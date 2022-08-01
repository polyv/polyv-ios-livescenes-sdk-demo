//
//  PLVLCChatroomViewModel.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/26.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVChatroomPresenter.h"

NS_ASSUME_NONNULL_BEGIN

/// PLVLCChatroomViewModel的协议
 /// @note 允许设置多个监听者
@protocol PLVLCChatroomViewModelProtocol <NSObject>

@optional

#pragma mark 私聊

/// 本地发送了新的私聊消息
/// 用于刷新列表
- (void)chatroomManager_didSendQuestionMessage;

/// 通知socket接收到新的私聊（教师回答）消息，每次1条
/// 用于刷新列表、显示新消息提示
- (void)chatroomManager_didReceiveAnswerMessage;

#pragma mark 公聊

/// 返回本地发送的公聊消息（包含禁言的情况）
/// 用于刷新列表、发送弹幕
/// @param model 消息模型，不为空
- (void)chatroomManager_didSendMessage:(PLVChatModel *)model;

/// 返回socket接收到的公聊消息
/// 用于刷新列表、发送弹幕、显示新消息提示
/// @param modelArray 消息队列，不为空
- (void)chatroomManager_didReceiveMessages:(NSArray <PLVChatModel *> *)modelArray;

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

/// 如果4秒内有登录聊天室的用户（包括自己），间隔4秒触发一次
/// 用于显示‘欢迎登录用户横幅’
/// @param userArray 4秒内登录聊天室的用户数组，如果为nil，表示当前时间段内当前用户有登录事件
- (void)chatroomManager_loginUsers:(NSArray <PLVChatUser *> * _Nullable )userArray;

/// 上报管理员发布的消息文本，间隔8秒触发一次
/// 用于显示‘管理员消息跑马灯’
/// @param content 管理员消息文本
- (void)chatroomManager_managerMessage:(NSString * )content;

/// 上报需插入弹幕的文本，间隔1秒触发一次
/// 用于显示‘播放器弹幕’
/// @param content 弹幕文本
- (void)chatroomManager_danmu:(NSString * )content;

/// 获取图片表情资源列表成功
/// 用于表情面板加载图片表情
/// @param dictArray 图片表情数据
- (void)chatroomManager_loadImageEmotionSuccess:(NSArray <NSDictionary *> *)dictArray;

/// 获取图片表情资源列表失败
/// 用于提示用户‘图片表情加载失败’
- (void)chatroomManager_loadImageEmotionFailure;

/// 打赏成功时触发
- (void)chatroomManager_rewardSuccess:(NSDictionary *)modelDict;

/// 获取礼物打赏开关成功时触发
/// @param enable 打赏开关
/// @param payWay 打赏方式，CASH为现金打赏，POINT为积分打赏
/// @param modelArray 打赏数据模型
/// @param pointUnit 打赏数据单位
- (void)chatroomManager_loadRewardEnable:(BOOL)enable payWay:(NSString * _Nullable)payWay rewardModelArray:(NSArray * _Nullable)modelArray pointUnit:(NSString * _Nullable)pointUnit;

/// 聊天室登录达到并发限制时触发
- (void)chatroomManager_didLoginRestrict;

/// 收到卡片推送消息后的回调
/// @param start 是否开启卡片推送(YES 开启 NO 取消)
/// @param pushDict 卡片推送的信息
- (void)chatroomManager_startCardPush:(BOOL)start pushInfo:(NSDictionary *)pushDict;

/// 聊天室是否开启关闭时触发
/// @param closeRoom 是否关闭聊天室，YES-关闭，NO-开启
- (void)chatroomManager_closeRoom:(BOOL)closeRoom;

/// 聊天室专注模式是否开启关闭时触发
/// @param focusMode 是否关闭聊天室，YES-关闭，NO-开启
- (void)chatroomManager_focusMode:(BOOL)focusMode;

@end

/*
 scene层聊天室核心类，负责scene层聊天室视图与common层聊天室核心类的通信：
 1. 对view层提供发送消息的接口
 2. 管理common层返回的消息模型
 3. 在view层需要刷新UI、更新列表数据时，通过回调通知view层
 */
@interface PLVLCChatroomViewModel : NSObject

/// 聊天室common层presenter，一个scene层只能初始化一个presenter对象
@property (nonatomic, strong, readonly) PLVChatroomPresenter *presenter;

#pragma mark 数据数组
/// 是否打开【只看讲师】开关
@property (nonatomic, assign) BOOL onlyTeacher;
/// 公聊消息数组
@property (nonatomic, strong, readonly) NSMutableArray <PLVChatModel *> *chatArray;
/// 私聊消息数组
@property (nonatomic, strong, readonly) NSMutableArray <PLVChatModel *> *privateChatArray;
/// 是否打开【礼物打赏】开关
@property (nonatomic, assign, readonly) BOOL enableReward;
/// 是否屏蔽礼物打赏特效 默认不屏蔽
@property (nonatomic, assign) BOOL hideRewardDisplay;
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

/// 加载表情图片
- (void)loadImageEmotions;

/// 发送私聊提问消息
/// @param content 消息文本
/// @return YES表示数据将有更新，可等待收到回调后刷新列表；NO表示socket未登录或房间关闭，可进行toast提示
- (BOOL)sendQuesstionMessage:(NSString *)content;

/// 发送文本消息
/// @param content 消息文本
/// @return YES表示数据将有更新，可等待收到回调后刷新列表；NO表示socket未登录或房间关闭，可进行toast提示
- (BOOL)sendSpeakMessage:(NSString *)content;

/// 发送图片消息
/// @param image 图片
/// @return YES表示数据将有更新，可等待收到回调后刷新列表；NO表示socket未登录或房间关闭，可进行toast提示
- (BOOL)sendImageMessage:(UIImage *)image;

/// 发送图片表情消息
/// @param imageId 图片id
/// @return YES表示数据将有更新，可等待收到回调后刷新列表；NO表示socket未登录或房间关闭，可进行toast提示
- (BOOL)sendImageEmotionId:(NSString *)imageId
                  imageUrl:(NSString *)imageUrl;

/// 发送点赞消息
/// 点赞数的实时更新通过监听roomData的likeCount获得
- (void)sendLike;

/// 本地生成一条教师消息，作为私聊窗口的第一条消息
/// 生成后的消息数据模型通过回调 '-chatroomPresenter_didReceiveAnswerChatModel:' 返回
- (void)createAnswerChatModel;

/// 增加PLVLCChatroomViewModelProtocol协议的监听者
/// @param delegate 待增加的监听者
/// @param delegateQueue 执行回调的队列
- (void)addDelegate:(id<PLVLCChatroomViewModelProtocol>)delegate delegateQueue:(dispatch_queue_t)delegateQueue;

/// 移除PLVLCChatroomViewModelProtocol协议的监听者
/// @param delegate 待移除的监听者
- (void)removeDelegate:(id<PLVLCChatroomViewModelProtocol>)delegate;

/// 移除PLVLCChatroomViewModelProtocol协议的所有监听者
- (void)removeAllDelegates;

@end

NS_ASSUME_NONNULL_END
