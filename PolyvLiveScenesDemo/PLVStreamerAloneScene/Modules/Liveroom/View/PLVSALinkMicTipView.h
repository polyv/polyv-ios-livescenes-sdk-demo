//
//  PLVSALinkMicTipView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/9.
//  Copyright © 2021 PLV. All rights reserved.
// 有新用户正在申请连麦提示视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVSALinkMicTipView;
@protocol PLVSALinkMicTipViewDelegate <NSObject>

- (void)linkMicTipViewDidTapCheckButton:(PLVSALinkMicTipView *)linkMicTipView;

@end

// 连麦提示视图
@interface PLVSALinkMicTipView : UIView

@property (nonatomic, weak)id<PLVSALinkMicTipViewDelegate> delegate;

/// 显示有用户申请连麦
/// @note 10秒后自动隐藏
- (void)show;

/// 显示有用户申请连麦
/// @note 0.3秒渐隐动画
- (void)dissmiss;

@end

NS_ASSUME_NONNULL_END
