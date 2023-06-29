//
//  PLVLSSwitchSuccessTipsView.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/4/28.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define kPLVLSSwitchSuccessTipsViewWidth (120.0)
#define kPLVLSSwitchSuccessTipsViewHeight (25.0)

@interface PLVLSSwitchSuccessTipsView : UIView

@property (nonatomic, assign, readonly) BOOL showing;

- (void)showAtView:(UIView *)superView aboveSubview:(UIView *)aboveView;

- (void)dismiss;

@end

NS_ASSUME_NONNULL_END