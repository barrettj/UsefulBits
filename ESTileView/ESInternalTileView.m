//
//  ESInternalTileView.m
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

#import "ESInternalTileView.h"

#if !HASARC
#warning Untested on NonARC Configurations
#endif

#define DEFAULT_TILE_SIZE 100
#define DEFAULT_ROW_COUNT 1
#define DEFAULT_COLUMN_COUNT 1
#define DEFAULT_TILE_COUNT 1

#ifndef DLog
#if DEBUG
#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define DLog(fmt, ...) 
#endif
#endif

@interface ESInternalTileView ()
@property (assign, nonatomic) CGSize tileSize;
@property (STRONG, nonatomic) NSMutableSet *internalVisibleTiles;
@property (STRONG, nonatomic) NSMutableSet *reusableTiles;
- (UIView *)dataSourceTileForRow:(NSInteger)row column:(NSInteger)column;
@end

@implementation ESInternalTileView
{
@private
	CGRect _storedFrame;
	// we use the following ivars to keep track of which rows and columns are visible
	int _firstVisibleRow, _firstVisibleColumn, _lastVisibleRow, _lastVisibleColumn, _numberOfRows, _numberOfColumns, _numberOfTiles;
	// cache data source methods
	struct {
		signed char dataSourceRespondsToNumberOfTilesForTileView:1;
		signed char dataSourceRespondsToTileSizeForTileView:1;
		signed char dataSourceRespondsToRowCountForTileView:1;
		signed char dataSourceRespondsToColumnCountForTileView:1;
	} _dataSourceCache;
	struct {
	} _delegateCache;
}
@synthesize tileSize=_tileSize;
@synthesize dataSource=_dataSource;
@synthesize numberOfRows=_numberOfRows;
@synthesize numberOfColumns=_numberOfColumns;
@synthesize alignment=_alignment;
@synthesize internalVisibleTiles=_internalVisibleTiles;
@synthesize reusableTiles=_reusableTiles;

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		_tileSize = CGSizeMake(DEFAULT_TILE_SIZE, DEFAULT_TILE_SIZE);
		_numberOfRows = DEFAULT_ROW_COUNT;
		_numberOfColumns = DEFAULT_COLUMN_COUNT;
		_numberOfTiles = DEFAULT_TILE_COUNT;
		
		// no rows or columns are visible at first; note this by making the firsts very high and the lasts very low
		_firstVisibleRow = _firstVisibleColumn = NSIntegerMax;
		_lastVisibleRow  = _lastVisibleColumn  = NSIntegerMin;
		
		self.clipsToBounds = NO;
		
		_alignment = ESTileViewAlignmentMake(ESTileViewHorizontalAlignmentLeft, ESTileViewVerticalAlignmentTop);
	}
	return self;
}

NO_ARC(
- (void)dealloc 
{
	[_reusableTiles release];
	[_internalVisibleTiles release];
	[super dealloc];
}
)

#pragma mark - Public
- (UIView *)dequeueReusableTile 
{
	UIView *tile = [self.reusableTiles anyObject];
	if (tile) 
	{
		// the only object retaining the tile is our reusableTiles set, so we have to retain/autorelease it
		// before returning it so that it's not immediately deallocated when we remove it from the set
		NO_ARC([[tile retain] autorelease];)
		[self.reusableTiles removeObject:tile];
	}
	return tile;
}

