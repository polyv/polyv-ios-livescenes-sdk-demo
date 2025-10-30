//
//  PLVStickerVideoView.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/8/14.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVStickerVideoView;
@class PLVStickerPlayer;

@protocol PLVStickerVideoViewDelegate <NSObject>

@optional

/// 视频贴图被点击
/// @param stickerView 视频贴图视图
- (void)plv_StickerVideoViewDidTapContentView:(PLVStickerVideoView *)stickerView;

/// 视频贴图移动
/// @param stickerView 视频贴图视图
/// @param point 触摸点
/// @param ended 手势是否结束
- (void)plv_StickerVideoViewHandleMove:(PLVStickerVideoView *)stickerView point:(CGPoint)point gestureEnded:(BOOL)ended;

/// Done按钮点击回调
/// @param stickerView 视频贴图视图
- (void)plv_StickerVideoViewDidTapDoneButton:(PLVStickerVideoView *)stickerView;

/// 播放按钮点击回调
/// @param stickerView 视频贴图视图
/// @param isPlaying 当前播放状态
- (void)plv_StickerVideoViewDidTapPlayButton:(PLVStickerVideoView *)stickerView isPlaying:(BOOL)isPlaying;

/// 回调音频数据包
/// @param stickerView 视频贴图视图
/// @param audioPacket 音频数据包
- (void)plv_StickerVideoViewDidUpdateAudioPacket:(PLVStickerVideoView *)stickerView audioPacket:(NSDictionary *)audioPacket;

/// 麦克风音量改变回调
/// @param stickerView 视频贴图视图
/// @param volume 音量值 (0.0 - 1.0)
- (void)plv_StickerVideoView:(PLVStickerVideoView *)stickerView didChangeMicrophoneVolume:(CGFloat)volume;

/// 音频音量设置改变回调（同时设置贴纸推流音凉 和 本地播放器音量）
/// @param stickerView 视频贴图视图
/// @param stickerVolume 贴纸音频音量值 (0.0 - 1.0)
/// @param micVolume 麦克风音量值 (0.0 - 1.0)
- (void)plv_StickerVideoView:(PLVStickerVideoView *)stickerView didChangeAudioVolume:(CGFloat)stickerVolume microphoneVolume:(CGFloat)micVolume;

/// 视频贴图删除按钮点击回调
/// @param stickerView 视频贴图视图
- (void)plv_StickerVideoViewDidTapDeleteButton:(PLVStickerVideoView *)stickerView;

@end

@interface PLVStickerVideoView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, strong, readonly) PLVStickerPlayer *player;

/// 代理
@property (nonatomic, weak, nullable) id<PLVStickerVideoViewDelegate> delegate;

/// 最小缩放比例
@property (nonatomic, assign) CGFloat stickerMinScale;

/// 最大缩放比例
@property (nonatomic, assign) CGFloat stickerMaxScale;

/// 是否启用控制
@property (nonatomic, assign) BOOL enabledControl;

/// 是否启用抖动动画
@property (nonatomic, assign) BOOL enabledShakeAnimation;

/// 是否显示边框
@property (nonatomic, assign) BOOL enabledBorder;

/// 是否启用编辑
@property (nonatomic, assign) BOOL enableEdit;

/// 视频URL
@property (nonatomic, strong, nullable) NSURL *videoURL;

/// 是否自动播放
@property (nonatomic, assign) BOOL autoPlay;

/// 是否静音播放
@property (nonatomic, assign) BOOL muted;

/// 视频音量 (0.0 - 1.0)
@property (nonatomic, assign) CGFloat videoVolume;

/// 麦克风音量 (0.0 - 1.0)
@property (nonatomic, assign) CGFloat microphoneVolume;

/// 初始化方法
/// @param frame 初始frame
/// @param videoURL 视频URL
- (instancetype)initWithFrame:(CGRect)frame videoURL:(NSURL *)videoURL;

/// 执行点击操作
- (void)performTapOperation;

/// 播放视频
- (void)play;

/// 暂停视频
- (void)pause;

/// 停止视频
- (void)stop;

/// 跳转到指定时间
/// @param time 目标时间（秒）
- (void)seekToTime:(NSTimeInterval)time;

/// 隐藏视频控制栏
- (void)hideVideoControl;

/// 重置组件大小
- (void)resetRect;

@end

NS_ASSUME_NONNULL_END
