//
//  ESBaseModelObject.m
//	
//  Created by Doug Russell
//  Copyright (c) 2011 Doug Russell. All rights reserved.
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//  

#import "ESBaseModelObject.h"
#import "NSObject+PropertyDictionary.h"
#import "ESObjectMapFunctions.h"

@implementation ESBaseModelObject

+ (ESObjectMap *)objectMap
{
	return GetObjectMapForClass([self class]);
}

+ (id)newWithDictionary:(NSDictionary *)dictionary
{
	return [[[self class] alloc] initWithDictionary:dictionary];
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
	if (dictionary == nil)
		return nil;
	self = [self init];
	if (self)
		[self configureWithDictionary:dictionary];
	return self;
}

- (void)configureWithDictionary:(NSDictionary *)dictionary
{
	NSDictionary *propertyDictionary = [[self class] propertyDictionary];
	ESObjectMap *objectMap = [[self class] objectMap];
	for (ESDeclaredPropertyAttributes *attributes in [propertyDictionary allValues])
	{
		@autoreleasepool {
			NSString *inputKey;
			NSString *outputKey;
			id dictionaryValue;
			id propertyValue;
			
			outputKey = attributes.name;
			if (outputKey == nil)
				continue;
			// Get the property map, if it exists
			ESPropertyMap *propertyMap = [objectMap propertyMapForOutputKey:outputKey];
			if (propertyMap == nil) // If there's no property map, then assume inputKey simply maps to outputKey
				inputKey = outputKey;
			else // If there is a property map, get the input key
				inputKey = propertyMap.inputKey;
			// Grab our value from the input dictionary
			dictionaryValue = [dictionary objectForKey:inputKey];
			if (dictionaryValue == nil)
				continue;
			// At this point we have a value to work with, so let's make sure we can actually set it
			if (attributes.readOnly)
				[NSException raise:@"Readonly Exception" format:@"Attempted to set a readonly property: %@", attributes];
			switch (attributes.storageType) {
				case IDType:
					break;
				case ObjectType:
					// If there's a transform block, execute it
					if (propertyMap.transformBlock)
						propertyValue = propertyMap.transformBlock(dictionaryValue);
					else
						propertyValue = dictionaryValue;
					Class class = NSClassFromString(attributes.classString);
					if (![propertyValue isKindOfClass:class])
					{
						// throw exception
					}
					[self setValue:propertyValue forKey:outputKey];
					break;
				case IntType:
				{
					int intPropertyValue = 0;
					// If there's a transform block, execute it
					if (((ESIntPropertyMap *)propertyMap).intTransformBlock)
						intPropertyValue = ((ESIntPropertyMap *)propertyMap).intTransformBlock(dictionaryValue);
					else
						intPropertyValue = [dictionaryValue intValue];
					NSInvocation *setIntInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:attributes.setter]];
					[setIntInvocation setTarget:self];
					[setIntInvocation setSelector:attributes.setter];
					[setIntInvocation setArgument:&intPropertyValue atIndex:2];
					[setIntInvocation invoke];
					break;
				}
				case DoubleType:
				{
					double doublePropertyValue = 0.0;
					// If there's a transform block, execute it
					if (((ESDoublePropertyMap *)propertyMap).doubleTransformBlock)
						doublePropertyValue = ((ESDoublePropertyMap *)propertyMap).doubleTransformBlock(dictionaryValue);
					else
						doublePropertyValue = [dictionaryValue doubleValue];
					NSInvocation *setIntInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:attributes.setter]];
					[setIntInvocation setTarget:self];
					[setIntInvocation setSelector:attributes.setter];
					[setIntInvocation setArgument:&doublePropertyValue atIndex:2];
					[setIntInvocation invoke];
					break;
				}
				case FloatType:
				{
					float floatPropertyValue = 0.0f;
					// If there's a transform block, execute it
					if (((ESFloatPropertyMap *)propertyMap).floatTransformBlock)
						floatPropertyValue = ((ESFloatPropertyMap *)propertyMap).floatTransformBlock(dictionaryValue);
					else
						floatPropertyValue = [dictionaryValue floatValue];
					NSInvocation *setIntInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:attributes.setter]];
					[setIntInvocation setTarget:self];
					[setIntInvocation setSelector:attributes.setter];
					[setIntInvocation setArgument:&floatPropertyValue atIndex:2];
					[setIntInvocation invoke];
					break;
				}
				case BoolType:
				{
					BOOL boolPropertyValue = NO;
					// If there's a transform block, execute it
					if (((ESBOOLPropertyMap *)propertyMap).boolTransformBlock)
						boolPropertyValue = ((ESBOOLPropertyMap *)propertyMap).boolTransformBlock(dictionaryValue);
					else
						boolPropertyValue = [dictionaryValue boolValue];
					NSInvocation *setIntInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:attributes.setter]];
					[setIntInvocation setTarget:self];
					[setIntInvocation setSelector:attributes.setter];
					[setIntInvocation setArgument:&boolPropertyValue atIndex:2];
					[setIntInvocation invoke];
					break;
				}
				default:
					break;
			}
		}
	}
}

