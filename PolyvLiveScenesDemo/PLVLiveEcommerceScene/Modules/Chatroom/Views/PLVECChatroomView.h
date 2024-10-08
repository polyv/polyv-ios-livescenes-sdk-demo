//
//  PLVChatroomView.h
//  PLVLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVECChatroomView, PLVChatModel;

@protocol PLVECChatroomViewDelegate <NSObject>

/// 加载打赏信息时触发
/// @param rewardEnable 是否支持打赏
/// @param payWay 打赏方式，CASH为现金打赏，POINT为积分打赏
/// @param modelArray 打赏数据模型数组
/// @param pointUnit 打赏单位
- (void)chatroomView_loadRewardEnable:(BOOL)rewardEnable payWay:(NSString * _Nullable)payWay rewardModelArray:(NSArray *_Nullable)modelArray pointUnit:(NSString * _Nullable)pointUnit;

/// 聊天重放功能开启时定时触发，获取当前回放视频播放节点
- (NSTimeInterval)chatroomView_currentPlaybackTime;

/// 聊天室登录达到并发限制时触发
- (void)chatroomView_didLoginRestrict;

/// 在点击超过500字符的长文本消息时会执行此回调
/// @param model 需要展示完整文本的长文本消息数据模型
- (void)chatroomView_alertLongContentMessage:(PLVChatModel *)model;

/// 点击领取红包时触发
/// @param state 红包消息状态
/// @param model 对应消息数据模型
- (void)chatroomView_checkRedpackStateResult:(PLVRedpackState)state chatModel:(PLVChatModel *)model;

/// 显示倒计时红包挂件
/// @param type 红包类型
/// @param delayTime 倒计时时间，单位秒
- (void)chatroomView_showDelayRedpackWithType:(PLVRedpackMessageType)type delayTime:(NSInteger)delayTime;

/// 隐藏倒计时红包挂件
- (void)chatroomView_hideDelayRedpack;

/// 收到评论上墙信息的回调
/// @param model 消息模型
/// @param show 是否需要显示评论上墙视图
- (void)chatroomView_receiveSpeakTopMessageChatModel:(PLVChatModel *)model showPinMsgView:(BOOL)show;

@end

/// 聊天室视图
@interface PLVECChatroomView : UIView

@property (nonatomic, weak) id<PLVECChatroomViewDelegate> delegate;

/// 用于聊天重放时，更新聊天回放viewModel的视频时长
- (void)updateDuration:(NSTimeInterval)duration;

/// 用于聊天重放时，回放视频被seek时通知聊天回放viewModel
- (void)playbackTimeChanged;

/// 用于聊天重放时，回放视频信息更新时通知聊天回放viewModel
- (void)playbackVideoInfoDidUpdated;

@end

NS_ASSUME_NONNULL_END
