//
//  PLVSAStreamerViewController.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVSAStreamerViewController;

@protocol PLVSAStreamerViewControllerDelegate <NSObject>

/// 点击 退出按钮 退出直播时 回调
- (void)streamerViewControllerLogout:(PLVSAStreamerViewController *)stramerViewController;

/// 嘉宾需要退出重进 回调
- (void)saStreamerViewControllerGuestNeedReLogin:(PLVSAStreamerViewController *)streamerViewController;

@end

@interface PLVSAStreamerViewController : UIViewController

/// 代理
@property (nonatomic, weak)id<PLVSAStreamerViewControllerDelegate> delegate;

/// 嘉宾登出页面
- (void)guestLogout;

@end

NS_ASSUME_NONNULL_END
