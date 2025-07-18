//
//  PLVLSExternalDeviceSwitchSheet.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/7/1.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVLSSideSheet.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLSExternalDeviceSwitchSheet;

@protocol PLVLSExternalDeviceSwitchSheetDelegate <NSObject>

- (void)externalDeviceSwitchSheet:(PLVLSExternalDeviceSwitchSheet *)externalDeviceSwitchSheet wannaChangeExternalDevice:(BOOL)enabled;

@end

@interface PLVLSExternalDeviceSwitchSheet : PLVLSSideSheet

@property (nonatomic, weak) id<PLVLSExternalDeviceSwitchSheetDelegate> delegate;

/// 弹出弹层
/// @param parentView 展示弹层的父视图，弹层会插入到父视图的最顶上
/// @param enabled 当前 支持外接设备 是否开启
- (void)showInView:(UIView *)parentView currentExternalDeviceEnabled:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END 