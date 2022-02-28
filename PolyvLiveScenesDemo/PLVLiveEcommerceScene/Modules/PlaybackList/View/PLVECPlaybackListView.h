//
//  PLVECPlaybackListView.h
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2021/12/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVECBottomView.h"


NS_ASSUME_NONNULL_BEGIN

@interface PLVECPlaybackListView : PLVECBottomView

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, weak, nullable) id <UICollectionViewDataSource> dataSource;

@property (nonatomic, weak, nullable) id <UICollectionViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
