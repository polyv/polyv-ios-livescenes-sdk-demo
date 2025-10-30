//
//  PLVStickerAudioSet.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/8/26.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVSABottomSheet.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVStickerAudioSet;

@protocol PLVStickerAudioSetDelegate <NSObject>

@optional

/// 视频音量改变回调
/// @param audioSet 音频设置视图
/// @param volume 音量值 (0.0 - 1.0)
- (void)stickerAudioSet:(PLVStickerAudioSet *)audioSet didChangeVideoVolume:(CGFloat)volume;

/// 麦克风音量改变回调
/// @param audioSet 音频设置视图
/// @param volume 音量值 (0.0 - 1.0)
- (void)stickerAudioSet:(PLVStickerAudioSet *)audioSet didChangeMicrophoneVolume:(CGFloat)volume;

@end

@interface PLVStickerAudioSet : PLVSABottomSheet

/// 代理
@property (nonatomic, weak) id<PLVStickerAudioSetDelegate> delegate;

/// 视频音量 (0.0 - 1.0)
@property (nonatomic, assign) CGFloat videoVolume;

/// 麦克风音量 (0.0 - 1.0)
@property (nonatomic, assign) CGFloat microphoneVolume;

/// 初始化方法，支持自定义尺寸
/// @param sheetHeight 弹层弹出高度
/// @param sheetLandscapeWidth 弹层横屏时弹出宽度
- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth;

@end

NS_ASSUME_NONNULL_END
