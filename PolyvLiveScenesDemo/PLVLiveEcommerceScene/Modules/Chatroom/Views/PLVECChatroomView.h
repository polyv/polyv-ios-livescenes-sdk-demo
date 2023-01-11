//
//  PLVChatroomView.h
//  PLVLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

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

@end

/// 聊天室视图
@interface PLVECChatroomView : UIView

@property (nonatomic, weak) id<PLVECChatroomViewDelegate> delegate;

/// 用于聊天重放时，更新聊天回放viewModel的视频时长
- (void)updateDuration:(NSTimeInterval)duration;

/// 用于聊天重放时，回放视频被seek时通知聊天回放viewModel
- (void)playbackTimeChanged;

@end

NS_ASSUME_NONNULL_END
