//
//  PLVECLotteryWidgetView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/7/10.
//  Copyright © 2023 PLV. All rights reserved.
//
// 直播带货抽奖挂件

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVECLotteryWidgetView;
@protocol PLVECLotteryWidgetViewDelegate <NSObject>

/// 点击抽奖挂件的回调
/// @param lotteryWidgetView 直播带货抽奖挂件
/// @param eventName 云课堂抽奖挂件事件名
- (void)lotteryWidgetViewDidClickAction:(PLVECLotteryWidgetView *)lotteryWidgetView eventName:(NSString *)eventName;

/// 抽奖挂件显示状态改变的的回调
/// @param lotteryWidgetView 云课堂抽奖挂件
/// @param show 当前的显示状态
- (void)lotteryWidgetView:(PLVECLotteryWidgetView *)lotteryWidgetView showStatusChanged:(BOOL)show;

/// 抽奖挂件的 PopupView 显示的的回调
/// @param lotteryWidgetView 云课堂抽奖挂件
- (void)lotteryWidgetViewPopupViewDidShow:(PLVECLotteryWidgetView *)lotteryWidgetView;

@end

@interface PLVECLotteryWidgetView : UIView

@property (nonatomic, weak) id<PLVECLotteryWidgetViewDelegate> delegate;

@property (nonatomic, assign, readonly) CGSize widgetSize;

/// 更新抽奖挂件数据
/// @param dict 抽奖数据
- (void)updateLotteryWidgetInfo:(NSDictionary *)dict;

- (void)hideWidgetView;

/// 隐藏 Popup 视图
- (void)hidePopupView;

@end

NS_ASSUME_NONNULL_END
