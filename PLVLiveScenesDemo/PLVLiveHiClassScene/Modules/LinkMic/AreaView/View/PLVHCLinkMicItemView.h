//
//  PLVHCLinkMicItemView.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/11/16.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLinkMicOnlineUser, PLVHCLinkMicWindowCupView;

@interface PLVHCLinkMicItemView : UIView

#pragma mark UI
@property (nonatomic, strong, readonly) UIView * contentBackgroudView; // 内容背景视图 (负责承载 [RTC画面]，直接决定了’内容画面‘在Cell中的布局、图层、圆角)
@property (nonatomic, strong, readonly) CAGradientLayer *bottomShadowLayer;//底部阴影
@property (nonatomic, strong, readonly) PLVHCLinkMicWindowCupView *cupView; //奖杯
@property (nonatomic, strong, readonly) UILabel *maxNicknameLabel; //大昵称
@property (nonatomic, strong, readonly) UILabel *minNicknameLabel; //小昵称
@property (nonatomic, strong, readonly) UIImageView *micImageView; //麦克风
@property (nonatomic, strong, readonly) UIImageView *brushImageView; //画笔
@property (nonatomic, strong, readonly) UIImageView *handUpImageView; //举手

#pragma mark 数据
@property (nonatomic, weak, readonly) PLVLinkMicOnlineUser *userModel;

/// 更新用户信息
- (void)updateOnlineUser:(PLVLinkMicOnlineUser *)userModel;

@end

NS_ASSUME_NONNULL_END
