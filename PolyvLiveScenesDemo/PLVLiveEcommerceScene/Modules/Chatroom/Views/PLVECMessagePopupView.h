//
//  PLVECMessagePopupView.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/11/16.
//  Copyright © 2022 PLV. All rights reserved.
//
// 直播带货竖屏超长文本消息弹窗

#import <UIKit/UIKit.h>
#import "PLVChatModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVECMessagePopupViewDelegate;

@interface PLVECMessagePopupView : UIView

@property (nonatomic, weak) id<PLVECMessagePopupViewDelegate> delegate;

// 弹窗文本
@property (nonatomic, copy, readonly) NSString *content;

- (instancetype)initWithChatModel:(PLVChatModel *)model;

// 显示弹窗
- (void)showOnView:(UIView *)superView;

// 移走弹窗
- (void)hideWithAnimation:(BOOL)animation;

@end

@protocol PLVECMessagePopupViewDelegate <NSObject>

@optional

// 弹窗【关闭】按钮被点击
- (void)messagePopupViewWillClose:(PLVECMessagePopupView *)popupView;

// 弹窗【复制】按钮被点击
- (void)messagePopupViewWillCopy:(PLVECMessagePopupView *)popupView;

@end

NS_ASSUME_NONNULL_END
