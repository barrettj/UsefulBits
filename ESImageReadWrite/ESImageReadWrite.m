//	
//	Created by Doug Russell
//  Copyright (c) 2011 Doug Russell. All rights reserved.
//	
//	Licensed under the Apache License, Version 2.0 (the "License");
//	you may not use this file except in compliance with the License.
//	You may obtain a copy of the License at
//	
//	http://www.apache.org/licenses/LICENSE-2.0
//	
//	Unless required by applicable law or agreed to in writing, software
//	distributed under the License is distributed on an "AS IS" BASIS,
//	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//	See the License for the specific language governing permissions and
//	limitations under the License.
//	

#import "ESImageReadWrite.h"
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

//	
//	References
//	http://www.cse.buffalo.edu/~ss424/Presentations/mmap_sample.c
//	http://rabbit.eng.miami.edu/info/functions/unixio.html
//	http://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man2/mmap.2.html
//	http://stackoverflow.com/questions/144250/how-to-get-the-rgb-values-for-a-pixel-on-an-image-on-the-iphone/694139#694139
//	http://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_context/dq_context.html#//apple_ref/doc/uid/TP30001066-CH203-BCIBHHBB
//	http://developer.apple.com/library/mac/#documentation/GraphicsImaging/Reference/CGDataProvider/Reference/reference.html
//	

NSString *const kImageReadWriteErrorDomain = @"ImageReadWriteErrorDomain";

static inline CGColorSpaceRef GetDeviceRGBColorSpace()
{
	static CGColorSpaceRef	deviceRGBSpace	= NULL;
	if (deviceRGBSpace == NULL)
		deviceRGBSpace	= CGColorSpaceCreateDeviceRGB();
	return deviceRGBSpace;
}

CGContextRef ESCreateCGBitmapContextForWidthAndHeight(void *data,
													  unsigned int width, 
													  unsigned int height)
{
	CGColorSpaceRef	colorSpace	= GetDeviceRGBColorSpace();
	CGBitmapInfo	alphaInfo	= kDefaultCGBitmapInfo;
	return CGBitmapContextCreate(
								 data, 
								 width, 
								 height, 
								 8, /* Bits per component */
								 width*4, /* Bytes per row (4 components per pixel, 8 bits per component, 32 bits per pixel, 4 bytes per pixel) */
								 colorSpace, 
								 alphaInfo
								 );
}

CGContextRef ESCreateLoFiCGBitmapContextForWidthAndHeight(void *data,
														  unsigned int width, 
														  unsigned int height)
{
	CGColorSpaceRef	colorSpace	= GetDeviceRGBColorSpace();
	CGBitmapInfo	alphaInfo	= kDefault16CGBitmapInfoNoAlpha;
	return CGBitmapContextCreate(
								 data, 
								 width, 
								 height, 
								 5, /* Bits per component */
								 width*2, /* Bytes per row (3 components per pixel, 5 bits per component, 15 bits per pixel (round up to 16), 2 bytes per pixel) */
								 colorSpace, 
								 alphaInfo
								 );
}

