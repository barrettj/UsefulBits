//
//  ESObjectPropertyMap.m
//  ESObjectMap
//
//  Created by Doug Russell on 9/16/11.
//  Copyright (c) 2011 Doug Russell. All rights reserved.
//

#import "ESObjectPropertyMap.h"

@implementation ESObjectPropertyMap
@synthesize objectClass=_objectClass;

+ (id)newPropertyMapWithInputKey:(NSString *)inputKey outputKey:(NSString *)outputKey objectClass:(Class)objectClass
{
	return [[[self class] alloc] initWithInputKey:inputKey outputKey:outputKey objectClass:objectClass];
}

- (id)initWithInputKey:(NSString *)inputKey outputKey:(NSString *)outputKey objectClass:(Class)objectClass
{
	self = [super initWithInputKey:inputKey outputKey:outputKey transformBlock:nil];
	if (self)
	{
		self.objectClass = objectClass;
		self.transformBlock = ^id(id inputValue) {
			return [[objectClass alloc] initWithDictionary:inputValue];
		};
		self.inverseTransformBlock = ^id(id inputValue) {
			return [inputValue dictionaryRepresentation];
		};
	}
	return self;
}
@end
