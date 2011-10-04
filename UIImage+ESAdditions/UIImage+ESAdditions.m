#import "UIImage+ESAdditions.h"

const CGBitmapInfo kDefaultCGBitmapInfo	= (kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
const CGBitmapInfo kDefaultCGBitmapInfoNoAlpha	= (kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host);

CGContextRef CreateCGBitmapContextForWidthAndHeight(unsigned int width, 
													unsigned int height, 
													CGColorSpaceRef optionalColorSpace, 
													CGBitmapInfo optionalInfo )
{
	CGColorSpaceRef	colorSpace	= (optionalColorSpace == NULL) ? GetDeviceRGBColorSpace() : optionalColorSpace;
	CGBitmapInfo	alphaInfo	= ( (int32_t)optionalInfo < 0 ) ? kDefaultCGBitmapInfo : optionalInfo;
	return CGBitmapContextCreate( NULL, width, height, 8, 0, colorSpace, alphaInfo );
}
CGColorSpaceRef	GetDeviceRGBColorSpace(void)
{
	static CGColorSpaceRef	deviceRGBSpace	= NULL;
	if( deviceRGBSpace == NULL )
		deviceRGBSpace	= CGColorSpaceCreateDeviceRGB();
	return deviceRGBSpace;
}
void ContextFlipYAroundHeight( CGContextRef ctx, float hgt )
{
	CGContextTranslateCTM( ctx, 0, hgt );
	CGContextScaleCTM( ctx, 1.0, -1.0 );
}
float GetScaleForProportionalResize(CGSize theSize, 
									CGSize intoSize, 
									bool onlyScaleDown, 
									bool maximize)
{
	float	sx = theSize.width;
	float	sy = theSize.height;
	float	dx = intoSize.width;
	float	dy = intoSize.height;
	float	scale	= 1;
	
	if( sx != 0 && sy != 0 )
	{
		dx	= dx / sx;
		dy	= dy / sy;
		
		// if maximize is true, take LARGER of the scales, else smaller
		if( maximize )		scale	= (dx > dy)	? dx : dy;
		else				scale	= (dx < dy)	? dx : dy;
		
		if( scale > 1 && onlyScaleDown )	// reset scale
			scale	= 1;
	}
	else
	{
		scale	 = 0;
	}
	return scale;
}

#define kEncodingKey @"UIImage"

@interface UIImage (private)

@end

@implementation UIImage (MYAdditions)

- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super init]))
	{
		NSData *data = [decoder decodeObjectForKey:kEncodingKey];
		self = [self initWithData:data];
	}
	return self;
}
- (void)encodeWithCoder:(NSCoder *)encoder
{
	NSData *data = UIImageJPEGRepresentation(self, 1.0);
	[encoder encodeObject:data forKey:kEncodingKey];
}

+ (UIImage *)imageForName:(NSString *)name 
				extension:(NSString *)extension
{
	return [UIImage imageWithContentsOfFile:
			[[NSBundle mainBundle] 
			 pathForResource:name 
			 ofType:extension]];
}

- (UIImage *)scaledToSize:(CGSize)targetSize
{
	UIImage	*	scaledImage = [self scaledToSize:targetSize 
								   orientation:self.imageOrientation 
								 clippedToRect:CGRectNull];
	return scaledImage;
}

- (UIImage *)scaledToSize:(CGSize)targetSize 
			  orientation:(UIImageOrientation)orientation
{
	UIImage	*	scaledImage = [self scaledToSize:targetSize 
								   orientation:orientation 
								 clippedToRect:CGRectNull];
	return scaledImage;
}

- (UIImage *)scaledToSize:(CGSize)targetSize 
			  orientation:(UIImageOrientation)orientation 
			clippedToRect:(CGRect)clippedRect
{
	CGImageRef		cgImage		=	NULL;
	UIImage		*	scaledImage	=	nil;
	CGSize			imageSize	=	CGSizeMake(CGImageGetWidth(self.CGImage) , CGImageGetHeight(self.CGImage));
	float			scale		=	GetScaleForProportionalResize(imageSize, targetSize, true, false);
	
	cgImage = CreateScaledCGImageFromUIImageWithOrientationCropped(self, scale, orientation, clippedRect);
	
	if (cgImage)
		scaledImage = [[UIImage alloc] initWithCGImage:cgImage];
	
	CGImageRelease(cgImage);
	
	return scaledImage;
}

