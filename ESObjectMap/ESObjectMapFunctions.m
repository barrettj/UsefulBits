//
//  ESObjectMapFunctions.m
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

#import "ESObjectMapFunctions.h"
#import "ESMutableDictionary.h"

static ESMutableDictionary *_objectMapCache;

ESObjectMap * GetObjectMapForClass(Class objectClass)
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_objectMapCache = [ESMutableDictionary new];
	});
	if (objectClass == nil)
		return nil;
	ESObjectMap *objectMap = [_objectMapCache objectForKey:objectClass];
	if (objectMap != nil)
		return objectMap;
	objectMap = [ESObjectMap new];
	[_objectMapCache setObject:objectMap forKey:objectClass];
	return objectMap;
}