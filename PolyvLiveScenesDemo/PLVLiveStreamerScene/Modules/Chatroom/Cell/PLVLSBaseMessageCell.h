//
//  PLVLSBaseMessageCell.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/4/14.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVChatModel;

@interface PLVLSBaseMessageCell : UITableViewCell

@property (nonatomic, strong) PLVChatModel *model; /// 消息数据模型

@property (nonatomic, assign) BOOL allowCopy;

@property (nonatomic, assign) BOOL allowReply;

@property (nonatomic, assign) BOOL allowPinMessage; /// 是否允许评论上墙

@property (nonatomic, copy) void(^ _Nullable replyHandler)(PLVChatModel *model);
/// 违禁词手动触发显示时 触发
@property (nonatomic, copy) void(^ _Nullable prohibitWordShowHandler)(void);
/// 违禁词隐藏时 触发
@property (nonatomic, copy) void(^ _Nullable prohibitWordDismissHandler)(void);
/// 点击 上墙按钮 触发
@property (nonatomic, copy) void(^ _Nullable pinMessageHandler)(PLVChatModel *model);

@end

NS_ASSUME_NONNULL_END
