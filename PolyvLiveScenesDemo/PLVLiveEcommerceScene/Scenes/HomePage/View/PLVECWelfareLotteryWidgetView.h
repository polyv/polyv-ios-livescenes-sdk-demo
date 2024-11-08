//
//  PLVECWelfareLotteryWidgetView.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/10/22.
//  Copyright © 2024 PLV. All rights reserved.
//
// 直播带货福利抽奖挂件

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVECWelfareLotteryWidgetView;
@protocol PLVECWelfareLotteryWidgetViewDelegate <NSObject>

// 点击抽奖挂件的回调
/// @param welfareLotteryWidgetView 直播带货抽奖挂件
- (void)welfareLotteryWidgetViewDidClickAction:(PLVECWelfareLotteryWidgetView *)welfareLotteryWidgetView;

/// 抽奖挂件显示状态改变的的回调
/// @param welfareLotteryWidgetView 直播带货抽奖挂件
/// @param show 当前的显示状态
- (void)welfareLotteryWidgetView:(PLVECWelfareLotteryWidgetView *)welfareLotteryWidgetView showStatusChanged:(BOOL)show;

/// 抽奖挂件的 PopupView 显示的的回调
/// @param welfareLotteryWidgetView 直播带货抽奖挂件
- (void)welfareLotteryWidgetViewPopupViewDidShow:(PLVECWelfareLotteryWidgetView *)welfareLotteryWidgetView;


@end

@interface PLVECWelfareLotteryWidgetView : UIView

@property (nonatomic, weak) id<PLVECWelfareLotteryWidgetViewDelegate> delegate;

@property (nonatomic, assign, readonly) CGSize widgetSize;

/// 更新抽奖挂件数据
///  @param dict 抽奖数据
- (void)updateWelfareLotteryWidgetInfo:(NSDictionary *)dict;

- (void)hideWidgetView;

/// 隐藏 Popup 视图
- (void)hidePopupView;


@end

NS_ASSUME_NONNULL_END
