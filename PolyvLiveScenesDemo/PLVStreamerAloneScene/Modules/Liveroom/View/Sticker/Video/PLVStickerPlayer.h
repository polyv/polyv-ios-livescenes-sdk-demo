//
//  PLVStickerPlayer.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/8/14.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 播放器状态枚举
typedef NS_ENUM(NSInteger, PLVStickerPlayerState) {
    PLVStickerPlayerStateIdle = 0,      // 空闲状态
    PLVStickerPlayerStatePreparing,     // 准备中
    PLVStickerPlayerStatePlaying,       // 播放中
    PLVStickerPlayerStatePaused,        // 暂停
    PLVStickerPlayerStateStopped,       // 停止
    PLVStickerPlayerStateError,         // 错误
    PLVStickerPlayerStateCompleted      // 播放完成
};

@class PLVStickerPlayer;

/// 播放器状态回调代理
@protocol PLVStickerPlayerDelegate <NSObject>

@optional
/// 播放器状态改变回调
/// @param player 播放器实例
/// @param state 新的播放器状态
- (void)stickerPlayer:(PLVStickerPlayer *)player didChangeState:(PLVStickerPlayerState)state;

/// 播放进度回调
/// @param player 播放器实例
/// @param currentTime 当前播放时间（秒）
/// @param totalTime 总时长（秒）
- (void)stickerPlayer:(PLVStickerPlayer *)player didUpdateProgress:(NSTimeInterval)currentTime totalTime:(NSTimeInterval)totalTime;

/// 播放错误回调
/// @param player 播放器实例
/// @param error 错误信息
- (void)stickerPlayer:(PLVStickerPlayer *)player didFailWithError:(NSError *)error;

/// 音频数据回调
/// @param player 播放器实例
/// @param audioPacket 音频数据包
- (void)stickerPlayer:(PLVStickerPlayer *)player didUpdateAudioPacket:(NSDictionary *)audioPacket;

/// 视频尺寸准备完成回调
/// @param player 播放器实例
/// @param videoSize 视频原始尺寸
- (void)stickerPlayer:(PLVStickerPlayer *)player didPrepareWithVideoSize:(CGSize)videoSize;

@end

@interface PLVStickerPlayer : NSObject

/// 代理
@property (nonatomic, weak) id<PLVStickerPlayerDelegate> delegate;

/// 当前播放器状态
@property (nonatomic, assign, readonly) PLVStickerPlayerState state;

/// 播放器视图
@property (nonatomic, strong, readonly) UIView *playerView;

/// 当前播放时间（秒）
@property (nonatomic, assign, readonly) NSTimeInterval currentTime;

/// 总时长（秒）
@property (nonatomic, assign, readonly) NSTimeInterval totalTime;

/// 是否正在播放
@property (nonatomic, assign, readonly) BOOL isPlaying;

/// 初始化播放器
/// @param url 播放链接
- (instancetype)initWithURL:(NSURL *)url;

/// 开始播放
- (void)play;

/// 暂停播放
- (void)pause;

/// 停止播放
- (void)stop;

/// 跳转到指定时间点
/// @param time 目标时间（秒）
- (void)seekToTime:(NSTimeInterval)time;

/// 设置音量
- (void)setupVolume:(CGFloat)volume;

/// 销毁播放器
- (void)destroy;

/// 获取当前播放画面的截图
/// @return 当前画面的截图，如果没有画面则返回nil
- (UIImage *)snapshot;

/// 获取视频尺寸
/// @return 视频尺寸
- (CGSize)videoSize;

@end

NS_ASSUME_NONNULL_END
