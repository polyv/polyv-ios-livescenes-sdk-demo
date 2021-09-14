//
//  PLVLSChatroomViewModel.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/2/3.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVChatroomPresenter.h"

NS_ASSUME_NONNULL_BEGIN

/*
 PLVLSChatroomViewModel的协议
 @note 在主线程回调
 */
@protocol PLVLSChatroomViewModelProtocol <NSObject>

@optional

/// 返回本地发送的公聊消息（包含禁言的情况）
/// 用于刷新列表、滚动列表到底部
- (void)chatroomViewModel_didSendMessage;

/// 返回socket接收到的公聊消息
/// 用于刷新列表、显示新消息提示
- (void)chatroomViewModel_didReceiveMessages;

/// socket通知有消息被删除（1条或多条）
/// 用于刷新列表
- (void)chatroomViewModel_didMessageDeleted;

/// 获取历史聊天记录成功时触发
/// 用于刷新列表，停止【下拉加载更多】控件的动画
/// @param noMore 是否还有更多历史消息，YES表示已加载完，此时可隐藏【下拉加载更多】控件
/// @param first  是否是初次加载历史消息，初次加载需滚动列表到底部
- (void)chatroomViewModel_loadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first;

/// 获取历史聊天消息失败时触发
/// 用于停止【下拉加载更多】控件的动画
- (void)chatroomViewModel_loadHistoryFailure;

/// 获取图片表情消息列表
- (void)chatroomViewModel_loadEmotionSuccess;

@end

/*
 scene层聊天室核心类，负责scene层聊天室视图与common层聊天室核心类的通信：
 1. 对view层提供发送消息的接口
 2. 管理common层返回的消息模型
 3. 在view层需要刷新UI、更新列表数据时，通过回调通知view层
 */
@interface PLVLSChatroomViewModel : NSObject

@property (nonatomic, weak) id<PLVLSChatroomViewModelProtocol> delegate;

/// 聊天室common层presenter，一个scene层只能初始化一个presenter对象
@property (nonatomic, strong, readonly) PLVChatroomPresenter *presenter;

/// 全部消息数组
@property (nonatomic, strong, readonly) NSMutableArray <PLVChatModel *> *chatArray;

/// 图片表情数组
@property (nonatomic, strong, readonly) NSArray *imageEmotionArray;

#pragma mark API

/// 单例方法
+ (instancetype)sharedViewModel;

/// 使用新的直播间数据启动聊天室管理器
- (void)setup;

/// 退出前调用，用于资源释放、状态位清零
- (void)clear;

/// 加载历史聊天记录，每次加载条数10条
- (void)loadHistory;

///加载图片表情资源列表
- (void)loadImageEmotions;

/// 发送文本消息
/// @param content 消息文本
/// @param replyChatModel 回复消息模型（非回复消息该字段为nil）
/// @return YES表示数据将有更新，可等待收到回调后刷新列表；NO表示socket未登录或房间关闭，可进行toast提示
- (BOOL)sendSpeakMessage:(NSString *)content replyChatModel:(PLVChatModel * _Nullable)replyChatModel;

/// 发送图片消息
/// @param image 图片
/// @return YES表示数据将有更新，可等待收到回调后刷新列表；NO表示socket未登录或房间关闭，可进行toast提示
- (BOOL)sendImageMessage:(UIImage *)image;

/// 发送图片表情消息
/// @param imageId 图片表情id
/// @param imageUrl 图片表情地址
- (BOOL)sendImageEmotionMessage:(NSString *)imageId
                       imageUrl:(NSString *)imageUrl;

@end

NS_ASSUME_NONNULL_END
