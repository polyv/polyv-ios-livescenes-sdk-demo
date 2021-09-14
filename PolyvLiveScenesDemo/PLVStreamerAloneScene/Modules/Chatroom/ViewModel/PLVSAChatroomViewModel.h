//
//  PLVSAChatroomViewModel.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVChatroomPresenter.h"

NS_ASSUME_NONNULL_BEGIN
@class PLVSAChatroomViewModel;

/*
 PLVSAChatroomViewModel的协议
 @note 在主线程回调
 */
@protocol PLVSAChatroomViewModelDelegate <NSObject>

@optional

/// 返回本地发送的公聊消息（包含禁言的情况）
/// 用于刷新列表、滚动列表到底部
/// @note 在主线程触发
- (void)chatroomViewModelDidSendMessage:(PLVSAChatroomViewModel *)viewModel;

/// 返回socket接收到的公聊消息
/// 用于刷新列表、显示新消息提示
/// @note 在主线程触发
- (void)chatroomViewModelDidReceiveMessages:(PLVSAChatroomViewModel *)viewModel;

/// socket通知有消息被删除（1条或多条）
/// 用于刷新列表
/// @note 在主线程触发
- (void)chatroomViewModelDidMessageDeleted:(PLVSAChatroomViewModel *)viewModel;

/// 获取历史聊天记录成功时触发
/// 用于刷新列表，停止【下拉加载更多】控件的动画
/// @note 在主线程触发
/// @param noMore 是否还有更多历史消息，YES表示已加载完，此时可隐藏【下拉加载更多】控件
/// @param first  是否是初次加载历史消息，初次加载需滚动列表到底部
- (void)chatroomViewModel:(PLVSAChatroomViewModel *)viewModel loadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first;

/// 获取历史聊天消息失败时触发
/// 用于停止【下拉加载更多】控件的动画
/// @note 在主线程触发
- (void)chatroomViewModelLoadHistoryFailure:(PLVSAChatroomViewModel *)viewModel;

/// 获取图片表情列表数据成功
- (void)chatroomViewModel_loadEmotionSuccess;

/// 当前时间段内如果有用户登录聊天室（包括自己），间隔2秒触发一次
/// @note 在主线程触发
/// @param userArray 登录聊天室的用户数组，如果为nil，表示当前时间段内当前用户有登录事件
- (void)chatroomViewModel:(PLVSAChatroomViewModel *)viewModel loginUsers:(NSArray <PLVChatUser *> * _Nullable )userArray;

/// 赠送礼物 触发
/// 显示赠送礼物动画
/// @note 在主线程触发
- (void)chatroomViewModel:(PLVSAChatroomViewModel *)viewModel
             giftNickName:(NSString *)nickName
             giftImageUrl:(NSString *)giftImageUrl
                  giftNum:(NSInteger )giftNum
              giftContent:(NSString *)giftContent;

/// 现在打赏 触发
/// 显示赠送礼物动画
/// @note 在主线程触发
- (void)chatroomViewModel:(PLVSAChatroomViewModel *)viewModel giftNickName:(NSString *)nickName cashGiftContent:(NSString *)cashGiftContent;

@end

/*
 scene层聊天室核心类，负责scene层聊天室视图与common层聊天室核心类的通信：
 1. 对view层提供发送消息的接口
 2. 管理common层返回的消息模型
 3. 在view层需要刷新UI、更新列表数据时，通过回调通知view层
 */
@interface PLVSAChatroomViewModel : NSObject

@property (nonatomic, weak) id<PLVSAChatroomViewModelDelegate> delegate;

/// 聊天室common层presenter，一个scene层只能初始化一个presenter对象
@property (nonatomic, strong, readonly) PLVChatroomPresenter *presenter;

/// 全部消息数组
@property (nonatomic, strong, readonly) NSMutableArray <PLVChatModel *> *chatArray;

/// 图片表情数组
@property (nonatomic, strong, readonly) NSArray *imageEmotionArray;

/// 只读属性，当前是否开启【全体禁言】
@property (nonatomic, assign, readonly) BOOL closeRoom;

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
/// @param imageUrl 图片表情的url
/// @return YES表示数据将有更新，可等待收到回调后刷新列表；NO表示socket未登录或房间关闭，可进行toast提示
- (BOOL)sendImageEmotionMessage:(NSString *)imageId
                       imageUrl:(NSString *)imageUrl;

/// 重新发送文本消息
/// @param content 消息文本
/// @param replyChatModel 回复消息模型（非回复消息该字段为nil）
/// @return YES表示数据将有更新，可等待收到回调后刷新列表；NO表示socket未登录或房间关闭，可进行toast提示
- (BOOL)resendSpeakMessage:(NSString *)content replyChatModel:(PLVChatModel * _Nullable)replyChatModel;

/// 重新发送图片消息
/// @param image 图片
/// @param imageId 图片Id，用于删除已展示到列表的消息
/// @return YES表示数据将有更新，可等待收到回调后刷新列表；NO表示socket未登录或房间关闭，可进行toast提示
- (BOOL)resendImageMessage:(UIImage *)image imageId:(NSString *)imageId;

/// 重新发送图片表情消息
/// @param imageId 图片id
/// @param imageUrl 图片imageUrl
/// @return YES表示数据将有更新，可等待收到回调后刷新列表；NO表示socket未登录或房间关闭，可进行toast提示
- (BOOL)resendImageEmotionMessage:(NSString *)imageId imageUrl:(NSString *)imageUrl;

/// 全体禁言
/// @param closeRoom YES:全体禁言；NO：全体解禁
- (BOOL)sendCloseRoom:(BOOL)closeRoom;

@end

NS_ASSUME_NONNULL_END
