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
					// If there's a transform block, execute it
					if (propertyMap.transformBlock)
						propertyValue = propertyMap.transformBlock(dictionaryValue);
					else
						propertyValue = dictionaryValue;
					if (propertyValue == nil)
						continue;
					[self setValue:propertyValue forKey:outputKey];
					break;
				case ObjectType:
					// If there's a transform block, execute it
					if (propertyMap.transformBlock)
						propertyValue = propertyMap.transformBlock(dictionaryValue);
					else
						propertyValue = dictionaryValue;
					if (propertyValue == nil)
						continue;
					Class class = NSClassFromString(attributes.classString);
					if (class && ![propertyValue isKindOfClass:class])
						[NSException raise:@"Class Mismatch" format:@"Object: %@ is not kind of class: %@", propertyValue, NSStringFromClass(class)];
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
					SetPrimitivePropertyValue(self, attributes.setter, &intPropertyValue);
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
					SetPrimitivePropertyValue(self, attributes.setter, &doublePropertyValue);
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
					SetPrimitivePropertyValue(self, attributes.setter, &floatPropertyValue);
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
					SetPrimitivePropertyValue(self, attributes.setter, &boolPropertyValue);
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
				case ObjectType:
					propertyValue = [self valueForKey:outputKey];
					if (propertyMap.inverseTransformBlock)
						dictionaryValue = propertyMap.inverseTransformBlock(propertyValue);
					else
						dictionaryValue = propertyValue;
					break;
				case IntType:
				{
					int result;
					GetPrimitivePropertyValue(self, attributes.getter, &result);
					dictionaryValue = [NSNumber numberWithInt:result];
					break;
				}
				case DoubleType:
				{
					double result;
					GetPrimitivePropertyValue(self, attributes.getter, &result);
					dictionaryValue = [NSNumber numberWithDouble:result];
					break;
				}
				case FloatType:
				{
					float result;
					GetPrimitivePropertyValue(self, attributes.getter, &result);
					dictionaryValue = [NSNumber numberWithFloat:result];
					break;
				}
				case BoolType:
				{
					BOOL result;
					GetPrimitivePropertyValue(self, attributes.getter, &result);
					dictionaryValue = [NSNumber numberWithBool:result];
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
