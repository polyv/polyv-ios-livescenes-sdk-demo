//
//  PLVHCChatroomMenuPopup.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/8/2.
//  Copyright © 2021 polyv. All rights reserved.
// 聊天室-长按弹出复制、回复菜单弹层

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCChatroomMenuPopup : UIView

/// 是否开启长按显示复制功能
@property (nonatomic, assign) BOOL allowCopy;

/// 是否开启长按显示回复功能
@property (nonatomic, assign) BOOL allowReply;

/// 隐藏视图回调
@property (nonatomic, copy) void(^ _Nullable dismissHandler)(void);

/// 复制按钮点击回调
@property (nonatomic, copy) void(^ _Nullable copyButtonHandler)(void);

/// 回复按钮点击回调
@property (nonatomic, copy) void(^ _Nullable replyButtonHandler)(void);

- (instancetype)initWithMenuFrame:(CGRect)frame buttonFrame:(CGRect)buttonFrame;

/// 弹出弹层
/// @param parentView 展示弹层的父视图，弹层会插入到父视图的最顶上
- (void)showInView:(UIView *)parentView;

/// 隐藏聊天室视图
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
