//
//  NSArray+ESAdditions.h
//	

#import <Foundation/Foundation.h>

@interface NSArray (ESAdditions)

- (id)firstObject;
- (void)each:(void (^)(id object))block;
- (void)eachConcurrent:(void (^)(id object))block;
- (NSArray *)sortedArrayUsingKey:(NSString *)key;
- (NSArray *)sortedArrayUsingKeys:(NSArray *)keys;
- (NSArray *)reversedArray;
- (NSArray *)filter:(BOOL (^)(id object))block;
- (BOOL)containsObjectOfClass:(Class)aClass;
- (NSArray *)map:(id (^)(id object))block;
- (NSArray *)mapConcurrent:(id (^)(id object))block;
- (NSArray *)arrayBySortingStrings;
- (NSString *)stringValue;

@end
