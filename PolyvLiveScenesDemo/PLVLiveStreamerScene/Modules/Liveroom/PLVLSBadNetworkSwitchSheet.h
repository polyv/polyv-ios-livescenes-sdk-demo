//
//  PLVLSBadNetworkSwitchSheet.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/5/4.
//  Copyright © 2022 PLV. All rights reserved.
// 弱网处理弹层

#import "PLVLSSideSheet.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLSBadNetworkSwitchSheet;

@protocol PLVLSBadNetworkSwitchSheetDelegate <NSObject>

- (void)switchSheet:(PLVLSBadNetworkSwitchSheet *)switchSheet didChangedVideoQosPreference:(PLVBRTCVideoQosPreference)videoQosPreference;

@end

@interface PLVLSBadNetworkSwitchSheet : PLVLSSideSheet

@property (nonatomic, weak) id<PLVLSBadNetworkSwitchSheetDelegate> delegate;

/// 弹出弹层
/// @param parentView 展示弹层的父视图，弹层会插入到父视图的最顶上
/// @param videoQosPreference 当前视频流画质偏好
- (void)showInView:(UIView *)parentView currentVideoQosPreference:(PLVBRTCVideoQosPreference)videoQosPreference;

@end

NS_ASSUME_NONNULL_END
