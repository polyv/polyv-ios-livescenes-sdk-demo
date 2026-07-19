//
//  PLVECLuckyBagWidgetView.h
//  PolyvLiveScenesDemo
//
//  Created by Codex on 2026/07/08.
//  Copyright © 2026 PLV. All rights reserved.
//
// 直播带货福袋挂件

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVECLuckyBagWidgetView;
@protocol PLVECLuckyBagWidgetViewDelegate <NSObject>

/// 点击福袋挂件的回调
/// @param luckyBagWidgetView 直播带货福袋挂件
- (void)luckyBagWidgetViewDidClickAction:(PLVECLuckyBagWidgetView *)luckyBagWidgetView;

/// 福袋挂件显示状态改变的的回调
/// @param luckyBagWidgetView 直播带货福袋挂件
/// @param show 当前的显示状态
- (void)luckyBagWidgetView:(PLVECLuckyBagWidgetView *)luckyBagWidgetView showStatusChanged:(BOOL)show;

/// 福袋挂件的 PopupView 显示的的回调
/// @param luckyBagWidgetView 直播带货福袋挂件
- (void)luckyBagWidgetViewPopupViewDidShow:(PLVECLuckyBagWidgetView *)luckyBagWidgetView;

@end

@interface PLVECLuckyBagWidgetView : UIView

@property (nonatomic, weak) id<PLVECLuckyBagWidgetViewDelegate> delegate;

@property (nonatomic, assign, readonly) CGSize widgetSize;

@property (nonatomic, copy, readonly, nullable) NSString *activityId;

/// 更新福袋挂件数据
///  @param dict 福袋数据
- (void)updateLuckyBagWidgetInfo:(NSDictionary *)dict;

- (void)hideWidgetView;

/// 隐藏 Popup 视图
- (void)hidePopupView;

@end

NS_ASSUME_NONNULL_END
