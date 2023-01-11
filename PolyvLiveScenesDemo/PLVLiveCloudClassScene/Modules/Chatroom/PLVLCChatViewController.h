//
//  PLVLCChatViewController.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLCLikeButtonView.h"
#import "PLVLCCardPushButtonView.h"

@class PLVChatModel;

NS_ASSUME_NONNULL_BEGIN

@class PLVLCChatroomPlaybackViewModel, PLVLCChatViewController;

@protocol PLVLCChatViewControllerDelegate <NSObject>

- (void)plvLCChatViewController:(PLVLCChatViewController *)chatVC needOpenInteract:(NSDictionary *)dict;

/// 在点击超过500字符的长文本消息时会执行此回调
/// @param model 需要展示完整文本的长文本消息数据模型
- (void)plvLCChatViewController:(PLVLCChatViewController *)chatVC alertLongContentMessage:(PLVChatModel *)model;

@end

extern NSString *PLVLCChatroomOpenBulletinNotification;

extern NSString *PLVLCChatroomOpenInteractAppNotification;

extern NSString *PLVLCChatroomOpenRewardViewNotification;

@interface PLVLCChatViewController : UIViewController

@property (nonatomic, weak) id<PLVLCChatViewControllerDelegate> delegate;

@property (nonatomic, weak) UIViewController *liveRoom;

/// 点赞悬浮按钮（含点赞数、点赞动画）自定义视图
@property (nonatomic, strong) PLVLCLikeButtonView *likeButtonView;

/// 卡片推送悬浮按钮 自定义视图
@property (nonatomic, strong) PLVLCCardPushButtonView *cardPushButtonView;

/// 初始化方法
- (instancetype)initWithLiveRoom:(UIViewController *)liveRoom;

- (void)resumeLikeButtonViewLayout;

- (void)resumeCardPushButtonViewLayout;

/// 主页创建/更新回放viewModel之后，通过菜单视图，通知聊天室视图
- (void)updatePlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)playbackViewModel;

- (void)leaveLiveRoom;

@end

NS_ASSUME_NONNULL_END
