//
//  PLVECChatroomViewModel.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/26.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVChatroomPresenter.h"

NS_ASSUME_NONNULL_BEGIN

/*
 PLVECChatroomViewModel的协议
 */
@protocol PLVECChatroomViewModelProtocol <NSObject>

@optional

/// 返回本地发送的公聊消息（包含禁言的情况）
/// 用于刷新列表、滚动列表到底部
- (void)chatroomManager_didSendMessage;

/// 返回socket接收到的公聊消息
/// 用于刷新列表、显示新消息提示
- (void)chatroomManager_didReceiveMessages;

/// socket通知有消息被删除（1条或多条）
/// 用于刷新列表
- (void)chatroomManager_didMessageDeleted;

/// 获取历史聊天记录成功时触发
/// 用于刷新列表，停止【下拉加载更多】控件的动画
/// @param noMore 是否还有更多历史消息，YES表示已加载完，此时可隐藏【下拉加载更多】控件
/// @param first  是否是初次加载历史消息，初次加载需滚动列表到底部
- (void)chatroomManager_loadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first;

/// 获取历史聊天消息失败时触发
/// 用于停止【下拉加载更多】控件的动画
- (void)chatroomManager_loadHistoryFailure;

/// 当前时间段内如果有用户登录聊天室（包括自己），间隔2秒触发一次
/// @param userArray 登录聊天室的用户数组，如果为nil，表示当前时间段内当前用户有登录事件
- (void)chatroomManager_loginUsers:(NSArray <PLVChatUser *> * _Nullable )userArray;

@end

/*
 scene层聊天室核心类，负责scene层聊天室视图与common层聊天室核心类的通信：
 1. 对view层提供发送消息的接口
 2. 管理common层返回的消息模型
 3. 在view层需要刷新UI、更新列表数据时，通过回调通知view层
 */
@interface PLVECChatroomViewModel : NSObject

@property (nonatomic, weak) id<PLVECChatroomViewModelProtocol> delegate;

/// 聊天室common层presenter，一个scene层只能初始化一个presenter对象
@property (nonatomic, strong, readonly) PLVChatroomPresenter *presenter;

/// 全部消息数组
@property (nonatomic, strong, readonly) NSMutableArray <PLVChatModel *> *chatArray;

#pragma mark API

/// 单例方法
+ (instancetype)sharedViewModel;

/// 使用新的直播间数据启动聊天室管理器
- (void)setup;

/// 退出前调用，用于资源释放、状态位清零
- (void)clear;

/// 加载历史聊天记录，每次加载条数10条
- (void)loadHistory;

/// 发送文本消息
/// @param content 消息文本
/// @return YES表示数据将有更新，可等待收到回调后刷新列表；NO表示socket未登录或房间关闭，可进行toast提示
- (BOOL)sendSpeakMessage:(NSString *)content;

/// 发送礼物消息
/// @param data 礼物消息data字段
/// @param tip 礼物消息tip字段
/// @return 是否成功发送的布尔值
- (BOOL)sendGiftMessageWithData:(NSDictionary *)data tip:(NSString *)tip;

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

/// 发送点赞消息
/// 点赞数的实时更新通过监听roomData的likeCount获得
- (void)sendLike;

@end

NS_ASSUME_NONNULL_END
