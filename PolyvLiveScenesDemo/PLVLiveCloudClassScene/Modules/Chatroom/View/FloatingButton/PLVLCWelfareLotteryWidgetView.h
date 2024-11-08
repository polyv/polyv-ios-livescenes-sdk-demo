//
//  PLVLCWelfareLotteryWidgetView.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/10/18.
//  Copyright © 2024 PLV. All rights reserved.
//
// 云课堂条件抽奖挂件

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLCWelfareLotteryWidgetView;
@protocol PLVLCWelfareLotteryWidgetViewDelegate <NSObject>

/// 点击抽奖挂件的回调
/// @param welfareLotteryWidgetView 云课堂抽奖挂件
- (void)welfareLotteryWidgetViewDidClickAction:(PLVLCWelfareLotteryWidgetView *)welfareLotteryWidgetView;

/// 抽奖挂件显示状态改变的的回调
/// @param welfareLotteryWidgetView 云课堂抽奖挂件
/// @param show 当前的显示状态
- (void)welfareLotteryWidgetView:(PLVLCWelfareLotteryWidgetView *)welfareLotteryWidgetView showStatusChanged:(BOOL)show;

/// 抽奖挂件的 PopupView 显示的的回调
/// @param welfareLotteryWidgetView 云课堂抽奖挂件
- (void)welfareLotteryWidgetViewPopupViewDidShow:(PLVLCWelfareLotteryWidgetView *)welfareLotteryWidgetView;

@end

@interface PLVLCWelfareLotteryWidgetView : UIView

@property (nonatomic, weak) id<PLVLCWelfareLotteryWidgetViewDelegate> delegate;

@property (nonatomic, assign, readonly) CGSize widgetSize;

/// 更新抽奖挂件数据
///  @param dict 抽奖数据
- (void)updateWelfareLotteryWidgetInfo:(NSDictionary *)dict;

- (void)hideWidgetView;

/// 隐藏 Popup 视图
- (void)hidePopupView;

@end

NS_ASSUME_NONNULL_END
