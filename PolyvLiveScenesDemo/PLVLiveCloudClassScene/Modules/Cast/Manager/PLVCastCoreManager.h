//
//  PLVCastCoreManager.h
//  PLVCloudClassDemo
//
//  Created by MissYasiky on 2020/7/14.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@class PLVCastServiceModel;

typedef NS_ENUM(NSUInteger, PLVWCastPlayStatus) {
    PLVWCastPlayStatusUnkown = 0,
    PLVWCastPlayStatusLoading,
    PLVWCastPlayStatusPlaying,
    PLVWCastPlayStatusPause,
    PLVWCastPlayStatusStopped,
    PLVWCastPlayStatusCommpleted,
    PLVWCastPlayStatusError,
};

@protocol PLVCastDeviceSearchDelegate <NSObject>

// 设备搜索发现设备回调
- (void)castManagerFindServices:(NSArray <PLVCastServiceModel *>*)servicesArray;

// 设备搜索状态变更回调
- (void)castManagerSearchStateChanged:(BOOL)start;

@end

@protocol PLVCastManagerDelegate <NSObject>

// 投屏错误回调
// 包括搜索中、连接中、投屏过程中错误
// error为空，代表其他未知情况
- (void)castManagerOnError:(nullable NSError *)error;

// 设备成功连接回调
- (void)castManagerDidConnectedWithService:(PLVCastServiceModel *)service;

// 设备断开连接, 可根据 isPassive 判断是否是被动断开
- (void)castManagerDisonnectPassive:(BOOL)isPassive;

// 播放状态回调
- (void)castManagerPlayStatusChanged:(PLVWCastPlayStatus)status;

@end

/// 投屏核心功能管理类
@interface PLVCastCoreManager : NSObject

@property (nonatomic, weak) id <PLVCastDeviceSearchDelegate> deviceDelegate;

@property (nonatomic, weak) id <PLVCastManagerDelegate> delegate;
/// 当前是否有连接中的设备
@property (nonatomic, assign, readonly) BOOL connected;

/// 获知是否已成功注册，否，则启动注册
+ (BOOL)isAuthorizeSuccess;

/// 注册投屏 SDK，当需要投屏业务时，可提前调用此方法。生命周期中仅第一次调用有效
+ (void)startAuthorize;

/// 获取单例
+ (instancetype)sharedManager;

/// 退出投屏时调用
- (void)clear;

#pragma mark 设备搜索操作

/// 开始搜索
- (void)startSearchService;

/// 停止搜索，若不停止，则设备列表会持续刷新及回调
- (void)stopSearchService;

#pragma mark 设备连接操作

/// 用 deviceName 作为标识寻找设备模型
- (PLVCastServiceModel *)connectServiceWithDeviceName:(NSString *)deviceName;

/// 断开当前连接
- (void)disconnect;

/// 判断当前设备模型是否是连接中的投屏设备
- (BOOL)isServiceConnecting:(PLVCastServiceModel *)service;

#pragma mark 设备播放操作

/// 根据 UrlString 进行播放
- (void)startPlayWithUrlString:(NSString *)urlString;

/// 暂停播放
- (void)pause;

/// 恢复播放
- (void)resume;

/// 退出播放
- (void)stop;

/// 进度调节 单位：秒
- (void)seekTo:(NSInteger)seekTime;

/// 增加音量
- (void)addVolume;

/// 减少音量
- (void)reduceVolume;

/// 设置音量值 范围：0~100
- (void)setVolume:(NSInteger)value;


@end

/// 投屏设备信息模型
@interface PLVCastServiceModel : NSObject

/// 唯一标识
@property (nonatomic, copy) NSString *tvUID;

/// 设备名
@property (nonatomic, copy) NSString * deviceName;

/// 是否当前连接中的设备
@property (nonatomic, assign) BOOL isConnecting;

/// 对应的乐播服务
//@property (nonatomic, strong) LBLelinkService * lbService;

@end

NS_ASSUME_NONNULL_END
