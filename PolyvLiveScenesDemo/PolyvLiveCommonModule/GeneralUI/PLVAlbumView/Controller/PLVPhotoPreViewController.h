//
//  PLVPhotoPreViewController.h
//  zPic
//
//  Created by zykhbl on 2017/7/19.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import "PLVPhotoPreBaseViewController.h"
#import "PLVPreCollectionViewCell.h"

@protocol PLVPhotoPreViewControllerDelegate;

@interface PLVPhotoPreViewController : PLVPhotoPreBaseViewController <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UIScrollViewDelegate, PLVPreCollectionViewCellDelegate>

@property (nonatomic, assign) id<PLVPhotoPreViewControllerDelegate> delegate;
@property (nonatomic, strong) UILabel *selectedLabel;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *selectedItems;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) NSInteger curIndex;
@property (nonatomic, assign) NSUInteger scrollIndex;
@property (nonatomic, assign) BOOL hiddenToolbar;
@property (nonatomic, assign) NSInteger photoCount;
@property (nonatomic, assign) BOOL showedExif;
@property (nonatomic, assign) CGRect showRect;
@property (nonatomic, assign) CGRect hiddenRect;
@property (nonatomic, strong) UILabel *exifLabel;

@end

@protocol PLVPhotoPreViewControllerDelegate <NSObject>

- (void)PLVPhotoPreViewController:(PLVPhotoPreViewController*)preVC select:(NSUInteger)index;

@end
