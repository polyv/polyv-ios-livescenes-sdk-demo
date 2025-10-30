//
//  PLVStickerVideoControl.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/8/25.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVStickerVideoControl;

@protocol PLVStickerVideoControlDelegate <NSObject>

@optional

/// 播放/暂停按钮点击
/// @param control 控制视图
/// @param isPlaying 当前播放状态
- (void)stickerVideoControl:(PLVStickerVideoControl *)control didTapPlayButton:(BOOL)isPlaying;

/// 删除按钮点击
/// @param control 控制视图
- (void)stickerVideoControlDidTapDeleteButton:(PLVStickerVideoControl *)control;

/// 快退按钮点击
/// @param control 控制视图
- (void)stickerVideoControlDidTapBackwardButton:(PLVStickerVideoControl *)control;

/// 快进按钮点击
/// @param control 控制视图
- (void)stickerVideoControlDidTapForwardButton:(PLVStickerVideoControl *)control;

/// 音量按钮点击
/// @param control 控制视图
/// @param isMuted 当前静音状态
- (void)stickerVideoControl:(PLVStickerVideoControl *)control didTapVolumeButton:(BOOL)isMuted;

/// 全屏按钮点击
/// @param control 控制视图
- (void)stickerVideoControlDidTapFullscreenButton:(PLVStickerVideoControl *)control;

/// 进度条拖拽
/// @param control 控制视图
/// @param progress 进度值 (0.0 - 1.0)
- (void)stickerVideoControl:(PLVStickerVideoControl *)control didSeekToProgress:(CGFloat)progress;

@end

@interface PLVStickerVideoControl : UIView

/// 代理
@property (nonatomic, weak) id<PLVStickerVideoControlDelegate> delegate;

/// 是否正在播放
@property (nonatomic, assign) BOOL isPlaying;

/// 是否静音
@property (nonatomic, assign) BOOL isMuted;

/// 当前播放时间（秒）
@property (nonatomic, assign) NSTimeInterval currentTime;

/// 总时长（秒）
@property (nonatomic, assign) NSTimeInterval totalTime;

/// 播放进度 (0.0 - 1.0)
@property (nonatomic, assign) CGFloat progress;

/// 是否显示控制栏
@property (nonatomic, assign) BOOL showsControls;

/// 初始化方法
- (instancetype)initWithFrame:(CGRect)frame;

/// 显示控制栏
- (void)showControls;

/// 隐藏控制栏
- (void)hideControls;

/// 更新播放状态
/// @param isPlaying 是否正在播放
- (void)updatePlayingState:(BOOL)isPlaying;

/// 更新进度
/// @param currentTime 当前时间
/// @param totalTime 总时长
- (void)updateProgress:(NSTimeInterval)currentTime totalTime:(NSTimeInterval)totalTime;

@end

NS_ASSUME_NONNULL_END
