//
//  PLVSAStatusbarAreaView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
// 状态栏视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVSAStatusbarAreaView;

typedef NS_ENUM(NSInteger, PLVSAStatusBarNetworkQuality){
    PLVSAStatusBarNetworkQuality_Unknown = 0, // 未知
    PLVSAStatusBarNetworkQuality_Good = 1,    // 信号良好
    PLVSAStatusBarNetworkQuality_Fine = 2,    // 信号一般
    PLVSAStatusBarNetworkQuality_Bad = 3,     // 信号差
    PLVSAStatusBarNetworkQuality_Disconnect = 4, // 无法连接
};


@protocol PLVAStatusbarAreaViewDelegate <NSObject>

/// 点击直播信息回调
- (void)statusbarAreaViewDidTapChannelInfoButton:(PLVSAStatusbarAreaView *)statusBarAreaView;

@end

@interface PLVSAStatusbarAreaView : UIView

@property (nonatomic, weak) id<PLVAStatusbarAreaViewDelegate> delegate;

/// 当前是否处于推流状态
@property (nonatomic, assign, readonly) BOOL inClass;

/// 已上课时长，同时更新界面时长文本
@property (nonatomic, assign) NSTimeInterval duration;

/// 网络状态，设置该值同时更新界面网络状态
@property (nonatomic, assign) PLVSAStatusBarNetworkQuality netState;

/// 当前网速，同时更新界面网速
@property (nonatomic, copy) NSString *netSpeed;

/// 开播老师昵称，同时更新界面老师昵称文本
@property (nonatomic, copy) NSString *teacherName;

/// 在线人数，同时更新界面在线人数文本
@property (nonatomic, assign) NSUInteger onlineNum;

/// 当前 本地麦克风音量值 (0.0~1.0)，同时更新界面音量图标
@property (nonatomic, assign) CGFloat localMicVolume;

/// 本地用户的 麦克风 当前是否开启
@property (nonatomic, assign) BOOL currentMicOpen;

/// 开始上课/结束上课
/// @param start YES - 开始上课 NO - 结束上课
- (void)startClass:(BOOL)start;


@end

NS_ASSUME_NONNULL_END
