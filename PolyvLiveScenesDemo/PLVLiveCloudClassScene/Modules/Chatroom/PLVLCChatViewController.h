//
//  PLVLCChatViewController.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLCLikeButtonView.h"
#import "PLVLCRedpackButtonView.h"
#import "PLVLCCardPushButtonView.h"
#import "PLVLCLotteryWidgetView.h"

@class PLVChatModel;

NS_ASSUME_NONNULL_BEGIN

@class PLVLCChatroomPlaybackViewModel, PLVLCChatViewController;

@protocol PLVLCChatViewControllerDelegate <NSObject>

- (void)plvLCChatViewController:(PLVLCChatViewController *)chatVC needOpenInteract:(NSDictionary *)dict;

/// 在点击超过500字符的长文本消息时会执行此回调
/// @param model 需要展示完整文本的长文本消息数据模型
- (void)plvLCChatViewController:(PLVLCChatViewController *)chatVC alertLongContentMessage:(PLVChatModel *)model;

/// 点击互动模块控件的回调
/// @param event 互动模块事件
- (void)plvLCChatViewController:(PLVLCChatViewController *)chatVC emitInteractEvent:(NSString *)event;

/// 抽奖挂件显示状态改变的的回调
/// @param show 当前的显示状态
- (void)plvLCChatViewController:(PLVLCChatViewController *)chatVC lotteryWidgetShowStatusChanged:(BOOL)show;

@end

extern NSString *PLVLCChatroomOpenBulletinNotification;

extern NSString *PLVLCChatroomOpenInteractAppNotification;

extern NSString *PLVLCChatroomOpenRewardViewNotification;

@interface PLVLCChatViewController : UIViewController

@property (nonatomic, weak) id<PLVLCChatViewControllerDelegate> delegate;

@property (nonatomic, weak) UIViewController *liveRoom;

/// 点赞悬浮按钮（含点赞数、点赞动画）自定义视图
@property (nonatomic, strong) PLVLCLikeButtonView *likeButtonView;

/// 倒计时红包悬浮按钮
@property (nonatomic, strong) PLVLCRedpackButtonView *redpackButtonView;

/// 卡片推送悬浮按钮 自定义视图
@property (nonatomic, strong) PLVLCCardPushButtonView *cardPushButtonView;

/// 红包挂件视图
@property (nonatomic, strong) PLVLCLotteryWidgetView *lotteryWidgetView;

/// 初始化方法
- (instancetype)initWithLiveRoom:(UIViewController *)liveRoom;

/// 调整右侧悬浮按钮位置
- (void)resumeFloatingButtonViewLayout;

/// 主页创建/更新回放viewModel之后，通过菜单视图，通知聊天室视图
- (void)updatePlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)playbackViewModel;

- (void)leaveLiveRoom;

/// 开启卡片推送
/// @param start 是否是开启推送 YES开启 NO取消
/// @param dict 卡片推送信息
/// @param callback 开始卡片推送的回调，是否显示挂件（YES 显示，NO不显示）
- (void)startCardPush:(BOOL)start cardPushInfo:(NSDictionary *)dict callback:(void (^)(BOOL show))callback;

/// 更新抽奖插件信息
/// @param dataArray 抽奖插件数据
- (void)updateLotteryWidgetViewInfo:(NSArray *)dataArray;

@end

NS_ASSUME_NONNULL_END
