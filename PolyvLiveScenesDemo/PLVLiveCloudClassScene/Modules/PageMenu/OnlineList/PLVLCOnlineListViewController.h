//
//  PLVLCOnlineListViewController.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/9/3.
//  Copyright © 2024 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVChatUser.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLCOnlineListViewControllerDelegate;

@interface PLVLCOnlineListViewController : UIViewController

@property (nonatomic, weak) id <PLVLCOnlineListViewControllerDelegate>delegate;

- (void)updateOnlineList:(NSArray <PLVChatUser *>*)onlineList;

@end

@protocol PLVLCOnlineListViewControllerDelegate <NSObject>

- (void)plvLCOnlineListViewControllerWannaShowRule:(PLVLCOnlineListViewController *)viewController;

- (void)plvLCOnlineListViewControllerNeedUpdateOnlineList:(PLVLCOnlineListViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
