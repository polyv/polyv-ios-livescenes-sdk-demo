//
//  PLVHCStatusbarAreaView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 PLV. All rights reserved.
//
// 状态栏区域视图

#import <UIKit/UIKit.h>

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVHCStatusbarAreaViewDelegate;

@interface PLVHCStatusbarAreaView : UIView

@property (nonatomic, weak) id<PLVHCStatusbarAreaViewDelegate> delegate;

/// 延迟上课
- (void)delayStartClass;

/// 开始上课
- (void)startClass;

///结束课程需要调用清除上课计时器
- (void)finishClass;

/// 设置状态栏网络信号
- (void)setNetworkQuality:(PLVBLinkMicNetworkQuality)networkQuality;

/// 设置网络延迟
- (void)setNetworkDelayTime:(NSInteger)delayTime;

@end

///状态栏代理
@protocol PLVHCStatusbarAreaViewDelegate <NSObject>

/// 强制下课处理，拖堂到最大时长后
- (void)statusbarAreaViewDidForcedFinishClass:(PLVHCStatusbarAreaView *)areaView;

@end

NS_ASSUME_NONNULL_END
