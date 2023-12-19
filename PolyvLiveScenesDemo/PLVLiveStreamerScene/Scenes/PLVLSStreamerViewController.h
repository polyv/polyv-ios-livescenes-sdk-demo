//
//  PLVLSStreamerViewController.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/2/23.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVLSStreamerViewController;

@protocol PLVLSStreamerViewControllerDelegate <NSObject>

/// 嘉宾需要退出重进 回调
- (void)lsStreamerViewControllerGuestNeedReLogin:(PLVLSStreamerViewController *)streamerViewController;

@end

@interface PLVLSStreamerViewController : UIViewController

/// 代理
@property (nonatomic, weak)id<PLVLSStreamerViewControllerDelegate> delegate;

/// 登出页面
- (void)logout;

@end

NS_ASSUME_NONNULL_END
