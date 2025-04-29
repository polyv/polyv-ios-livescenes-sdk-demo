//
//  PLVVirtualBackgroudCollectionView.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/4/10.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVVirtualBackgroudCell.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVVirtualBackgroudCollectionView;

@protocol PLVVirtualBackgroudCollectionViewDelegate <NSObject>

@optional
/// 点击了某个虚拟背景
- (void)virtualBackgroudCollectionView:(PLVVirtualBackgroudCollectionView *)collectionView data:(PLVVirtualBackgroudModel *)model;

/// 点击了上传按钮
- (void)virtualBackgroudCollectionViewDidClickUploadButton:(PLVVirtualBackgroudCollectionView *)collectionView;

@end

@interface PLVVirtualBackgroudCollectionView : UIView

/// 代理对象
@property (nonatomic, weak) id<PLVVirtualBackgroudCollectionViewDelegate> delegate;

@property (nonatomic, assign, readonly) NSInteger customImgCoutn;

/// 设置虚拟背景图片列表
/// @param images 图片数组
- (void)setupWithBackgroundImages:(NSArray<UIImage *> *)images;

/// 添加上传的背景图片
/// @param image 上传的图片
- (void)addUploadedImage:(UIImage *)image;


@end

NS_ASSUME_NONNULL_END
