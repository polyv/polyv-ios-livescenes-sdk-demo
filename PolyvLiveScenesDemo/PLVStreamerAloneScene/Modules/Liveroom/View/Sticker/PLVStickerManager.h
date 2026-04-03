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
@class PLVMobileTemplateLayerModel;

@protocol PLVStickerManagerDelegate <NSObject>

@optional
/// 贴图管理器进入编辑模式
- (void)stickerManagerDidEnterEditMode:(PLVStickerManager *)manager;

/// 贴图管理器退出编辑模式
- (void)stickerManagerDidExitEditMode:(PLVStickerManager *)manager;

/// 回调图片
- (void)stickerManager:(PLVStickerManager *)manager didGenerateImage:(UIImage *)image;

/// 回调音频
- (void)stickerManager:(PLVStickerManager *)manager didUpdateAudioPacket:(NSDictionary *)audioPacket;

/// 音频音量设置改变回调
- (void)stickerManager:(PLVStickerManager *)manager didChangeAudioVolume:(CGFloat)stickerVolume microphoneVolume:(CGFloat)micVolume;

@end

@interface PLVStickerManager : NSObject

@property (nonatomic, weak) id<PLVStickerManagerDelegate> delegate;

@property (nonatomic, strong, readonly) PLVStickerCanvas *stickerCanvas;


/// 初始化方法
/// @param parentView 父视图，用于显示贴图画布和各种弹窗
- (instancetype)initWithParentView:(UIView *)parentView;

/// 显示贴图类型选择视图
- (void)showStickerTypeSelection;

/// 显示贴图类型 视频
- (void)showStickerTypeForVideo;

/// 生成贴图图像
- (UIImage *)generateStickerImage;

/// 以指定位置添加图片贴图
- (void)addImageSticker:(UIImage *)image frame:(CGRect)frame;

/// 以指定位置添加文字贴图
- (void)addTextStickerWithText:(NSString *)text frame:(CGRect)frame;

/// 清除所有贴图
- (void)clearAllStickers;

/// 下载网络图片
- (void)fetchImageWithURLString:(NSString *)urlString completion:(void (^)(UIImage * _Nullable image))completion;

/// 应用模板中的贴图层（文字/图片），完成后回调合成后的贴图图像
- (void)applyTemplateStickerLayers:(NSArray<PLVMobileTemplateLayerModel *> *)layers
                         completion:(void(^)(UIImage * _Nullable stickerImage))completion;

@end

NS_ASSUME_NONNULL_END 
