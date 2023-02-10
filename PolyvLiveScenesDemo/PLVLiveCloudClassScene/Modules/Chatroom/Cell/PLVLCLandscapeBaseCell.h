//
//  PLVLCLandscapeBaseCell.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/12/29.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVChatModel.h"

NS_ASSUME_NONNULL_BEGIN

/*
 云课堂场景，横屏聊天室消息 cell 父类
 */
@interface PLVLCLandscapeBaseCell : UITableViewCell

#pragma mark 数据
/// 消息数据模型
@property (nonatomic, strong) PLVChatModel *model;

#pragma mark UI
/// 背景气泡
@property (nonatomic, strong) UIView *bubbleView;
/// cell宽度
@property (nonatomic, assign) CGFloat cellWidth;
/// 支持显示复制菜单按钮
@property (nonatomic, assign) BOOL allowCopy;
/// 支持显示回复菜单按钮
@property (nonatomic, assign) BOOL allowReply;
/// 点击 回复按钮 触发
@property (nonatomic, copy) void(^ _Nullable replyHandler)(PLVChatModel *model);

#pragma mark 子类必须override的三个API

/// 设置消息数据模型，cell宽度
- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth;

/// 根据消息数据模型、cell宽度计算cell高度
+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth;

/// 判断model是否为有效类型，子类可覆写
+ (BOOL)isModelValid:(PLVChatModel *)model;

@end

NS_ASSUME_NONNULL_END
