//
//  PLVStickerManager.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2023/9/15.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVStickerTypeSelectionView.h"
#import "PLVStickerTextModel.h"
#import "PLVStickerCanvas.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVStickerManager;

@protocol PLVStickerManagerDelegate <NSObject>

@optional
/// 贴图管理器进入编辑模式
- (void)stickerManagerDidEnterEditMode:(PLVStickerManager *)manager;

/// 贴图管理器退出编辑模式
- (void)stickerManagerDidExitEditMode:(PLVStickerManager *)manager;

@end

@interface PLVStickerManager : NSObject

@property (nonatomic, weak) id<PLVStickerManagerDelegate> delegate;

@property (nonatomic, strong, readonly) PLVStickerCanvas *stickerCanvas;


/// 初始化方法
/// @param parentView 父视图，用于显示贴图画布和各种弹窗
- (instancetype)initWithParentView:(UIView *)parentView;

/// 显示贴图类型选择视图
- (void)showStickerTypeSelection;

/// 生成贴图图像
- (UIImage *)generateStickerImage;

/// 清除所有贴图
- (void)clearAllStickers;

@end

NS_ASSUME_NONNULL_END 
