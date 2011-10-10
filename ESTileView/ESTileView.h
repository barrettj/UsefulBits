//
//  ESScrollView.h
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

#import <UIKit/UIKit.h>
#import "ARCLogic.h"

typedef enum {
	ESTileViewHorizontalAlignmentLeft,
	ESTileViewHorizontalAlignmentCenter,
	ESTileViewHorizontalAlignmentRight,
} ESTileViewHorizontalAlignment;

typedef enum {
	ESTileViewVerticalAlignmentTop,
	ESTileViewVerticalAlignmentCenter,
	ESTileViewVerticalAlignmentBottom,
} ESTileViewVerticalAlignment;

typedef struct {
	ESTileViewHorizontalAlignment horizontalAlignment;
	ESTileViewVerticalAlignment verticalAlignment;
} ESTileViewAlignment;

static inline ESTileViewAlignment
ESTileViewAlignmentMake(ESTileViewHorizontalAlignment horizontalAlignment, ESTileViewVerticalAlignment verticalAlignment)
{
	ESTileViewAlignment alignment;
	alignment.horizontalAlignment = horizontalAlignment;
	alignment.verticalAlignment = verticalAlignment;
	return alignment;
}

@protocol ESTileViewDataSource;
@protocol ESTileViewDelegate <UIScrollViewDelegate>
@end

/**
 * Generic control for use as a paneling scroll view with delegate callbacks for configuration and non-contentSize paging
 */

@interface ESTileView : UIView

/**
 * 
 */
@property (WEAK, nonatomic) IBOutlet id<ESTileViewDataSource> dataSource;
/**
 * This is an assign (rather than weak) property due to underlying implementation details, this may change.
 */
@property (assign, nonatomic) IBOutlet id<ESTileViewDelegate> delegate;
/**
 * 
 */
@property (assign, nonatomic, readonly) CGSize tileSize;
/**
 * 
 */
@property (assign, nonatomic, readonly) NSInteger numberOfRows;
/**
 * 
 */
@property (assign, nonatomic, readonly) NSInteger numberOfColumns;
/**
 * 
 */
@property (assign, nonatomic) ESTileViewAlignment alignment;
/**
 * 
 */
@property (assign, nonatomic) BOOL pagingEnabled;

/**
 * 
 */
- (UIView *)dequeueReusableTile;
/**
 * 
 */
- (void)reloadData;
/**
 * 
 */
- (NSArray *)visibleTiles;
/**
 * 
 */
- (void)scrollToTileAtRow:(NSInteger)row column:(NSInteger)column;
/**
 * 
 */
- (void)scrollToTileAtRow:(NSInteger)row column:(NSInteger)column animated:(BOOL)animated;

@end

@protocol ESTileViewDataSource <NSObject>
/**
 * It is acceptible to return nil to create a gap in the tile grid
 */
- (UIView *)tileView:(ESTileView *)tileView tileForRow:(NSInteger)row column:(NSInteger)column;
@optional
/**
 * Defaults to the number of tiles required to fully populate the tile grid if not implemented
 */
- (NSInteger)numberOfTilesForTileView:(ESTileView *)tileView;
/**
 * Defaults to {100.0f,100.0f} if not implemented
 */
- (CGSize)tileSizeForTileView:(ESTileView *)tileView;
/**
 * Defaults to 1 if not implemented
 */
- (NSInteger)rowCountForTileView:(ESTileView *)tileView;
/**
 * Defaults to 1 if not implemented
 */
- (NSInteger)columnCountForTileView:(ESTileView *)tileView;
@end
