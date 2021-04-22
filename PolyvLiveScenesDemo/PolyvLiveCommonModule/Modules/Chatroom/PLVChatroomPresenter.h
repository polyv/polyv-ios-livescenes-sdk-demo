//
//  PLVChatroomPresenter.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/25.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PLVChatModel.h"

NS_ASSUME_NONNULL_BEGIN

/* PLVChatroomPresenter的协议 */
@protocol PLVChatroomPresenterProtocol <NSObject>

@optional

/// 获取历史聊天消息成功时触发
/// @param modelArray 聊天消息队列
/// @param noMore 是否还有更多历史消息，YES表示已加载完
- (void)chatroomPresenter_loadHistorySuccess:(NSArray <PLVChatModel *> *)modelArray noMore:(BOOL)noMore;

/// 获取历史聊天消息失败时触发
- (void)chatroomPresenter_loadHistoryFailure;

/// 返回socket接收到的消息
/// @param modelArray 消息队列，不为空
- (void)chatroomPresenter_didReceiveChatModels:(NSArray <PLVChatModel *> *)modelArray;

/// 返回socket接收到的教师回答消息
/// @param model 教师回答消息
- (void)chatroomPresenter_didReceiveAnswerChatModel:(PLVChatModel *)model;

/// socket通知已删除某条消息
/// @param msgId 被删除消息ID
- (void)chatroomPresenter_didMessageDeleted:(NSString *)msgId;

/// socket通知所有聊天消息被清空
- (void)chatroomPresenter_didAllMessageDeleted;

@end

/*
 负责聊天室socket消息的接收与发送
 1. 对直播间数据的在线人数、观看热度、点赞数进行实时更新
 2. 提供发送各类消息的API，并把消息封装成数据模型返回
 3. 加载历史聊天记录，并把加载结果与数据封装成数据模型通过回调通知scene层
 4. 监听socket关于聊天消息的接收与删除，并把新消息封装成数据模型，然后通过回调通知scene层
 */
@interface PLVChatroomPresenter : NSObject

@property (nonatomic, weak) id<PLVChatroomPresenterProtocol> delegate;

/// 初始化方法
/// @param count 每次调用接口获取的聊天消息条数，不得小于1
/// @param allow 是否允许使用分房间功能
- (instancetype)initWithLoadingHistoryCount:(NSUInteger)count childRoomAllow:(BOOL)allow;

/// 销毁方法
/// 退出前调用，用于资源释放、状态位清零
- (void)destroy;

/// 发送私聊提问消息
/// @param content 消息文本
/// @return 消息数据模型
- (PLVChatModel * _Nullable)sendQuesstionMessage:(NSString *)content;

/// 发送文本消息
/// @param content 消息文本
/// @return 消息数据模型
- (PLVChatModel * _Nullable)sendSpeakMessage:(NSString *)content;

/// 发送图片消息
/// @param image 图片
/// @return 消息数据模型
- (PLVChatModel * _Nullable)sendImageMessage:(UIImage *)image;

/// 发送自定义消息
/// @param event 自定义消息event字段
/// @param data 自定义消息data字段
/// @param tip 自定义消息tip字段
/// @param emitMode 自定义消息emitMode字段
/// @return 是否成功发送的布尔值
- (BOOL)sendCustomMessageWithEvent:(NSString *)event
                              data:(NSDictionary *)data
                               tip:(NSString * _Nullable)tip
                          emitMode:(int)emitMode;

/// 本地生成一条教师消息，作为私聊窗口的第一条消息
/// 生成后的消息数据模型通过回调 '-chatroomPresenter_didReceiveAnswerChatModel:' 返回
- (void)createAnswerChatModel;

/// 发送点赞消息
- (void)sendLike;

/// 加载历史聊天记录
- (void)loadHistory;

@end

NS_ASSUME_NONNULL_END
