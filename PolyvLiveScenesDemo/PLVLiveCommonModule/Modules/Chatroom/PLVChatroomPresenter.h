//
//  PLVChatroomPresenter.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/25.
//  Copyright © 2020 PLV. All rights reserved.
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

/// 获取图片表情数据
/// @param dictArray 图片表情列表
- (void)chatroomPresenter_loadImageEmotionsSuccess:(NSArray <NSDictionary *> *)dictArray;

/// 获取图片表情数据失败时触发
- (void)chatroomPresenter_loadImageEmotionsFailure;

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

/// 发送消息包含严禁词时触发
/// @param message 后端返回的message提示文本
/// @param word 触发的严禁词
- (void)chatroomPresenter_receiveWarning:(NSString *)message prohibitWord:(NSString *)word;

/// 发送图片违规时触发
/// @param msgId 后端返回的消息ID
- (void)chatroomPresenter_receiveImageWarningWithMsgId:(NSString *)msgId;

/// 发送图片失败时触发
/// @param message 图片消息数据模型
- (void)chatroomPresenter_sendImageMessageFaild:(PLVImageMessage *)message;

/// 发送图片成功时（收到socket消息回调）触发
/// @param message 图片消息数据模型(已更新了数据模型中的msgId字段)
- (void)chatroomPresenter_sendImageMessageSuccess:(PLVImageMessage *)message;

/// 发送图片表情状态更新（收到socket消息回调）触发
/// @param message 图片表情消息数据模型(更新了数据模型中的msgId字段和发送状态字段sendState)
- (void)chatroomPresenter_sendImageEmotionMessageStatus:(PLVImageEmotionMessage *)message;
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

/// 当前登陆用户是否是特殊身份（譬如讲师），默认为NO，为YES时字段closeRoom、banned永远为NO
@property (nonatomic, assign) BOOL specialRole;

/// 聊天室是否被关闭，默认为NO
@property (nonatomic, assign, readonly) BOOL closeRoom;

/// 初始化方法
/// @param count 每次调用接口获取的聊天消息条数，不得小于1
/// @param allow 是否允许使用分房间功能
- (instancetype)initWithLoadingHistoryCount:(NSUInteger)count childRoomAllow:(BOOL)allow;

/// 销毁方法
/// 退出前调用，用于资源释放、状态位清零
- (void)destroy;

/// 发送私聊提问消息
/// @param content 消息文本
/// @return 消息数据模型, 发送失败时，返回nil
- (PLVChatModel * _Nullable)sendQuesstionMessage:(NSString *)content;

/// 发送文本消息
/// @param content 消息文本
/// @return 消息数据模型, 发送失败时，返回nil
- (PLVChatModel * _Nullable)sendSpeakMessage:(NSString *)content;

/// 发送文本消息（包括回复类型的文本消息）
/// @param content 消息文本
/// @param replyChatModel 被回复消息模型（非回复消息该字段为nil），仅在属性specialRole为YES时生效
/// @return 消息数据模型, 发送失败时，返回nil
- (PLVChatModel * _Nullable)sendSpeakMessage:(NSString *)content
                              replyChatModel:(PLVChatModel * _Nullable)replyChatModel;

/// 发送文本消息（包括回复类型的文本消息）
/// @param content 消息文本
/// @param replyChatModel 被回复消息模型（非回复消息该字段为nil），仅在属性specialRole为YES时生效
/// @return 消息数据模型（开始进入socket发送环节即返回消息数据模型，否则返回nil，发送成功与否关注属性msgState的变化）
- (PLVChatModel * _Nullable)chatModelWithMsgStateForSendSpeakMessage:(NSString *)content
                                                      replyChatModel:(PLVChatModel * _Nullable)replyChatModel;


/// 发送图片消息
/// @param image 图片
/// @return 消息数据模型（开始上传图片即返回消息数据模型，否则返回nil）
- (PLVChatModel * _Nullable)sendImageMessage:(UIImage *)image;

/// 发送图片表情消息
/// @param imageId 图片id
/// @return 消息数据模型, 发送失败时，返回nil
- (PLVChatModel * _Nullable)sendImageEmotionId:(NSString *)imageId;


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

/// 发送全体禁言、解禁消息，，讲师端专用接口
/// @param closeRoom YES:全体禁言；NO：全体解禁
- (BOOL)sendCloseRoom:(BOOL)closeRoom;

/// 本地生成一条教师消息，作为私聊窗口的第一条消息
/// 生成后的消息数据模型通过回调 '-chatroomPresenter_didReceiveAnswerChatModel:' 返回
- (void)createAnswerChatModel;

/// 发送点赞消息
- (void)sendLike;

/// 加载历史聊天记录
- (void)loadHistory;

///加载图片表情
- (void)loadImageEmotions;

@end

NS_ASSUME_NONNULL_END
