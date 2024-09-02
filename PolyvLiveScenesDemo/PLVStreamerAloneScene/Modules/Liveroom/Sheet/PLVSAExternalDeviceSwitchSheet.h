//
//  PLVSAExternalDeviceSwitchSheet.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/8/2.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVSABottomSheet.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVSAExternalDeviceSwitchSheet;

@protocol PLVSAExternalDeviceSwitchSheetDelegate <NSObject>

- (void)externalDeviceSwitchSheet:(PLVSAExternalDeviceSwitchSheet *)externalDeviceSwitchSheet wannaChangeExternalDevice:(BOOL)enabled;

@end

@interface PLVSAExternalDeviceSwitchSheet : PLVSABottomSheet

@property (nonatomic, weak) id<PLVSAExternalDeviceSwitchSheetDelegate> delegate;

/// 弹出弹层
/// @param parentView 展示弹层的父视图，弹层会插入到父视图的最顶上
/// @param enabled 当前 支持外接设备 是否开启
- (void)showInView:(UIView *)parentView currentExternalDeviceEnabled:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END