void ESWriteRawImageToFile(UIImage *image, NSString *fileName, CGBitmapInfo bitmapInfo, NSError **error, BOOL memoryMap)
{
	//Bail early if input is junk
	if (!image || !fileName)
		return;
	size_t bytesPerPixel;
	if (bitmapInfo == kDefaultCGBitmapInfo)
	{
		bytesPerPixel = 4;
	}
	else if (bitmapInfo == kDefault16CGBitmapInfoNoAlpha)
	{
		bytesPerPixel = 2;
	}
	else
	{
		if (error)
			*error = [NSError errorWithDomain:kImageReadWriteErrorDomain 
										 code:UnsupportedBitmapInfo 
									 userInfo:nil];
		return;
	}
	
	//Path to write file to (inside applications caches directory)
	NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, 
														   NSUserDomainMask, 
														   YES) lastObject] stringByAppendingPathComponent:fileName];
	//Make sure file doesn't already exist
	if ([[NSFileManager defaultManager] fileExistsAtPath:path])
	{
		if (error)
			*error = [NSError errorWithDomain:kImageReadWriteErrorDomain 
										 code:FileExistsAtPath 
									 userInfo:nil];
		return;
	}
	// memory to write image to
	unsigned char * map;
	// Width * Height * bytes per pixel
	size_t FILESIZE = image.size.width * image.size.height * bytesPerPixel;
	if (memoryMap)
	{
		//Setup to write file
		int fileDescriptor;
		int result;
		const char * FILEPATH = [path cStringUsingEncoding:NSASCIIStringEncoding];
		/*	
		 *	Open up file handle for writing
		 *		- Creating the file if it doesn't exist.
		 *		- Truncating it to 0 size if it already exists. (not really needed)
		 *	
		 *		O_RDWR          Read and Write operations both permitted
		 *		O_CREAT         Create file if it doesn't already exist
		 *		O_TRUNC         Delete existing contents of file
		 *		Note: "O_WRONLY" mode is not sufficient when mmaping.
		 */
		fileDescriptor = open(FILEPATH, O_RDWR | O_CREAT | O_TRUNC, (mode_t)0600);
		if (fileDescriptor == -1)
		{
			if (error)
				*error = [NSError errorWithDomain:kImageReadWriteErrorDomain 
											 code:FileFailedToOpenForWriting 
										 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												   [NSString stringWithFormat:@"Error opening file for writing: filename: %@ path: %@", fileName, path], @"underlyingError", nil]];
			return;
		}
		/**
		 *  Expand the file to the size of our target data
		 *	SEEK_SET        Position is number of bytes from beginning of file
		 */
		result = lseek(fileDescriptor, FILESIZE-1, SEEK_SET);
		if (result == -1) 
		{
			close(fileDescriptor);
			if (error)
				*error = [NSError errorWithDomain:kImageReadWriteErrorDomain 
											 code:FileFailedToSeek 
										 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												   [NSString stringWithFormat:@"Error calling lseek() to 'stretch' the file to filesize: %d", FILESIZE], @"underlyingError", nil]];
			return;
		}
		/**
		 *	Write something at the end of the file (doesn't matter what)
		 */
		result = write(fileDescriptor, "", 1);
		if (result != 1) 
		{
			close(fileDescriptor);
			if (error)
				*error = [NSError errorWithDomain:kImageReadWriteErrorDomain 
											 code:FileFailedToWriteLastByte 
										 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												   @"Error writing last byte of the file", @"underlyingError", nil]];
			return;
		}
		/**
		 *	Memory map the file
		 *	PROT_READ  Pages may be read.
		 *	PROT_WRITE Pages may be written.
		 *	MAP_SHARED Share this mapping. Updates to the mapping are visible to other processes that map this file, and are carried through to the underlying file. The file may not actually be updated until msync(2) or munmap() is called.
		 */
		map = mmap(0, FILESIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fileDescriptor, 0);
		if (map == MAP_FAILED) 
		{
			close(fileDescriptor);
			if (error)
				*error = [NSError errorWithDomain:kImageReadWriteErrorDomain 
											 code:FileFailedToMMap 
										 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												   @"Error mmapping the file", @"underlyingError", nil]];
			return;
		}
		//Create a context backed by mmapped data  (I should move this into a function, it's dupe logic)
		CGContextRef context;
		if (bytesPerPixel == 4)
			context = ESCreateCGBitmapContextForWidthAndHeight(map, image.size.width, image.size.height);
		else
			context = ESCreateLoFiCGBitmapContextForWidthAndHeight(map, image.size.width, image.size.height);
		UIGraphicsPushContext(context);
		//Flip the image to compensate for CG coordinate space
		CGContextTranslateCTM(context, 0.0, image.size.height);
		CGContextScaleCTM(context, 1.0, -1.0);
		/**
		 * Draw the image, effectively writing it to the mmaped file 
		 */
		[image drawInRect:CGRectMake(0.0, 0.0, image.size.width, image.size.height) 
				blendMode:kCGBlendModeCopy 
					alpha:1.0];
		UIGraphicsPopContext();
		CGContextRelease(context);
		/**
		 * Clean up the mmap and close the file 
		 */
		if (munmap(map, FILESIZE) == -1)
		{
			if (error)
				*error = [NSError errorWithDomain:kImageReadWriteErrorDomain 
											 code:FileFailedToUnMMap 
										 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
												   @"Error un-mmapping the file", @"underlyingError", nil]];
			return;
		}
		close(fileDescriptor);
	}
	else
	{
		map = malloc(FILESIZE);
		//Create a context backed by data array (I should move this into a function, it's dupe logic)
		CGContextRef context;
		if (bytesPerPixel == 4)
			context = ESCreateCGBitmapContextForWidthAndHeight(map, image.size.width, image.size.height);
		else
			context = ESCreateLoFiCGBitmapContextForWidthAndHeight(map, image.size.width, image.size.height);
		UIGraphicsPushContext(context);
		//Flip the image to compensate for CG coordinate space
		CGContextTranslateCTM(context, 0.0, image.size.height);
		CGContextScaleCTM(context, 1.0, -1.0);
		/**
		 * Draw the image, effectively writing it to the mmaped file 
		 */
		[image drawInRect:CGRectMake(0.0, 0.0, image.size.width, image.size.height) 
				blendMode:kCGBlendModeCopy 
					alpha:1.0];
		UIGraphicsPopContext();
		CGContextRelease(context);
		NSData *data = [[NSData alloc] initWithBytesNoCopy:map length:FILESIZE freeWhenDone:YES];
		[data writeToFile:path atomically:NO];
#if !__has_feature(objc_arc)
		[data release];
#endif
	}
}

