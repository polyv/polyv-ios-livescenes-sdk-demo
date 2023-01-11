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

/// 获取提醒历史聊天消息成功时触发
/// @param modelArray 聊天消息队列
/// @param noMore 是否还有更多历史消息，YES表示已加载完
- (void)chatroomPresenter_loadRemindHistorySuccess:(NSArray <PLVChatModel *> *)modelArray noMore:(BOOL)noMore;

/// 获取提醒历史聊天消息失败时触发
- (void)chatroomPresenter_loadRemindHistoryFailure;

/// 获取图片表情数据
- (void)chatroomPresenter_loadImageEmotionsSuccess;

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
/// @param warning 后端返回的提示文本
/// @param word 触发的严禁词, work为nil时表示消息中的严禁词已用**代替后成功发出
- (void)chatroomPresenter_receiveWarning:(NSString *)warning prohibitWord:(NSString * _Nullable )word;

/// 发送图片违规时触发
/// @param msgId 后端返回的消息ID
- (void)chatroomPresenter_receiveImageWarningWithMsgId:(NSString *)msgId;

/// 发送图片失败时触发
/// @param message 图片消息数据模型
- (void)chatroomPresenter_sendImageMessageFaild:(PLVImageMessage *)message;

/// 发送图片成功时（收到socket消息回调）触发
/// @param message 图片消息数据模型(已更新了数据模型中的msgId字段)
- (void)chatroomPresenter_sendImageMessageSuccess:(PLVImageMessage *)message;

/// 聊天室开启、关闭状态变化回调
/// @param closeRoom 聊天室当前状态，YES：开启，允许全体人员发言；
///                               NO：关闭，只允许特殊身份（譬如讲师）发言
- (void)chatroomPresenter_didChangeCloseRoom:(BOOL) closeRoom;

/// 聊天室登录达到并发限制
- (void)chatroomPresenter_didLoginRestrict;

/// 聊天室专注模式开启、关闭
/// @param focusMode 聊天室专注当前状态，YES：只允许特殊身份（譬如讲师）发言；
///                               NO：关闭，允许全体人员发言
- (void)chatroomPresenter_didChangeFocusMode:(BOOL)focusMode;

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

/// 当前登陆用户是否是特殊身份（譬如讲师），为YES时字段closeRoom、banned永远为NO
@property (nonatomic, assign, readonly) BOOL specialRole;

/// 图片表情数组
@property (nonatomic, strong, readonly) NSArray *imageEmotionArray;

/// 初始化方法
/// @param count 每次调用接口获取的聊天消息条数，不得小于1
- (instancetype)initWithLoadingHistoryCount:(NSUInteger)count;

/// 初始化方法 2
/// @param count 每次调用接口获取的聊天消息条数，不得小于1
/// @param allow 是否允许使用分房间功能
- (instancetype)initWithLoadingHistoryCount:(NSUInteger)count childRoomAllow:(BOOL)allow;

/// 互动学堂专用方法，配置课程码/课节ID
/// @param courseCode 课程码
/// @param lessonId 课节ID
- (void)setCourseCode:(NSString *)courseCode lessonId:(NSString *)lessonId;

/// 属性配置完毕，登录socket
- (void)login;

/// socket 连接成功之后发送 login 消息进行登录
/// @note 这个方法仅适用于 socket 连接且登录成功之后调用
- (void)emitLoginEvent;

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

/// 发送回复消息
/// @param content 消息文本
/// @param replyChatModel 被回复消息模型（该字段为nil时发送文本消息），仅在属性specialRole为YES时生效
/// @return 消息数据模型, 发送失败时，返回nil
- (PLVChatModel * _Nullable)sendSpeakMessage:(NSString *)content
                              replyChatModel:(PLVChatModel * _Nullable)replyChatModel;

/// 发送 提醒 文本消息
/// @param content 消息文本
/// @return 消息数据模型, 发送失败时，返回nil
- (PLVChatModel * _Nullable)sendRemindSpeakMessage:(NSString *)content;

/// 发送 提醒 图片消息
/// @param image 图片
/// @return 消息数据模型（开始上传图片即返回消息数据模型，否则返回nil）
- (PLVChatModel * _Nullable)sendRemindImageMessage:(UIImage *)image;

/// 发送图片消息
/// @param image 图片
/// @return 消息数据模型（开始上传图片即返回消息数据模型，否则返回nil）
- (PLVChatModel * _Nullable)sendImageMessage:(UIImage *)image;

/// 发送图片表情消息
/// @param imageId 图片id
/// @param imageUrl 发送图片的URL
/// @return 消息数据模型, 发送失败时，返回nil
- (PLVChatModel * _Nullable)sendImageEmotionId:(NSString *)imageId
                                      imageUrl:(NSString *)imageUrl;

/// 发送自定义消息
/// @param event 自定义消息event字段
/// @param data 自定义消息data字段
/// @param tip 自定义消息tip字段
/// @param emitMode 自定义消息emitMode字段（0-发送给所有人，1-发送给所有人除了自己，2-只发送给自己）
/// @return 消息数据模型, 发送失败时，返回nil
- (PLVChatModel * _Nullable)sendCustomMessageWithEvent:(NSString *)event
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

/// 加载提醒消息历史记录
- (void)loadRemindHistory;

///加载图片表情
- (void)loadImageEmotions;

/// 切换聊天室房间时调用，用于清空原有的聊天消息，并重新加载历史聊天消息
- (void)changeRoom;

/// 消息overLen字段为YES时，使用该方法获取超长消息
/// @return YES-消息发出；NO-消息未发出，即callback不会执行
- (BOOL)overLengthSpeakMessageWithMsgId:(NSString *)msgId callback:(void (^)(NSString * _Nullable content))callback;

@end

NS_ASSUME_NONNULL_END
