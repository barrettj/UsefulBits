//	
//	ESBlockView.h
//	
//	Created by Doug Russell
//	Copyright 2011 Doug Russell. All rights reserved.
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

// References
// https://github.com/twitter/twui

#import "ESBlockView.h"
#import <QuartzCore/QuartzCore.h>

#if !__has_feature(objc_arc)
#error This class will leak without ARC
#endif

@implementation ESBlockView
@synthesize drawRectBlock=_drawRectBlock;
@synthesize layoutBlock=_layoutBlock;

- (void)setNeedsDisplay
{
	[self.layer setNeedsDisplay];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
	if (layer != self.layer)
		return;
	
	if (self.drawRectBlock)
	{
		CGRect clipRect = CGContextGetClipBoundingBox(ctx);
		UIGraphicsPushContext(ctx);
		if ([self clearsContextBeforeDrawing])
			CGContextClearRect(ctx, clipRect);
		CGContextSetAllowsAntialiasing(ctx, true);
		CGContextSetShouldAntialias(ctx, true);
		CGContextSetShouldSmoothFonts(ctx, YES);
		_drawRectBlock(self, clipRect);
		CGImageRef image = CGBitmapContextCreateImage(ctx);
		layer.contents = (__bridge_transfer id)image;
		UIGraphicsPopContext();
	}
	else
		[super drawLayer:layer inContext:ctx];
}

- (void)layoutSubviews
{
	if (self.layoutBlock)
		self.layoutBlock(self);
	else
		[super layoutSubviews];
}

@end
