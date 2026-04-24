//
//  PLVLCWelcomeView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/10/12.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCWelcomeView : UIView

- (void)showWelcomeWithNickName:(NSString *)nickName;

- (void)showWelcomeWithMessage:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
