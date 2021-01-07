//
//  PLVLCChatViewController.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLCLikeButtonView.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *PLVLCChatroomOpenBulletinNotification;

@interface PLVLCChatViewController : UIViewController

@property (nonatomic, weak) UIViewController *liveRoom;

/// 点赞悬浮按钮（含点赞数、点赞动画）自定义视图
@property (nonatomic, strong) PLVLCLikeButtonView *likeButtonView;

/// 初始化方法
- (instancetype)initWithLiveRoom:(UIViewController *)liveRoom;

- (void)resumeLikeButtonViewLayout;

@end

NS_ASSUME_NONNULL_END