- (void)reloadData 
{
	NSAssert((self.dataSource != nil), @"Attempted to reload tile view data with no datasource");
	// recycle all tiles so that every tile will be replaced in the next layoutSubviews
	[self.reusableTiles addObjectsFromArray:[self.internalVisibleTiles allObjects]];
	[self.internalVisibleTiles makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[self.internalVisibleTiles removeAllObjects];
	// Call datasource methods to configure tiling
	__STRONG id<ESTileViewDataSource> dataSource = self.dataSource;
	if (dataSource && self->_dataSourceCache.dataSourceRespondsToTileSizeForTileView)
		self.tileSize = [dataSource tileSizeForTileView:((ESTileView *)self.superview)];
	if (dataSource && self->_dataSourceCache.dataSourceRespondsToRowCountForTileView)
		_numberOfRows = [dataSource rowCountForTileView:((ESTileView *)self.superview)];
	if (dataSource && self->_dataSourceCache.dataSourceRespondsToRowCountForTileView)
		_numberOfColumns = [dataSource columnCountForTileView:((ESTileView *)self.superview)];
	if (dataSource && self->_dataSourceCache.dataSourceRespondsToNumberOfTilesForTileView)
		_numberOfTiles = [dataSource numberOfTilesForTileView:((ESTileView *)self.superview)];
	else
		_numberOfTiles = (_numberOfRows + 1) * _numberOfColumns;
	self.contentSize = CGSizeMake(self.tileSize.width * (CGFloat)self.numberOfColumns, self.tileSize.height * (CGFloat)self.numberOfRows);
	// no rows or columns are now visible; note this by making the firsts very high and the lasts very low
	_firstVisibleRow = _firstVisibleColumn = NSIntegerMax;
	_lastVisibleRow  = _lastVisibleColumn  = NSIntegerMin;
	[self setNeedsLayout];
}

- (NSArray *)visibleTiles
{
	return [NSArray arrayWithArray:[self.internalVisibleTiles allObjects]];
}

- (UIView *)tileForRow:(NSInteger)row column:(NSInteger)column
{
	return [self viewWithTag:(row * self.numberOfColumns + column)];
}

- (void)setDataSource:(id<ESTileViewDataSource>)dataSource
{
	_dataSource = dataSource;
	// Resolves and caches all the data source protocol methods
	if (dataSource)
	{
		self->_dataSourceCache.dataSourceRespondsToNumberOfTilesForTileView = [_dataSource respondsToSelector:@selector(numberOfTilesForTileView:)];
		self->_dataSourceCache.dataSourceRespondsToTileSizeForTileView = [_dataSource respondsToSelector:@selector(tileSizeForTileView:)];
		self->_dataSourceCache.dataSourceRespondsToRowCountForTileView = [_dataSource respondsToSelector:@selector(rowCountForTileView:)];
		self->_dataSourceCache.dataSourceRespondsToColumnCountForTileView = [_dataSource respondsToSelector:@selector(columnCountForTileView:)];
	}
	else
	{
		self->_dataSourceCache.dataSourceRespondsToNumberOfTilesForTileView = NO;
		self->_dataSourceCache.dataSourceRespondsToTileSizeForTileView = NO;
		self->_dataSourceCache.dataSourceRespondsToRowCountForTileView = NO;
		self->_dataSourceCache.dataSourceRespondsToColumnCountForTileView = NO;
	}
}

- (id<ESTileViewDelegate>)delegate
{
	return (id<ESTileViewDelegate>)[super delegate];
}

- (void)setDelegate:(id<ESTileViewDelegate>)delegate
{
	[super setDelegate:delegate];
}

- (void)setFrame:(CGRect)frame
{
	_storedFrame = frame;
	CGSize tileSize = self.tileSize;
	// If paging is enabled, adjust scroll view frame to allow paging by tile size rather than contentSize
	if (self.pagingEnabled)
	{
		CGRect alignedFrame = self.frame;
		alignedFrame.size = tileSize;
		switch (self.alignment.verticalAlignment) {
			case ESTileViewVerticalAlignmentTop:
				alignedFrame.origin.y = _storedFrame.origin.y;
				break;
			case ESTileViewVerticalAlignmentCenter:
				alignedFrame.origin.y = _storedFrame.origin.y + ((_storedFrame.size.height - tileSize.height) / 2.0f);
				break;
			case ESTileViewVerticalAlignmentBottom:
				alignedFrame.origin.y = _storedFrame.origin.y + (_storedFrame.size.height - tileSize.height);
				break;
			default:
				break;
		}
		switch (self.alignment.horizontalAlignment) {
			case ESTileViewHorizontalAlignmentLeft:
				alignedFrame.origin.x = _storedFrame.origin.x;
				break;
			case ESTileViewHorizontalAlignmentCenter:
				alignedFrame.origin.x = _storedFrame.origin.x + ((_storedFrame.size.width - tileSize.width) / 2.0f);
				break;
			case ESTileViewHorizontalAlignmentRight:
				alignedFrame.origin.x = _storedFrame.origin.x + (_storedFrame.size.width - tileSize.width);
				break;
			default:
				break;
		}
		[super setFrame:alignedFrame];
	}
	else
		[super setFrame:frame];
}

- (void)setPagingEnabled:(BOOL)pagingEnabled
{
	[super setPagingEnabled:pagingEnabled];
	// If paging is enabled, we adjust the scrollviews frame
	// causing the scroll indicators to appear out of place
	// so if paging is on we turn off indicators
	[self setShowsHorizontalScrollIndicator:!pagingEnabled];
	[self setShowsVerticalScrollIndicator:!pagingEnabled];
	// Make sure frame is in proper state for paging/not paging
	[self setFrame:_storedFrame];
}

- (void)scrollToTileAtRow:(NSInteger)row column:(NSInteger)column
{
	[self scrollToTileAtRow:row column:column animated:YES];
}

- (void)scrollToTileAtRow:(NSInteger)row column:(NSInteger)column animated:(BOOL)animated
{
	CGSize tileSize = [self tileSize];
	CGRect frame = CGRectMake(tileSize.width * column, 
							  tileSize.height * row, 
							  tileSize.width, 
							  tileSize.height);
	[self scrollRectToVisible:frame animated:animated];
}

#pragma mark - Private
- (NSMutableSet *)reusableTiles
{
	// we will recycle tiles by removing them from the view and storing them here
	if (_reusableTiles == nil)
		_reusableTiles = [NSMutableSet new];
	return _reusableTiles;
}

- (NSMutableSet *)internalVisibleTiles
{
	// set to hold our active tiles
	if (_internalVisibleTiles == nil)
		_internalVisibleTiles = [NSMutableSet new];
	return _internalVisibleTiles;
}

#pragma mark - Layout
- (void)layoutSubviews 
{
	[super layoutSubviews];
	
	if (self.dataSource == nil)
		return;
	
	CGRect visibleBounds = [self bounds];
	visibleBounds.origin.x += (_storedFrame.origin.x - self.frame.origin.x);
	visibleBounds.origin.y += (_storedFrame.origin.y - self.frame.origin.y);
	visibleBounds.size = _storedFrame.size;
	
	// first recycle all tiles that are no longer visible
	NSMutableSet *reusableTiles = self.reusableTiles;
	NSMutableSet *visibleTiles = self.internalVisibleTiles;
	NSArray *tiles = [self.internalVisibleTiles allObjects];
	for (UIView *tile in tiles)
	{
		// Check if tile is on screen
		CGRect scaledTileFrame = [self convertRect:[tile frame] toView:self];
		/**
		 * Expand tiles frame by 1 pixel on all sides to give ourselves some wiggle room with tiles
		 * right on the edge
		 * (This is a crude solution, find something better)
		 */
		scaledTileFrame.size.width += 2.0f;
		scaledTileFrame.size.height += 2.0f;
		scaledTileFrame.origin.x -= 1.0f;
		scaledTileFrame.origin.y -= 1.0f;
		// If the tile doesn't intersect, it's not visible, so we can recycle it
		if (!CGRectIntersectsRect(scaledTileFrame, visibleBounds)) 
		{
			[reusableTiles addObject:tile];
			[tile removeFromSuperview];
			[visibleTiles removeObject:tile];
		}
	}
	// Work out the tiles needed for current bounds
	CGSize tileSize = [self tileSize];
	CGFloat tileWidth  = tileSize.width;
	CGFloat tileHeight = tileSize.height;
	NSInteger maxRow = self.numberOfRows;
	NSInteger maxCol = self.numberOfColumns;
	NSInteger firstNeededRow = MAX(0, floorf(visibleBounds.origin.y / tileHeight));
	NSInteger firstNeededCol = MAX(0, floorf(visibleBounds.origin.x / tileWidth));
	NSInteger lastNeededRow = MIN(maxRow, (NSInteger)floorf(CGRectGetMaxY(visibleBounds) / tileHeight));
	NSInteger lastNeededCol = MIN(maxCol, (NSInteger)floorf(CGRectGetMaxX(visibleBounds) / tileWidth));
	NSInteger maxIndex = maxRow * maxCol;
	// If needed tiles are unchanged, bail out
	if ((_firstVisibleRow == firstNeededRow) &&
		(_firstVisibleColumn == firstNeededCol) &&
		(_lastVisibleRow == lastNeededRow) &&
		(_lastVisibleColumn == lastNeededCol))
		return;
	
	// iterate through needed rows and columns, adding any tiles that are missing
	for (NSInteger row = firstNeededRow; row <= lastNeededRow; row++) 
	{
		NSInteger maxIndexForRow = (row + 1) * maxCol;
		for (NSInteger col = firstNeededCol; col <= lastNeededCol; col++) 
		{
			NSInteger index = row * maxCol + col;
			if (index >= _numberOfTiles)
				break;
			BOOL tileIsMissing = (((_firstVisibleRow > row || _firstVisibleColumn > col) || 
								   (_lastVisibleRow  < row || _lastVisibleColumn  < col)) && 
								  (index < maxIndex) && 
								  (index < maxIndexForRow));
			if (tileIsMissing) 
			{
				UIView *tile = [self.dataSource tileView:((ESTileView *)self.superview) tileForRow:row column:col];
				if (tile)
				{
					tile.tag = index;
					CGRect frame = CGRectMake(tileSize.width * col, 
											  tileSize.height * row, 
											  tileSize.width, 
											  tileSize.height);
					[tile setFrame:frame];
					// insert subview at index 0 so that it doesn't end up on top of scroll indicators
					[self insertSubview:tile atIndex:0];
					[visibleTiles addObject:tile];
				}
			}
		}
	}
	// update our record of which rows/cols are visible
	_firstVisibleRow = firstNeededRow;
	_firstVisibleColumn = firstNeededCol;
	_lastVisibleRow  = lastNeededRow;
	_lastVisibleColumn  = lastNeededCol;
}

- (UIView *)dataSourceTileForRow:(NSInteger)row column:(NSInteger)column
{
	return [self.dataSource tileView:((ESTileView *)self.superview) tileForRow:row column:column];
}

@end
