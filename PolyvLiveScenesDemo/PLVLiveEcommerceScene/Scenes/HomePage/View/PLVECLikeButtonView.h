//
//  PLVECLikeButtonView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/1/21.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#define PLVECLikeButtonViewWidth (50.0)
#define PLVECLikeButtonViewHeight (42.0 + 3.0 + 12.0)

NS_ASSUME_NONNULL_BEGIN

@interface PLVECLikeButtonView : UIView

@property (nonatomic, assign) NSUInteger likeCount;

@property (nonatomic, copy) void(^didTapLikeButton)(void);

@property (nonatomic, assign) BOOL animationLeftShift;

/// 显示点赞动画
- (void)showLikeAnimation;

/// 启动计时器， 每10s随机显示一些点赞动画
- (void)startTimer;

/// 取消计时器
- (void)invalidTimer;

/// 设置点赞动画
/// @param likeCount 当前点赞数量
- (void)setupLikeAnimationWithCount:(NSInteger)likeCount;

@end

NS_ASSUME_NONNULL_END
