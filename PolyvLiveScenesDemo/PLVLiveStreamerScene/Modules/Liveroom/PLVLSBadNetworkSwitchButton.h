//
//  PLVLSBadNetworkSwitchButton.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/5/4.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSBadNetworkSwitchButton : UIView

@property (nonatomic, assign, readonly) BOOL selected;

/// 点击触发
@property (nonatomic, copy) void (^buttonActionBlock) (BOOL selected);

/// 初始化方法
/// @param videoQosPreference 当前视频流画质偏好
- (instancetype)initWithVideoQosPreference:(PLVBRTCVideoQosPreference)videoQosPreference;

- (void)setSelected:(BOOL)selected;

@end

NS_ASSUME_NONNULL_END
