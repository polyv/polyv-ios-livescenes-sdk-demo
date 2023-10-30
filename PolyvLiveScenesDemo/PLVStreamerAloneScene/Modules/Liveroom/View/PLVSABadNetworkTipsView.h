//
//  PLVSABadNetworkTipsView.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/4/28.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVSABadNetworkTipsView : UIView

@property (nonatomic, assign, readonly) BOOL showing;

@property (nonatomic, assign, readonly) CGSize viewSize;

/// 点击【马上切换】触发
@property (nonatomic, copy) void (^switchButtonActionBlock) (void);

/// 点击关闭按钮触发
@property (nonatomic, copy) void (^closeButtonActionBlock) (void);

- (void)showAtView:(UIView *)superView aboveSubview:(UIView *)aboveView;

- (void)dismiss;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
