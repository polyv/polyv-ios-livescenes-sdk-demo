//
//  PLVAlbumPhotoPreViewController.h
//  zPic
//
//  Created by zykhbl on 2017/7/19.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import "PLVPhotoPreBaseViewController.h"
#import "PLVPreCollectionViewCell.h"

@protocol PLVAlbumPhotoPreViewControllerDelegate;
DEPRECATED_MSG_ATTRIBUTE("已废弃，该模块与PLVImagePickerControllernen能力重复，后续请使用PLVImagePickerController")
@interface PLVAlbumPhotoPreViewController : PLVPhotoPreBaseViewController <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UIScrollViewDelegate, PLVPreCollectionViewCellDelegate>

@property (nonatomic, assign) id<PLVAlbumPhotoPreViewControllerDelegate> delegate;
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

@protocol PLVAlbumPhotoPreViewControllerDelegate <NSObject>

- (void)PLVAlbumPhotoPreViewController:(PLVAlbumPhotoPreViewController*)preVC select:(NSUInteger)index;

@end