UIImage * ESCreateImage(NSString *fileName, CGFloat width, CGFloat height, CGBitmapInfo bitmapInfo, NSError **error)
{
	//Bail early if input is junk
	if (!fileName)
		return nil;
	size_t bitsPerComponent;
	size_t bitsPerPixel;
	size_t bytesPerPixel;
	if (bitmapInfo == kDefaultCGBitmapInfo)
	{
		bitsPerComponent = 8;
		bitsPerPixel = 32;
		bytesPerPixel = 4;
	}
	else if (bitmapInfo == kDefault16CGBitmapInfoNoAlpha)
	{
		bitsPerComponent = 5;
		bitsPerPixel = 16;
		bytesPerPixel = 2;
	}
	else
	{
		if (error)
			*error = [NSError errorWithDomain:kImageReadWriteErrorDomain 
										 code:UnsupportedBitmapInfo 
									 userInfo:nil];
		return nil;
	}
	//Path to read file from (inside applications caches directory)
	NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, 
														   NSUserDomainMask, 
														   YES) lastObject] stringByAppendingPathComponent:fileName];
	//Make sure file actually exists
	if (![[NSFileManager defaultManager] fileExistsAtPath:path])
		return nil;
	//Create a provider to read raw image data
	CGDataProviderRef provider = CGDataProviderCreateWithFilename([path cStringUsingEncoding:NSASCIIStringEncoding]);
	if (provider == NULL)
		return nil;
	//Create CGImage using provider and appropriate bitmap configuration
	CGImageRef imageRef = CGImageCreate(width, 
										height, 
										bitsPerComponent,
										bitsPerPixel,
										width*bytesPerPixel, //bytes per row 
										GetDeviceRGBColorSpace(), 
										bitmapInfo, 
										provider, 
										NULL, 
										NO,
										kCGRenderingIntentDefault);
	if (imageRef == NULL)
	{
		CGDataProviderRelease(provider);
		return nil;
	}
	//Create image
	UIImage *image = [UIImage imageWithCGImage:imageRef];
	//Cleanup
	CGImageRelease(imageRef);
	CGDataProviderRelease(provider);
	return image;
}
