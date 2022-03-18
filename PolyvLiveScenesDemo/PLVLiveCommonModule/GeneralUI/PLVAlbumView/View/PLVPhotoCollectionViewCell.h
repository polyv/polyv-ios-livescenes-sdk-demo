//
//  PLVPhotoCollectionViewCell.h
//  zPic
//
//  Created by zykhbl on 2017/7/10.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PLVPhotoCollectionViewCellDelegate;
DEPRECATED_MSG_ATTRIBUTE("已废弃，该模块与PLVImagePickerControllernen能力重复，后续请使用PLVImagePickerController")
@interface PLVPhotoCollectionViewCell : UICollectionViewCell

@property (nonatomic, assign) id<PLVPhotoCollectionViewCellDelegate> delegate;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) UIImageView *photoImgView;
@property (nonatomic, strong) UIView *selectedBgView;
@property (nonatomic, strong) UILabel *selectedLabel;
@property (nonatomic, strong) UILabel *videoDurationLabel;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPress;

@end

@protocol PLVPhotoCollectionViewCellDelegate <NSObject>

- (void)PLVPhotoCollectionViewCell:(PLVPhotoCollectionViewCell*)cell preview:(BOOL)glag;

@end
