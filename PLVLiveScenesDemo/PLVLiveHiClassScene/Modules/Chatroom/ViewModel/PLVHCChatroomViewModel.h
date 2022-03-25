//
//  PLVHCChatroomViewModel.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/25.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVChatroomPresenter.h"

NS_ASSUME_NONNULL_BEGIN
@class PLVHCChatroomViewModel;

/*
 PLVHCChatroomViewModel的协议
 @note 在主线程回调
 */
@protocol PLVHCChatroomViewModelDelegate <NSObject>

@optional

/// 返回本地发送的公聊消息（包含自己被禁言后发送消息的情况（此消息只显示在本地））
/// 用于刷新列表、滚动列表到底部
/// @note 在主线程触发
- (void)chatroomViewModelDidSendMessage:(PLVHCChatroomViewModel *)viewModel;

/// 返回本地重发的公聊消息（包含自己被禁言后发送消息的情况（此消息只显示在本地））
/// 用于刷新列表、滚动列表到底部
/// @note 在主线程触发
- (void)chatroomViewModelDidResendMessage:(PLVHCChatroomViewModel *)viewModel;

/// 发送了严禁消息（图片、文字）
/// 用于刷新列表、滚动列表到底部
/// @note 在主线程触发
- (void)chatroomViewModelDidSendProhibitMessgae:(PLVHCChatroomViewModel *)viewModel;

/// 返回socket接收到的公聊消息
/// 用于刷新列表、显示新消息提示
/// @note 在主线程触发
- (void)chatroomViewModelDidReceiveMessages:(PLVHCChatroomViewModel *)viewModel;

/// 返回socket接收到的聊天室关闭、开启消息
/// 用于刷新列表、显示新消息提示
/// @note 在主线程触发
- (void)chatroomViewModelDidReceiveCloseRoomMessage:(PLVHCChatroomViewModel *)viewModel;

/// socket通知有消息被删除（1条或多条）
/// 用于刷新列表
/// @note 在主线程触发
- (void)chatroomViewModelDidMessageDeleted:(PLVHCChatroomViewModel *)viewModel;

/// 获取历史聊天记录成功时触发
/// 用于刷新列表，停止【下拉加载更多】控件的动画
/// @note 在主线程触发
/// @param noMore 是否还有更多历史消息，YES表示已加载完，此时可隐藏【下拉加载更多】控件
/// @param first  是否是初次加载历史消息，初次加载需滚动列表到底部
- (void)chatroomViewModel:(PLVHCChatroomViewModel *)viewModel loadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first;

/// 获取历史聊天消息失败时触发
/// 用于停止【下拉加载更多】控件的动画
/// @note 在主线程触发
- (void)chatroomViewModelLoadHistoryFailure:(PLVHCChatroomViewModel *)viewModel;

@end

/*
 scene层聊天室核心类，负责scene层聊天室视图与common层聊天室核心类的通信：
 1. 对view层提供发送消息的接口
 2. 管理common层返回的消息模型
 3. 在view层需要刷新UI、更新列表数据时，通过回调通知view层
 */
@interface PLVHCChatroomViewModel : NSObject

/// PLVHCChatroomViewModel代理
@property (nonatomic, weak) id<PLVHCChatroomViewModelDelegate> delegate;

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
/// @param replyChatModel 回复消息模型（非回复消息该字段为nil）
/// @return YES表示数据将有更新，可等待收到回调后刷新列表；NO表示socket未登录或房间关闭，可进行toast提示
- (BOOL)sendSpeakMessage:(NSString *)content replyChatModel:(PLVChatModel * _Nullable)replyChatModel;

/// 发送图片消息
/// @param image 图片
/// @return YES表示数据将有更新，可等待收到回调后刷新列表；NO表示socket未登录或房间关闭，可进行toast提示
- (BOOL)sendImageMessage:(UIImage *)image;

/// 重新发送文本消息
/// @param model 消息模型
/// @param replyChatModel 回复消息模型（非回复消息该字段为nil）
/// @return YES表示数据将有更新，可等待收到回调后刷新列表；NO表示socket未登录或房间关闭，可进行toast提示
- (BOOL)resendSpeakMessage:(PLVChatModel *)model replyChatModel:(PLVChatModel * _Nullable)replyChatModel;

/// 重新发送图片消息
/// @param model 消息模型
/// @return YES表示数据将有更新，可等待收到回调后刷新列表；NO表示socket未登录或房间关闭，可进行toast提示
- (BOOL)resendImageMessage:(PLVChatModel *)model;

/// 切换聊天室房间时调用，用于清空原有的聊天消息，并重新加载历史聊天消息
- (void)changeRoom;

@end

NS_ASSUME_NONNULL_END

