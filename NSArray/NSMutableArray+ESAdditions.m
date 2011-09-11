//
//  NSMutableArray+ESAdditions.m
//	

#import "NSMutableArray+ESAdditions.h"

// References:
// http://365cocoa.tumblr.com
// https://github.com/erica/NSArray-Utilities/blob/master/ArrayUtilities.m

@implementation NSMutableArray (ESAdditions)

// 365 Cocoa
- (void)insertObjectsFromArray:(NSArray *)array atIndex:(int)index
{
	for (id obj in array)
		[self insertObject:obj atIndex:index++];
}

- (void)addObjectIfNotNil:(id)obj
{
	if (obj != nil)
		[self addObject:obj];
}

// Erica Sadun

- (NSMutableArray *)push:(id)object
{
    [self addObject:object];
	return self;
}

- (NSMutableArray *)pushObjects:(id)object,...
{
	if (!object)
		return self;
	id obj = object;
	va_list objects;
	va_start(objects, object);
	do 
	{
		[self addObject:obj];
		obj = va_arg(objects, id);
	} while (obj);
	va_end(objects);
	return self;
}

- (id)pop
{
	if ([self count] == 0) 
		return nil;
    id lastObject = [self lastObject];
    [self removeLastObject];
    return lastObject;
}

- (id)pull
{
	if ([self count] == 0)
		return nil;
	id firstObject = [self objectAtIndex:0];
	[self removeObjectAtIndex:0];
	return firstObject;
}

@end
