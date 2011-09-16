//
//  ESURLPropertyMap.h
//  ESObjectMap
//
//  Created by Doug Russell on 9/16/11.
//  Copyright (c) 2011 Doug Russell. All rights reserved.
//

#import "ESPropertyMap.h"

@interface ESURLPropertyMap : ESPropertyMap

+ (id)newPropertyMapWithInputKey:(NSString *)inputKey outputKey:(NSString *)outputKey;
- (id)initWithInputKey:(NSString *)inputKey outputKey:(NSString *)outputKey;

@end
