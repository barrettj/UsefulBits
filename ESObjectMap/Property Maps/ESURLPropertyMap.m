//
//  ESURLPropertyMap.m
//  ESObjectMap
//
//  Created by Doug Russell on 9/16/11.
//  Copyright (c) 2011 Doug Russell. All rights reserved.
//

#import "ESURLPropertyMap.h"

@implementation ESURLPropertyMap

+ (id)newPropertyMapWithInputKey:(NSString *)inputKey outputKey:(NSString *)outputKey
{
	return [[[self class] alloc] initWithInputKey:inputKey outputKey:outputKey];
}

- (id)initWithInputKey:(NSString *)inputKey outputKey:(NSString *)outputKey
{
	self = [super initWithInputKey:inputKey 
						 outputKey:outputKey 
					transformBlock:^id(id inputValue) {
						return [NSURL URLWithString:inputValue];
					}];
	if (self)
	{
		self.inverseTransformBlock = ^id(id inputValue) {
			return [inputValue absoluteString];
		};
	}
	return self;
}

@end
