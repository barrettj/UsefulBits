//
//  NSArray+ESAdditions.m
//	

#import "NSArray+ESAdditions.h"

// References:
// http://365cocoa.tumblr.com
// https://github.com/jweinberg/Objective-Curry/blob/master/NSArray+Functional.m
// https://github.com/erica/NSArray-Utilities/blob/master/ArrayUtilities.m

@interface NSArray (ESAdditions_Private)
- (NSArray *)_map:(id (^)(id object))block concurrent:(BOOL)concurrent;
@end

@implementation NSArray (ESAdditions)

// 365 Cocoa

- (id)firstObject
{
	if (self.count == 0)
		return nil;
	return [self objectAtIndex:0];
}

- (void)each:(void (^)(id object))block
{
	[self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		block(obj);
	}];
}

- (void)eachConcurrent:(void (^)(id object))block
{
	[self enumerateObjectsWithOptions:NSEnumerationConcurrent 
						   usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		block(obj);
	}];
}

- (NSArray *)sortedArrayUsingKey:(NSString *)key
{
	return [self sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:key ascending:YES]]];
}

- (NSArray *)sortedArrayUsingKeys:(NSArray *)keys
{
	return [self sortedArrayUsingDescriptors:[keys map:^id (id key) {
		return [[NSSortDescriptor alloc] initWithKey:key ascending:YES];
	}]];
}

- (NSArray *)reversedArray
{
	return [[self reverseObjectEnumerator] allObjects];
}

- (NSArray *)filter:(BOOL (^)(id object))block
{
	return [self filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^(id evaluatedObject, NSDictionary *bindings) {
		return block(evaluatedObject);
	}]];
}

- (BOOL)containsObjectOfClass:(Class)aClass
{
	for (id obj in self) 
	{
		if ([obj isKindOfClass:aClass])
			return YES;
	}
	return NO;
}

- (NSArray *)_map:(id (^)(id object))block concurrent:(BOOL)concurrent
{
	NSUInteger count = [self count];
	__unsafe_unretained id *temp = (__unsafe_unretained id *)malloc(count * sizeof(id));
	void (^enumBlock)(id obj, NSUInteger idx, BOOL *stop) = ^(id obj, NSUInteger idx, BOOL *stop) {
		CFTypeRef objectRef = (__bridge_retained CFTypeRef)block(obj);
		temp[idx] = (__bridge id)objectRef;
	};
	if (concurrent)
		[self enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:enumBlock];
	else
		[self enumerateObjectsUsingBlock:enumBlock];
	NSArray *result = [NSArray arrayWithObjects:temp 
										  count:count];
	NSUInteger i;
	for (i=0; i < count; i++)
	{
		CFTypeRef objectRef = (__bridge CFTypeRef)temp[i];
		CFRelease(objectRef);
	}
	free(temp);
	return result;
}

- (NSArray *)mapConcurrent:(id (^)(id object))block
{
	return [self _map:block concurrent:YES];
}

- (NSArray *)map:(id (^)(id object))block
{
	return [self _map:block concurrent:YES];
}

// Erica Sadun

- (NSArray *) arrayBySortingStrings
{
	NSMutableArray *sort = [NSMutableArray arrayWithArray:self];
	for (id eachitem in self)
		if (![eachitem isKindOfClass:[NSString class]])
			[sort removeObject:eachitem];
	return [sort sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (NSString *) stringValue
{
	return [self componentsJoinedByString:@" "];
}

@end
