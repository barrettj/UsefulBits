//
//  ESScrollView.m
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

// Reference: http://developer.apple.com/library/ios/#samplecode/ScrollViewSuite/Listings/3_Tiling_Classes_TiledScrollView_m.html#//apple_ref/doc/uid/DTS40008904-3_Tiling_Classes_TiledScrollView_m-DontLinkElementID_26

#import "ESTileView.h"
#import "ESInternalTileView.h"

@interface ESTileView ()
@property (STRONG, nonatomic) ESInternalTileView *internalTileView;
- (void)commonInit;
@end

@implementation ESTileView
@synthesize internalTileView=_internalTileView;

#pragma mark - Setup/Cleanup
- (void)commonInit
{
	_internalTileView = [[ESInternalTileView alloc] initWithFrame:[self bounds]];
	[self addSubview:_internalTileView];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self)
	{
		[self commonInit];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame 
{
	self = [super initWithFrame:frame];
	if (self) 
	{
		[self commonInit];
	}
	return self;
}

- (void)dealloc 
{
	NO_WEAK(
	[_internalTileView setDelegate:nil];
	[_internalTileView setDataSource:nil];
			)
	NO_ARC(
	[_internalTileView release];
	[super dealloc];
		   )
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	self.internalTileView.frame = self.bounds;
	[self.internalTileView setNeedsLayout];
}

// Pass touches to scroll view
// Necessary for partial page size paging
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	UIView *hit = [super hitTest:point withEvent:event];
	if (hit == self)
		return self.internalTileView;
	return hit;
}

- (void)didMoveToSuperview
{
	[super didMoveToSuperview];
	if (self.internalTileView.dataSource)
		[self.internalTileView reloadData];
}

#pragma mark - Pass Through Properties
- (id<ESTileViewDataSource>)dataSource
{
	return self.internalTileView.dataSource;
}

- (void)setDataSource:(id<ESTileViewDataSource>)dataSource
{
	self.internalTileView.dataSource = dataSource;
}

- (id<ESTileViewDelegate>)delegate
{
	return self.internalTileView.delegate;
}

- (void)setDelegate:(id<ESTileViewDelegate>)delegate
{
	self.internalTileView.delegate = delegate;
}

- (UIView *)dequeueReusableTile
{
	return [self.internalTileView dequeueReusableTile];
}

- (void)reloadData
{
	[self.internalTileView reloadData];
}

- (NSArray *)visibleTiles
{
	return [self.internalTileView visibleTiles];
}

- (BOOL)pagingEnabled
{
	return self.internalTileView.pagingEnabled;
}

- (void)setPagingEnabled:(BOOL)pagingEnabled
{
	self.internalTileView.pagingEnabled = pagingEnabled;
}

- (NSInteger)numberOfRows
{
	return self.internalTileView.numberOfRows;
}

- (void)setNumberOfRows:(NSInteger)numberOfRows
{
	self.internalTileView.numberOfRows = numberOfRows;
}

- (NSInteger)numberOfColumns
{
	return self.internalTileView.numberOfColumns;
}

- (void)setNumberOfColumns:(NSInteger)numberOfColumns
{
	self.internalTileView.numberOfColumns = numberOfColumns;
}

- (CGSize)tileSize
{
	return self.internalTileView.tileSize;
}

- (void)setTileSize:(CGSize)tileSize
{
	self.internalTileView.tileSize = tileSize;
}

- (ESTileViewAlignment)alignment
{
	return self.internalTileView.alignment;
}

- (void)setAlignment:(ESTileViewAlignment)alignment
{
	self.internalTileView.alignment = alignment;
}

- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
	self.internalTileView.frame = self.bounds;
}

- (void)scrollToTileAtRow:(NSInteger)row column:(NSInteger)column
{
	[self.internalTileView scrollToTileAtRow:row column:column];
}

- (void)scrollToTileAtRow:(NSInteger)row column:(NSInteger)column animated:(BOOL)animated
{
	[self.internalTileView scrollToTileAtRow:row column:column animated:animated];
}

@end
