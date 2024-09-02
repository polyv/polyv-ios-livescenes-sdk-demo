//
//  PLVSANoiseCancellationModeSwitchSheet.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/7/30.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVSABottomSheet.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVSANoiseCancellationModeSwitchSheet;

@protocol PLVSANoiseCancellationModeSwitchSheetDelegate <NSObject>

- (void)noiseCancellationModeSwitchSheet:(PLVSANoiseCancellationModeSwitchSheet *)noiseCancellationModeSwitchSheet wannaChangeNoiseCancellationLevel:(PLVBLinkMicNoiseCancellationLevel)noiseCancellationLevel;

@end

@interface PLVSANoiseCancellationModeSwitchSheet : PLVSABottomSheet

@property (nonatomic, weak) id<PLVSANoiseCancellationModeSwitchSheetDelegate> delegate;

/// 弹出弹层
/// @param parentView 展示弹层的父视图，弹层会插入到父视图的最顶上
/// @param localNoiseCancellationLevel 当前 本地音频流降噪等级
- (void)showInView:(UIView *)parentView currentNoiseCancellationLevel:(PLVBLinkMicNoiseCancellationLevel)localNoiseCancellationLevel;

@end

NS_ASSUME_NONNULL_END
