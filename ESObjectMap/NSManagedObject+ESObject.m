//
//  NSManagedObject+ESObject.m
//  ESObjectMap
//
//  Created by Doug Russell on 9/17/11.
//  Copyright (c) 2011 Doug Russell. All rights reserved.
//

#import "NSManagedObject+ESObject.h"
#import "ESObjectMapFunctions.h"

@implementation NSManagedObject (ESObject)

+ (ESObjectMap *)objectMap
{
	return GetObjectMapForClass([self class]);
}

- (void)configureWithDictionary:(NSDictionary *)dictionary
{
	ConfigureObjectWithDictionary(self, dictionary);
}

- (NSDictionary *)dictionaryRepresentation
{
	return GetDictionaryRepresentation(self);
}

@end
