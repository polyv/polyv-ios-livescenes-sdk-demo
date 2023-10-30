//
//  PLVLCTuwenViewController.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLCTuwenDelegate <NSObject>

- (void)clickTuwenImage:(BOOL)showImage;

@end

@interface PLVLCTuwenViewController : UIViewController

@property (nonatomic, weak) id<PLVLCTuwenDelegate> delegate;

/// 直播状态改变时调用
- (void)updateLiveStatusIsLive:(BOOL)isLive;

/// 更新用户信息
/// 在用户的信息改变后进行通知
- (void)updateUserInfo;

@end

NS_ASSUME_NONNULL_END
