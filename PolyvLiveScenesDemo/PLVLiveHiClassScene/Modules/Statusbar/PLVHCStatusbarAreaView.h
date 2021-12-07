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

/// 互动学堂状态栏状态枚举
typedef NS_ENUM(NSInteger, PLVHiClassStatusbarState){
    PLVHiClassStatusbarStateNotInClass = 0, // 未上课
    PLVHiClassStatusbarStateDelayStartClass = 1, // 已延迟
    PLVHiClassStatusbarStateInClass = 2, // 上课中
    PLVHiClassStatusbarStateDelayFinishClass = 3, // 拖堂
    PLVHiClassStatusbarStateFinishClass = 4, // 已下课
};

@interface PLVHCStatusbarAreaView : UIView

/// 设置状态栏标题文本
- (void)setClassTitle:(NSString *)title;

/// 设置状态栏课节号
- (void)setLessonId:(NSString *)lessonId;

/// 设置状态栏当前状态
- (void)updateState:(PLVHiClassStatusbarState)state;

/// 更新上课时长
- (void)updateDuration:(NSInteger)duration;

/// 设置状态栏网络信号
- (void)setNetworkQuality:(PLVBLinkMicNetworkQuality)networkQuality;

/// 设置网络延迟
- (void)setNetworkDelayTime:(NSInteger)delayTime;

@end

NS_ASSUME_NONNULL_END
