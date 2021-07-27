//
//  PLVSAMemberPopup.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/8.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVChatUser;

NS_ASSUME_NONNULL_BEGIN

@interface PLVSAMemberPopup : UIView

@property (nonatomic, copy) void(^didDismissBlock)(void);
@property (nonatomic, copy) void(^bandUserBlock)(NSString *userId, NSString *userName, BOOL banned);
@property (nonatomic, copy) void(^kickUserBlock)(NSString *userId, NSString *userName);

- (instancetype)initWithChatUser:(PLVChatUser *)chatUser centerYPoint:(CGFloat)centerY;

- (void)showAtView:(UIView *)superView;

@end

NS_ASSUME_NONNULL_END
