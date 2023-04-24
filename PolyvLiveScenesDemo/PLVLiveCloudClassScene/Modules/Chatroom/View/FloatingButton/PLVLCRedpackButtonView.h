//
//  PLVLCRedpackButtonView.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/1/11.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

#define PLVLCRedpackButtonViewWidth (50.0)
#define PLVLCRedpackButtonViewHeight (50.0 + 12.0)

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLCRedpackButtonViewDelegate;

/// 红包悬浮挂件
@interface PLVLCRedpackButtonView : UIView

@property (nonatomic, weak) id<PLVLCRedpackButtonViewDelegate> delegate;

/// 显示
/// @param redpackMessageType 红包类型
/// @param delayTime 倒计时时间
- (void)showWithRedpackMessageType:(PLVRedpackMessageType)redpackMessageType delayTime:(NSInteger)delayTime;

/// 隐藏
- (void)dismiss;

@end

@protocol PLVLCRedpackButtonViewDelegate <NSObject>

/// 点击挂件触发
- (void)didTpaRedpackButtonView:(PLVLCRedpackButtonView *)redpackButtonView;

@end

NS_ASSUME_NONNULL_END
