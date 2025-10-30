//
//  PLVCastCoreBusinessManager.h
//  PLVCloudClassSDK
//
//  Created by MissYasiky on 2020/7/23.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 播放状态
 */
typedef NS_ENUM(NSUInteger, PLVCastPlayStatus) {
    PLVCastPlayStatusUnkown = 0,    // 未知状态
    PLVCastPlayStatusLoading,       // 视频正在加载状态
    PLVCastPlayStatusPlaying,       // 正在播放状态
    PLVCastPlayStatusPause,         // 暂停状态
    PLVCastPlayStatusStopped,       // 退出播放状态
    PLVCastPlayStatusCommpleted,    // 播放完成状态
    PLVCastPlayStatusError,         // 播放错误
};

@protocol PLVCastBusinessDelegate <NSObject>

@optional

/// 初始化投屏SDK
/// @param success YES:成功 NO:失败
- (void)castAuthorize:(BOOL)success;

/// 开始连接投屏设备
- (void)castConnectStart;

/// 投屏设备连接成功
- (void)castConnectSuccess;

/// 投屏设备连接失败
/// @param error 连接失败 error
- (void)castConnectError:(NSError *)error;

/// 投屏设备连接断开
- (void)castDisconnect;

/// 投屏播放错误
- (void)castPlayError:(NSError *)error;

/// 投屏播放状态变化
- (void)castPlayStatus:(PLVCastPlayStatus)status;

///  进入当前正在投屏的直播间观看页
/// @param channelId 直播间频道号
- (void)castEnterLiveRoom:(NSString *)channelId;

/// 离开当前正在投屏的直播间观看页
/// @param channelId 直播间频道号 
- (void)castLeaveLiveRoom:(NSString *)channelId;

@end

@interface PLVCastCoreBusinessManager : NSObject

@property (nonatomic, weak) id<PLVCastBusinessDelegate> delegate;

/// 获取单例
+ (instancetype)sharedManager;

/// 注册投屏 SDK，该方法只在第一次调用有效
/// 要在调用这个方法之前先设置 delegate 才可以获取注册结果的回调
- (void)startAuthorize;

/// 停止投屏功能，释放相关资源
/// 不再需要投屏功能时调用
- (void)quit;

@end

NS_ASSUME_NONNULL_END