CGImageRef CreateScaledCGImageFromUIImage(UIImage	*	image, 
										  float			scaleFactor)
{
	return CreateScaledCGImageFromUIImageWithOrientation(image, scaleFactor, image.imageOrientation);
}

CGImageRef CreateScaledCGImageFromUIImageWithOrientation(UIImage	*		image, 
														 float				scaleFactor, 
														 UIImageOrientation	orientation)
{
	return CreateScaledCGImageFromUIImageWithOrientationCropped(image, scaleFactor, orientation, CGRectNull);
}

CGImageRef CreateScaledCGImageFromUIImageWithOrientationCropped(UIImage	*			image, 
																float				scaleFactor, 
																UIImageOrientation	orientation, 
																CGRect				clippedRect)
{
	CGImageRef			newImage		=	NULL;
	CGContextRef		bmContext		=	NULL;
	BOOL				mustTransform	=	YES;
	CGAffineTransform	transform		=	CGAffineTransformIdentity;
	
	CGImageRef			srcCGImage		=	CGImageRetain(image.CGImage);
	
	size_t				width			=	CGImageGetWidth(srcCGImage) * scaleFactor;
	size_t				height			=	CGImageGetHeight(srcCGImage) * scaleFactor;
	
	// These Orientations are rotated 0 or 180 degrees, so they retain the width/height of the image
	if((orientation == UIImageOrientationUp) || 
	   (orientation == UIImageOrientationDown) || 
	   (orientation == UIImageOrientationUpMirrored) || 
	   (orientation == UIImageOrientationDownMirrored))
	{	
		bmContext	= CreateCGBitmapContextForWidthAndHeight( width, height, NULL, kDefaultCGBitmapInfo );
	}
	else	// The other Orientations are rotated ±90 degrees, so they swap width & height.
	{	
		bmContext	= CreateCGBitmapContextForWidthAndHeight( height, width, NULL, kDefaultCGBitmapInfo );
	}
	
	CGContextSetBlendMode(bmContext, kCGBlendModeCopy);
	
	switch(orientation)
	{
		case UIImageOrientationDown:		// 0th row is at the bottom, and 0th column is on the right - Rotate 180 degrees
			transform	= CGAffineTransformMake(-1.0, 0.0, 0.0, -1.0, width, height);
			break;
			
		case UIImageOrientationLeft:		// 0th row is on the left, and 0th column is the bottom - Rotate -90 degrees
			transform	= CGAffineTransformMake(0.0, 1.0, -1.0, 0.0, height, 0.0);
			break;
			
		case UIImageOrientationRight:		// 0th row is on the right, and 0th column is the top - Rotate 90 degrees
			transform	= CGAffineTransformMake(0.0, -1.0, 1.0, 0.0, 0.0, width);
			break;
			
		case UIImageOrientationUpMirrored:	// 0th row is at the top, and 0th column is on the right - Flip Horizontal
			transform	= CGAffineTransformMake(-1.0, 0.0, 0.0, 1.0, width, 0.0);
			break;
			
		case UIImageOrientationDownMirrored:	// 0th row is at the bottom, and 0th column is on the left - Flip Vertical
			transform	= CGAffineTransformMake(1.0, 0.0, 0, -1.0, 0.0, height);
			break;
			
		case UIImageOrientationLeftMirrored:	// 0th row is on the left, and 0th column is the top - Rotate -90 degrees and Flip Vertical
			transform	= CGAffineTransformMake(0.0, -1.0, -1.0, 0.0, height, width);
			break;
			
		case UIImageOrientationRightMirrored:	// 0th row is on the right, and 0th column is the bottom - Rotate 90 degrees and Flip Vertical
			transform	= CGAffineTransformMake(0.0, 1.0, 1.0, 0.0, 0.0, 0.0);
			break;
			
		default:
			mustTransform	= NO;
			break;
	}
	
	if (mustTransform)	CGContextConcatCTM( bmContext, transform );
	
	CGContextDrawImage( bmContext, CGRectMake(0.0, 0.0, width, height), srcCGImage );
	
	newImage = CGBitmapContextCreateImage(bmContext);
	
	CFRelease(bmContext);
	
	CGImageRelease(srcCGImage);
	
	if (!CGRectIsNull(clippedRect))
	{
		CGImageRef temp = newImage;
		newImage = CGImageCreateWithImageInRect(newImage, clippedRect);
		CGImageRelease(temp);
	}
	
	return newImage;
}

@end
