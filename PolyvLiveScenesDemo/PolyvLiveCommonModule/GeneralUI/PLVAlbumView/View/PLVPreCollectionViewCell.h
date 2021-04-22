//
//  PLVPreCollectionViewCell.h
//  zPic
//
//  Created by zykhbl on 2017/7/19.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PLVPreCollectionViewCellDelegate;

@interface PLVPreCollectionViewCell : UICollectionViewCell <UIScrollViewDelegate>

@property (nonatomic, assign) id<PLVPreCollectionViewCellDelegate>delegate;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *photoImgView;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGesture;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPress;
@property (nonatomic, assign) BOOL chaged;
@property (nonatomic, assign) CGFloat baseScale;
@property (nonatomic, strong) NSString *exifStr;
@property (nonatomic, assign) NSTextAlignment textAlignment;

@end

@protocol PLVPreCollectionViewCellDelegate <NSObject>

- (void)PLVPreCollectionViewCell:(PLVPreCollectionViewCell*)cell scrollViewDidEndZooming:(BOOL)flag;
- (void)PLVPreCollectionViewCell:(PLVPreCollectionViewCell*)cell showExif:(BOOL)flag;

@end
