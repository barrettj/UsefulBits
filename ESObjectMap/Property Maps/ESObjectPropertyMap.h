//
//  ESObjectPropertyMap.h
//  ESObjectMap
//
//  Created by Doug Russell on 9/16/11.
//  Copyright (c) 2011 Doug Russell. All rights reserved.
//

#import "ESPropertyMap.h"

@interface ESObjectPropertyMap : ESPropertyMap

@property (strong, nonatomic) Class objectClass;

+ (id)newPropertyMapWithInputKey:(NSString *)inputKey outputKey:(NSString *)outputKey objectClass:(Class)objectClass;
- (id)initWithInputKey:(NSString *)inputKey outputKey:(NSString *)outputKey objectClass:(Class)objectClass;


@end