- (NSDictionary *)dictionaryRepresentation
{
	NSMutableDictionary *dictionaryRepresentation = [NSMutableDictionary new];
	NSDictionary *propertyDictionary = [[self class] propertyDictionary];
	ESObjectMap *objectMap = [[self class] objectMap];
	for (ESDeclaredPropertyAttributes *attributes in [propertyDictionary allValues])
	{
		@autoreleasepool {
			NSString *inputKey;
			NSString *outputKey;
			id dictionaryValue;
			id propertyValue;
			
			outputKey = attributes.name;
			if (outputKey == nil)
				continue;
			// Get the property map, if it exists
			ESPropertyMap *propertyMap = [objectMap propertyMapForOutputKey:outputKey];
			if (propertyMap == nil) // If there's no property map, then assume inputKey simply maps to outputKey
				inputKey = outputKey;
			else // If there is a property map, get the input key
				inputKey = propertyMap.inputKey;
			switch (attributes.storageType) {
				case IDType:
					break;
				case ObjectType:
					propertyValue = [self valueForKey:outputKey];
					if (propertyMap.inverseTransformBlock)
						dictionaryValue = propertyMap.inverseTransformBlock(propertyValue);
					else
						dictionaryValue = propertyValue;
					break;
				case IntType:
				{
					NSInvocation *getIntInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:attributes.getter]];
					[getIntInvocation setTarget:self];
					[getIntInvocation setSelector:attributes.getter];
					int result;
					[getIntInvocation invoke];
					[getIntInvocation getReturnValue:&result];
					NSNumber *intNumber = [NSNumber numberWithInt:result];
					if (intNumber)
						dictionaryValue = intNumber;
					break;
				}
				case DoubleType:
				{
					NSInvocation *getDoubleInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:attributes.getter]];
					[getDoubleInvocation setTarget:self];
					[getDoubleInvocation setSelector:attributes.getter];
					double result;
					[getDoubleInvocation invoke];
					[getDoubleInvocation getReturnValue:&result];
					NSNumber *doubleNumber = [NSNumber numberWithDouble:result];
					if (doubleNumber)
						dictionaryValue = doubleNumber;
					break;
				}
				case FloatType:
				{
					NSInvocation *getFloatInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:attributes.getter]];
					[getFloatInvocation setTarget:self];
					[getFloatInvocation setSelector:attributes.getter];
					float result;
					[getFloatInvocation invoke];
					[getFloatInvocation getReturnValue:&result];
					NSNumber *floatNumber = [NSNumber numberWithFloat:result];
					if (floatNumber)
						dictionaryValue = floatNumber;
					break;
				}
				case BoolType:
				{
					NSInvocation *getBOOLInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:attributes.getter]];
					[getBOOLInvocation setTarget:self];
					[getBOOLInvocation setSelector:attributes.getter];
					BOOL result;
					[getBOOLInvocation invoke];
					[getBOOLInvocation getReturnValue:&result];
					NSNumber *boolNumber = [NSNumber numberWithBool:result];
					if (boolNumber)
						dictionaryValue = boolNumber;
					break;
				}
				default:
					break;
			}
			if (dictionaryValue)
				[dictionaryRepresentation setObject:dictionaryValue forKey:inputKey];
		}
	}
	return dictionaryRepresentation;
}

@end
