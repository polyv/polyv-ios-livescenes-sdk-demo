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

NS_ASSUME_NONNULL_BEGIN

@class PLVLCChatroomPlaybackViewModel, PLVLCChatViewController;

@protocol PLVLCChatViewControllerDelegate <NSObject>

- (void)plvLCChatViewController:(PLVLCChatViewController *)chatVC needOpenInteract:(NSDictionary *)dict;

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

/// 切换聊天室关闭状态
- (void)changeCloseRoomStatus:(BOOL)closeRoom;

/// 切换聊天室专注模式状态
- (void)changeFocusMode:(BOOL)focusMode;

- (void)updatePlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)playbackViewModel;

- (void)leaveLiveRoom;

@end

NS_ASSUME_NONNULL_END
