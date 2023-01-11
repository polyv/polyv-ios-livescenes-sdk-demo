//
//  PLVLCMessagePopupView.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/11/16.
//  Copyright © 2022 PLV. All rights reserved.
//
// 云课堂竖屏超长文本消息弹窗

#import <UIKit/UIKit.h>
#import "PLVChatModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLCMessagePopupViewDelegate;

@interface PLVLCMessagePopupView : UIView

@property (nonatomic, weak) id<PLVLCMessagePopupViewDelegate> delegate;

// 弹窗文本
@property (nonatomic, copy, readonly) NSString *content;

- (instancetype)initWithChatModel:(PLVChatModel *)model;

// 设置弹窗高度
- (void)setContainerHeight:(CGFloat)height;

// 显示弹窗
- (void)showOnView:(UIView *)superView;

// 移走弹窗
- (void)hideWithAnimation:(BOOL)animation;

@end

@protocol PLVLCMessagePopupViewDelegate <NSObject>

@optional

// 弹窗【关闭】按钮被点击
- (void)messagePopupViewWillClose:(PLVLCMessagePopupView *)popupView;

// 弹窗【复制】按钮被点击
- (void)messagePopupViewWillCopy:(PLVLCMessagePopupView *)popupView;

@end

NS_ASSUME_NONNULL_END
