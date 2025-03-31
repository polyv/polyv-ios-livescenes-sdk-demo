//
//  PLVStickerCanvas.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/3/17.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVStickerCanvas;

@protocol PLVStickerCanvasDelegate <NSObject>

/// 退出编辑模式
- (void)stickerCanvasExitEditMode:(PLVStickerCanvas *)stickerCanvas;

/// 进入编辑模式
- (void)stickerCanvasEnterEditMode:(PLVStickerCanvas *)stickerCanvas;

@end

@interface PLVStickerCanvas : UIView

@property (nonatomic, weak) id<PLVStickerCanvasDelegate> delegate;

@property (nonatomic, assign) BOOL enableEdit;

@property (nonatomic, readonly) NSInteger curImageCount;


/// 展示贴图画布
- (void)showCanvasWithImages:(NSArray<UIImage *> *)images;

/// 生成带透明通道的图片，子控件不透明
- (UIImage *)generateImageWithTransparentBackground;

@end

NS_ASSUME_NONNULL_END
