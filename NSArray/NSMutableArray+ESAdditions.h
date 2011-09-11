//
//  NSMutableArray+ESAdditions.h
//	

#import <Foundation/Foundation.h>

@interface NSMutableArray (ESAdditions)

- (void)insertObjectsFromArray:(NSArray *)array atIndex:(int)index;
- (void)addObjectIfNotNil:(id)obj;
- (NSMutableArray *)push:(id)object;
- (NSMutableArray *)pushObjects:(id)object,...;
- (id)pop;
- (id)pull;

@end
