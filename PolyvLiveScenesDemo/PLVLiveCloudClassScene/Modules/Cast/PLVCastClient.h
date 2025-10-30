//
//  PLVCastClient.h
//  PLVVodSDKDemo
//
//  Created by MissYasiky on 2020/7/14.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVCastPlayControlView.h"

extern NSString *PLVCastClientLeaveLiveCtrlNotification;

typedef NS_ENUM(NSInteger, PLVCastClientState) {
    PLVCastClientStateUnconnected,              // 暂未有任何投屏连接
    PLVCastClientStateConnectCurrentChannel,    // 当前所在频道正处于投屏中
    PLVCastClientStateConnectOtherChannel,      // 投屏频道并非当前所在频道
};

@protocol PLVCastClientDelegate;

NS_ASSUME_NONNULL_BEGIN

/// 投屏业务 SDK 内部管理类
@interface PLVCastClient : NSObject

/// 数据
// 投屏播放地址
@property (nonatomic, copy) NSString *playUrlString;
// 多码率播放地址集合
@property (nonatomic, copy) NSArray<NSDictionary *> *definitionsArray;

// 是否需要显示屏幕镜像提示视图
@property (nonatomic, assign, readonly) BOOL needShowMirrorTips;

/// UI
// 投屏皮肤
@property (nonatomic, strong, readonly) PLVCastPlayControlView *castControlView;

/// 代理
@property (nonatomic, weak) id <PLVCastClientDelegate> delegate;

/// 获知是否已成功注册，否，则启动注册
/// 调用实例方法之前先通过此方法，若返回 NO 则不生成单例
+ (BOOL)isAuthorizeSuccess;

/// 注册投屏 SDK，生命周期中仅第一次调用有效
/// 建议在 '-application:didFinishLaunchingWithOptions:' 中调用
+ (void)startAuthorize;

/// 获取单例
+ (instancetype)sharedClient;

/// 启用投屏功能
- (void)setupWithNavigationController:(UIViewController *)navController
                            channelID:(NSString *)channelID;

/// 跳转到设备搜索页
- (void)pushTheDeviceSearchViewController;

/// 弹出屏幕镜像功能提示
- (void)showMirrorTipsView;

/// 离开当前播放页面时调用
- (void)leave;

/// 停止投屏功能，释放相关资源
/// 不再需要投屏功能时调用，离开当前播放页不需要调用
- (void)quit;

@end

@protocol PLVCastClientDelegate <NSObject>

/// 开始投屏
- (void)plvCastClientStartPlay;

/// 退出投屏
- (void)plvCastClientQuitPlay;

@end

NS_ASSUME_NONNULL_END
