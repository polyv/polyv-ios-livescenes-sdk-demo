//
//  PLVLCMessageCell.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/1.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVChatModel.h"
#import "PLVChatUser.h"

NS_ASSUME_NONNULL_BEGIN

/*
 云课堂场景，竖屏聊天室消息 cell 父类
 支持文本消息、图片消息、引用消息和私聊消息
 */
@interface PLVLCMessageCell : UITableViewCell

#pragma mark 数据
/// 消息数据模型
@property (nonatomic, strong) PLVChatModel *model;
/// cell宽度
@property (nonatomic, assign) CGFloat cellWidth;
/// 登录用户的聊天室userId
@property (nonatomic, strong) NSString *loginUserId;

#pragma mark UI
/// 发出消息用户头像
@property (nonatomic, strong) UIImageView *avatarImageView;
/// 发出消息用户昵称
@property (nonatomic, strong) UILabel *nickLabel;

#pragma mark API

/// 设置消息数据模型，cell宽度
- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth;

/// 根据消息数据模型、cell宽度计算cell高度
+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth;

/// 判断model是否为有效类型，子类可覆写
+ (BOOL)isModelValid:(PLVChatModel *)model;

/// 根据size获取气泡图层
+ (CAShapeLayer *)bubbleLayerWithSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
