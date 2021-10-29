//
//  PLVHCBaseMessageCell.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/25.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVChatUser.h"

NS_ASSUME_NONNULL_BEGIN
@class PLVChatModel;

/// 互动学堂 聊天室 base cell
@interface PLVHCBaseMessageCell : UITableViewCell

#pragma mark 数据
/// 消息数据模型
@property (nonatomic, strong) PLVChatModel *model;

/// 是否开启长按显示复制功能
/// @note 需要在子类中覆盖实现方法：copyAction:
@property (nonatomic, assign) BOOL allowCopy;

/// 是否开启长按显示回复功能
@property (nonatomic, assign) BOOL allowReply;

/// 是否已对消息状态进行KVO，默认为NO
@property (nonatomic, assign) BOOL observingMsgState;

/// 触发长按显示'复制、回复菜单弹层' 的父视图，默认不触发长按事件，弱引用
@property (nonatomic, weak)UIView *menuSuperView;

#pragma mark 回调

/// 点击 回复按钮 触发
@property (nonatomic, copy) void(^ _Nullable replyHandler)(PLVChatModel *model);

/// 违禁词自动 隐藏时 触发
@property (nonatomic, copy) void(^ _Nullable prohibitWordTipdismissHandler)(void);

/// 点击复制回调，子类覆盖实现
- (void)copyAction;

/// 显示复制、回复菜单弹窗
- (void)showMenuPopup;

#pragma mark 设置身份标签

/// 返回是否显示身份标签
/// @note YES: 显示；NO: 隐藏
/// @param user 用户模型
+ (BOOL)showActorLabelWithUser:(PLVChatUser *)user;

/// 身份标签图片
/// @param user 用户模型
+ (UIImage*) actorImageWithUser:(PLVChatUser *)user;

/// 判断当前用户Id是否为自己
/// @note YES: 自己；NO: 其他人
/// @param userId 用户Id
+ (BOOL)isLoginUser:(NSString *)userId;

#pragma mark - [ 需子类覆盖实现方法 ]

#pragma mark 判断model是否为有效类型

/// 判断model是否为有效类型，由子类需覆盖重写，未覆盖重时写返回NO
/// @param model 数据模型
+ (BOOL)isModelValid:(PLVChatModel *)model;

#pragma mark cellId

/// 根据用户模型返回CellId，由子类覆盖重写，未覆盖重写时返回nil
/// @note user.userId不存在时返回nil;
/// user.userId为自己、其他人时分别返回一种cellId（由子类实现）
/// @param user 用户模型
+ (NSString * _Nullable)reuseIdentifierWithUser:(PLVChatUser *)user;


@end

NS_ASSUME_NONNULL_END
