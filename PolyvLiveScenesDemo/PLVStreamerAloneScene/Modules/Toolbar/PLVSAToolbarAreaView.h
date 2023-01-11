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

/// 连麦布局切换按钮回调
- (void)toolbarAreaViewDidLinkMicLayoutSwitchButton:(PLVSAToolbarAreaView *)toolbarAreaView layoutSwitchButtonSelected:(BOOL)selected;

/// 点击连麦按钮回调
- (void)toolbarAreaViewDidTapLinkMicButton:(PLVSAToolbarAreaView *)toolbarAreaView linkMicButtonSelected:(BOOL)selected;

/// 点击人员按钮回调
- (void)toolbarAreaViewDidTapMemberButton:(PLVSAToolbarAreaView *)toolbarAreaView;;

/// 点击商品库按钮回调
- (void)toolbarAreaViewDidTapCommodityButton:(PLVSAToolbarAreaView *)toolbarAreaView;

/// 点击更多按钮回调
- (void)toolbarAreaViewDidTapMoreButton:(PLVSAToolbarAreaView *)toolbarAreaView;

/// 点击视频连麦按钮
- (void)toolbarAreaViewDidTapVideoLinkMicButton:(PLVSAToolbarAreaView *)toolbarAreaView linkMicButtonSelected:(BOOL)selected;

/// 点击语音连麦按钮
- (void)toolbarAreaViewDidTapAudioLinkMicButton:(PLVSAToolbarAreaView *)toolbarAreaView linkMicButtonSelected:(BOOL)selected;

@end

@interface PLVSAToolbarAreaView : UIView

@property (nonatomic, weak)id<PLVSAToolbarAreaViewDelegate> delegate;

/// 当前 频道连麦功能是否开启（YES:连麦功能已开启 NO:连麦功能已关闭）
/// 同时更改连麦按钮状态，enbale设为YES
@property (nonatomic, assign) BOOL channelLinkMicOpen;

/// 人员按钮右上角红点显示或隐藏
/// @param show YES: 显示；NO：隐藏
- (void)showMemberBadge:(BOOL)show;

/// 更新状态栏连麦用户数量
/// @note 更新用户数量时，会更新连麦布局切换按钮显示状态 （大于1时显示）
/// @param onlineUserCount 连麦的用户数量
- (void)updateOnlineUserCount:(NSInteger)onlineUserCount;

@end

NS_ASSUME_NONNULL_END
