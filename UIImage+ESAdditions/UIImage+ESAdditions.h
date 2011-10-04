#import <UIKit/UIKit.h>

extern const CGBitmapInfo kDefaultCGBitmapInfo;
extern const CGBitmapInfo kDefaultCGBitmapInfoNoAlpha;

CGContextRef	CreateCGBitmapContextForWidthAndHeight(unsigned int width, 
													   unsigned int height, 
													   CGColorSpaceRef optionalColorSpace, 
													   CGBitmapInfo optionalInfo);
CGColorSpaceRef	GetDeviceRGBColorSpace(void);
void 			ContextFlipYAroundHeight(CGContextRef ctx, 
										 float hgt);
float GetScaleForProportionalResize(CGSize theSize, 
									CGSize intoSize, 
									bool onlyScaleDown, 
									bool maximize);

@interface UIImage (MyAdditions) <NSCoding>

- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

+ (UIImage *)imageForName:(NSString *)name extension:(NSString *)extension;

- (UIImage *)scaledToSize:(CGSize)targetSize; // AutoReleased
- (UIImage *)scaledToSize:(CGSize)targetSize 
			  orientation:(UIImageOrientation)orientation; // AutoReleased
- (UIImage *)scaledToSize:(CGSize)targetSize 
			  orientation:(UIImageOrientation)orientation 
			clippedToRect:(CGRect)clippedRect; // AutoReleased
CGImageRef CreateScaledCGImageFromUIImage(UIImage	*	image, 
										  float			scaleFactor); // Owning Reference
CGImageRef CreateScaledCGImageFromUIImageWithOrientation(UIImage	*		image, 
														 float				scaleFactor, 
														 UIImageOrientation	orientation); // Owning Reference
CGImageRef CreateScaledCGImageFromUIImageWithOrientationCropped(UIImage	*			image, 
																float				scaleFactor, 
																UIImageOrientation	orientation, 
																CGRect				clippedRect); // Owning Reference

@end
