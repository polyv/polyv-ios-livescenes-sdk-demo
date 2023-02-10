//
//  PLVECChatBaseCell.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/1/3.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVChatModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVECChatBaseCell : UITableViewCell

#pragma mark 数据
@property (nonatomic, strong) PLVChatModel *model;
@property (nonatomic, assign) CGFloat cellWidth;

#pragma mark UI
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *chatLabel;
@property (nonatomic, assign) BOOL quoteReplyEnabled; // 观众支持引用回复功能
@property (nonatomic, assign) BOOL allowCopy; // 支持显示复制菜单按钮
@property (nonatomic, assign) BOOL allowReply; // 支持显示回复菜单按钮
@property (nonatomic, copy) void(^ _Nullable replyHandler)(PLVChatModel *model); // 点击【回复】按钮触发

/// 更新数据模型，子类需覆写
- (void)updateWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth;

/// 获取cell高度，子类需覆写
+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth;

/// 判断model是否为有效类型，子类需覆写
+ (BOOL)isModelValid:(PLVChatModel *)model;

@end

NS_ASSUME_NONNULL_END
