//
//  PLVLCLandscapeLocalSystemMessageCell.h
//  PolyvLiveScenesDemo
//
//  Copyright © 2026 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVChatModel;

NS_ASSUME_NONNULL_BEGIN

/*
 云课堂场景，横屏聊天室本地系统提示 cell
 用于严禁词禁发等本地系统消息展示
 */
@interface PLVLCLandscapeLocalSystemMessageCell : UITableViewCell

/// 使用消息模型更新 cell 内容
/// @param model 聊天消息模型（message 为 PLVLocalSystemMessage）
/// @param cellWidth cell 宽度
- (void)updateWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth;

/// 计算 cell 高度
/// @param model 聊天消息模型
/// @param cellWidth cell 宽度
+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth;

/// 判断模型是否为本 cell 可展示的本地系统消息
/// @param model 聊天消息模型
+ (BOOL)isModelValid:(PLVChatModel *)model;

@end

NS_ASSUME_NONNULL_END
