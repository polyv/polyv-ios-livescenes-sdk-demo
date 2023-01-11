//
//  PLVLCLandscapeMessagePopupView.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/11/17.
//  Copyright © 2022 PLV. All rights reserved.
//
// 云课堂横屏超长文本消息弹窗

#import <UIKit/UIKit.h>
#import "PLVChatModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLCLandscapeMessagePopupViewDelegate;

@interface PLVLCLandscapeMessagePopupView : UIView

@property (nonatomic, weak) id<PLVLCLandscapeMessagePopupViewDelegate> delegate;

// 弹窗文本
@property (nonatomic, copy, readonly) NSString *content;

- (instancetype)initWithChatModel:(PLVChatModel *)model;

// 显示弹窗
- (void)showOnView:(UIView *)superView;

// 移走弹窗
- (void)hideWithAnimation:(BOOL)animation;

@end

@protocol PLVLCLandscapeMessagePopupViewDelegate <NSObject>

@optional

// 弹窗【关闭】按钮被点击
- (void)landscapeMessagePopupViewWillClose:(PLVLCLandscapeMessagePopupView *)popupView;

// 弹窗【复制】按钮被点击
- (void)landscapeMessagePopupViewWillCopy:(PLVLCLandscapeMessagePopupView *)popupView;

@end

NS_ASSUME_NONNULL_END
