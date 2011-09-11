//
//  ESMutableDictionary.m
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
#import "ESMutableDictionary.h"

@implementation ESMutableDictionary
{
	CFMutableDictionaryRef _internalDictionary;
	dispatch_queue_t _syncQueue;
}

- (id)init
{
	self = [super init];
	if (self)
	{
		_internalDictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 
														0, 
														&kCFTypeDictionaryKeyCallBacks, 
														&kCFTypeDictionaryValueCallBacks);
		_syncQueue = dispatch_queue_create("com.es.mutabledictionary", 0);
	}
	return self;
}

- (void)dealloc
{
	CFRelease(_internalDictionary);
	dispatch_release(_syncQueue);
}

- (void)setObject:(id)obj forKey:(id)key
{
	if (!obj || !key)
		return;
	dispatch_sync(_syncQueue,  ^(void) {
		CFDictionarySetValue(_internalDictionary, (__bridge CFTypeRef)key, (__bridge CFTypeRef)obj);
	});
}

- (void)removeObjectForKey:(id)key
{
	if (!key)
		return;
	dispatch_sync(_syncQueue,  ^(void) {
		CFDictionaryRemoveValue(_internalDictionary, (__bridge CFTypeRef)key);
	});
}

- (id)objectForKey:(id)key
{
	if (!key)
		return nil;
	__block CFTypeRef value = nil;
	__block Boolean present;
	dispatch_sync(_syncQueue, ^(void) {
		present = CFDictionaryGetValueIfPresent(_internalDictionary, (__bridge CFTypeRef)key, &value);
	});
	if (present)
		return (__bridge id)value;
	else
		return nil;
}

- (NSDictionary *)copyDictionary
{
	__block NSDictionary *dictionary;
	dispatch_sync(_syncQueue, ^(void) {
		dictionary = [(__bridge NSDictionary *)_internalDictionary copy];
	});
	return dictionary;
}

@end
