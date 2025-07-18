//
//  PLVLSNoiseCancellationModeSwitchSheet.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/7/1.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVLSSideSheet.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLSNoiseCancellationModeSwitchSheet;

@protocol PLVLSNoiseCancellationModeSwitchSheetDelegate <NSObject>

- (void)noiseCancellationModeSwitchSheet:(PLVLSNoiseCancellationModeSwitchSheet *)noiseCancellationModeSwitchSheet wannaChangeNoiseCancellationLevel:(PLVBLinkMicNoiseCancellationLevel)noiseCancellationLevel;

@end

@interface PLVLSNoiseCancellationModeSwitchSheet : PLVLSSideSheet

@property (nonatomic, weak) id<PLVLSNoiseCancellationModeSwitchSheetDelegate> delegate;

/// 弹出弹层
/// @param parentView 展示弹层的父视图，弹层会插入到父视图的最顶上
/// @param localNoiseCancellationLevel 当前 本地音频流降噪等级
- (void)showInView:(UIView *)parentView currentNoiseCancellationLevel:(PLVBLinkMicNoiseCancellationLevel)localNoiseCancellationLevel;

@end

NS_ASSUME_NONNULL_END 
