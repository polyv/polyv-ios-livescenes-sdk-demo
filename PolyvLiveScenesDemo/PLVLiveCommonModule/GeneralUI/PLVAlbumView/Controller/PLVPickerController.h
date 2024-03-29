//
//  PLVPickerController.h
//  zPic
//
//  Created by zykhbl on 2017/7/10.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVPhotoCollectionViewCell.h"
#import "PLVAlbumPhotoPreViewController.h"
#import "PLVAlbumsViewController.h"
DEPRECATED_MSG_ATTRIBUTE("已废弃，该模块与PLVImagePickerControllernen能力重复，后续请使用PLVImagePickerController")
@protocol PLVPickerControllerDelegate;

@interface PLVPickerController : UIViewController <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UINavigationControllerDelegate, PHPhotoLibraryChangeObserver, PLVPhotoCollectionViewCellDelegate, PLVAlbumPhotoPreViewControllerDelegate, PLVAlbumsViewControllerDelegate>

@property (nonatomic, assign) id<PLVPickerControllerDelegate> delegate;
@property (nonatomic, assign) CGFloat collectionFooterHeight;
@property (nonatomic, assign) PickerModer pickerModer;
@property (nonatomic, assign) NSUInteger maxPhotoAndVideoCount;
@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) PHAssetCollection *assetCollection;
@property (nonatomic, strong) PHFetchResult<PHAsset*> *assets;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, assign) NSInteger photoCount;
@property (nonatomic, assign) NSInteger videoCount;
@property (nonatomic, strong) NSMutableArray *selectedItems;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong) NSMutableArray *panSelectedItems;
@property (nonatomic, strong) NSMutableArray *delPanItems;
@property (nonatomic, strong) NSIndexPath *prePanSelectIndexPath;
@property (nonatomic, strong) NSIndexPath *firstPanSelectIndexPath;
@property (nonatomic, assign) CGPoint prePanPoint;
@property (nonatomic, assign) CGFloat originY;
@property (nonatomic, assign) CGFloat cellWidth;

@property (nonatomic, strong) NSSet *runLoopModes;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) BOOL moving;
@property (nonatomic, assign) CGFloat speed;

@property (nonatomic, strong) UIView *toolBar;
@property (nonatomic, strong) UIButton *albumsBtn;
@property (nonatomic, strong) UIImageView *arrowDownImgView;
@property (nonatomic, strong) PLVAlbumsViewController *albumsVC;
@property (nonatomic, assign) NSInteger countOfOneScreen;

@property (nonatomic, strong) UIButton *sendBtn;

- (id)initWithPickerModer:(PickerModer)pModer;

@end

@protocol PLVPickerControllerDelegate <NSObject>

- (void)pickerController:(PLVPickerController*)pVC uploadImage:(UIImage *)uploadImage;

- (void)dismissPickerController:(PLVPickerController*)pVC;

@end
