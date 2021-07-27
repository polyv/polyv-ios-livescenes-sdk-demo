//
//  PLVSAToolbarAreaView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
// 工具类视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVSAToolbarAreaView;
@protocol PLVSAToolbarAreaViewDelegate <NSObject>

/// 点击连麦按钮回调
- (void)toolbarAreaViewDidTapLinkMicButton:(PLVSAToolbarAreaView *)toolbarAreaView linkMicButtonSelected:(BOOL)selected;

/// 点击人员按钮回调
- (void)toolbarAreaViewDidTapMemberButton:(PLVSAToolbarAreaView *)toolbarAreaView;;

/// 点击更多按钮回调
- (void)toolbarAreaViewDidTapMoreButton:(PLVSAToolbarAreaView *)toolbarAreaView;


@end

@interface PLVSAToolbarAreaView : UIView

@property (nonatomic, weak)id<PLVSAToolbarAreaViewDelegate> delegate;

/// 当前 频道连麦功能是否开启（YES:连麦功能已开启 NO:连麦功能已关闭）
/// 同时更改连麦按钮状态，enbale设为YES
@property (nonatomic, assign) BOOL channelLinkMicOpen;

/// 人员按钮右上角红点显示或隐藏
/// @param show YES: 显示；NO：隐藏
- (void)showMemberBadge:(BOOL)show;

/// 网络状态，发送消息前判断网络是否异常
/// @note 内部将会把 netState 传给 sendMessageView
@property (nonatomic, assign) NSInteger netState;

@end

NS_ASSUME_NONNULL_END
