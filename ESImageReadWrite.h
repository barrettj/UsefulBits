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

#import <UIKit/UIKit.h>

/**
 * 8 bit per component w/ alpha channel
 */
static const CGBitmapInfo kDefaultCGBitmapInfo	= (kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
/**
 * 8 bit per component w/ no alpha channel
 */
static const CGBitmapInfo kDefaultCGBitmapInfoNoAlpha	= (kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host);
/**
 * 5 bit per component w/ no alpha channel
 */
static const CGBitmapInfo kDefault16CGBitmapInfoNoAlpha	= (kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder16Host);
/**
 * Take in an image and bitmap info and render it into a memory mapped image as raw pixel data
 */
void ESWriteRawImageToFile(UIImage *image, NSString *fileName, CGBitmapInfo bitmapInfo, NSError **error, BOOL mmap);
/**
 * Create an image from given fileName with width, height and bitmap info using mmap to load the data
 */
UIImage * ESCreateImage(NSString *fileName, CGFloat width, CGFloat height, CGBitmapInfo bitmapInfo, NSError **error);
/**
 * Create bitmap context with most common configuration (8 bits per component, alpha channel, devicecolorspace)
 */
CGContextRef ESCreateCGBitmapContextForWidthAndHeight(
													  void *data,
													  unsigned int width, 
													  unsigned int height
													  );
/**
 * Create bitmap context with lo fi configuration to help with memory constraints (5 bits per component, no alpha channel, devicecolorspace)
 */
CGContextRef ESCreateLoFiCGBitmapContextForWidthAndHeight(
														  void *data,
														  unsigned int width, 
														  unsigned int height
														  );
/**
 * Error domain for WriteImageToMemoryMappedFile && CreateMemoryMappedImage
 */
extern NSString *const kImageReadWriteErrorDomain;
/**
 * Error codes for WriteImageToMemoryMappedFile && CreateMemoryMappedImage
 */
typedef enum {
	FileExistsAtPath,
	UnsupportedBitmapInfo,
	FileFailedToOpenForWriting,
	FileFailedToSeek,
	FileFailedToWriteLastByte,
	FileFailedToMMap,
	FileFailedToUnMMap
} ImageReadWriteError;
