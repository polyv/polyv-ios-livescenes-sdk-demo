//
//  PLVLCLuckyBagWidgetView.h
//  PolyvLiveScenesDemo
//
//  Created by Codex on 2026/07/08.
//  Copyright © 2026 PLV. All rights reserved.
//
// 云课堂福袋挂件

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLCLuckyBagWidgetView;
@protocol PLVLCLuckyBagWidgetViewDelegate <NSObject>

/// 点击福袋挂件的回调
/// @param luckyBagWidgetView 云课堂福袋挂件
- (void)luckyBagWidgetViewDidClickAction:(PLVLCLuckyBagWidgetView *)luckyBagWidgetView;

/// 福袋挂件显示状态改变的的回调
/// @param luckyBagWidgetView 云课堂福袋挂件
/// @param show 当前的显示状态
- (void)luckyBagWidgetView:(PLVLCLuckyBagWidgetView *)luckyBagWidgetView showStatusChanged:(BOOL)show;

/// 福袋挂件的 PopupView 显示的的回调
/// @param luckyBagWidgetView 云课堂福袋挂件
- (void)luckyBagWidgetViewPopupViewDidShow:(PLVLCLuckyBagWidgetView *)luckyBagWidgetView;

@end

@interface PLVLCLuckyBagWidgetView : UIView

@property (nonatomic, weak) id<PLVLCLuckyBagWidgetViewDelegate> delegate;

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
