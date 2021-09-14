//
//  PLVSABaseMessageCell.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVChatUser.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVChatModel;

/// 手机开播-纯视频 聊天室 base cell
@interface PLVSABaseMessageCell : UITableViewCell
// 数据

/// 消息数据模型
@property (nonatomic, strong) PLVChatModel *model;

@property (nonatomic, assign) BOOL allowCopy;

@property (nonatomic, assign) BOOL allowReply;

// 是否已对消息状态进行KVO，默认为NO
@property (nonatomic, assign) BOOL observingMsgState;

// 回调

/// 点击 回复按钮 触发
@property (nonatomic, copy) void(^ _Nullable replyHandler)(PLVChatModel *model);
/// 违禁词自动 隐藏时 触发
@property (nonatomic, copy) void(^ _Nullable dismissHandler)(void);

// 设置身份标签

/// 返回是否显示身份标签
/// @note YES: 显示；NO: 隐藏
/// @param user 用户模型
+ (BOOL)showActorLabelWithUser:(PLVChatUser *)user;

/// 身份标签图片
/// @param user 用户模型
+ (UIImage*) actorImageWithUser:(PLVChatUser *)user;

@end

NS_ASSUME_NONNULL_END
