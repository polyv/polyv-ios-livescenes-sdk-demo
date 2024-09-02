//
//  PLVPinMessagePopupView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2024/7/1.
//  Copyright © 2024 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

/// 下墙事件的回调
typedef void (^PLVPinMessageViewCancelTopActionBlock)(PLVSpeakTopMessage *message);

@interface PLVPinMessagePopupView : UIView

/// 是否可以上墙或者下墙操作 默认NO
@property (nonatomic, assign) BOOL canPinMessage;

/// 点开下墙按钮的回调
@property (nonatomic, copy) PLVPinMessageViewCancelTopActionBlock cancelTopActionBlock;

@property (nonatomic, strong, readonly) UIButton *closeButton;

- (void)showPopupView:(BOOL)show message:(PLVSpeakTopMessage * _Nullable)message;

@end

NS_ASSUME_NONNULL_END
