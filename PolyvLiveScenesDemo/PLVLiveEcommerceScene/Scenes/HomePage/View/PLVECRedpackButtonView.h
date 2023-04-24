//
//  PLVECRedpackButtonView.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/1/11.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

#define PLVECRedpackButtonViewWidth (50.0)
#define PLVECRedpackButtonViewHeight (50.0 + 12.0)

NS_ASSUME_NONNULL_BEGIN

@protocol PLVECRedpackButtonViewDelegate;

/// 红包悬浮挂件
@interface PLVECRedpackButtonView : UIView

@property (nonatomic, weak) id<PLVECRedpackButtonViewDelegate> delegate;

/// 显示
/// @param redpackMessageType 红包类型
/// @param delayTime 倒计时时间
- (void)showWithRedpackMessageType:(PLVRedpackMessageType)redpackMessageType delayTime:(NSInteger)delayTime;

/// 隐藏
- (void)dismiss;

@end

@protocol PLVECRedpackButtonViewDelegate <NSObject>

/// 点击挂件触发
- (void)didTpaRedpackButtonView:(PLVECRedpackButtonView *)redpackButtonView;

@end

NS_ASSUME_NONNULL_END
