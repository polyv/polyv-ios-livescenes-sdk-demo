//
//  PLVECCardPushButtonView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2022/7/13.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#define PLVECCardPushButtonViewWidth (44)
#define PLVECCardPushButtonViewHeight (44.0 + 12.0)

NS_ASSUME_NONNULL_BEGIN

@class PLVECCardPushButtonView;

@protocol PLVECCardPushButtonViewDelegate <NSObject>

/// 在点击卡片领取按钮或者观看领奖倒计时结束后会执行此回调，需要互动视图打开领取入口
/// @param pushButtonView 卡片推送领取按钮挂件
/// @param dict 打开视图需要的参数
- (void)cardPushButtonView:(PLVECCardPushButtonView *)pushButtonView needOpenInteract:(NSDictionary *)dict;

/// 卡片推送挂件的显示状态改变的的回调
/// @param pushButtonView 卡片推送挂件
/// @param show 当前的显示状态
- (void)cardPushButtonView:(PLVECCardPushButtonView *)pushButtonView showStatusChanged:(BOOL)show;

/// 卡片推送挂件的 PopupView 显示的的回调
/// @param pushButtonView 卡片推送挂件
- (void)cardPushButtonViewPopupViewDidShow:(PLVECCardPushButtonView *)pushButtonView;

@end

@interface PLVECCardPushButtonView : UIView

@property (nonatomic, weak) id<PLVECCardPushButtonViewDelegate> delegate;

/// 开启卡片推送
/// @param start 是否是开启推送 YES开启 NO取消
/// @param dict 卡片推送信息
- (void)startCardPush:(BOOL)start cardPushInfo:(NSDictionary *)dict;

/// 隐藏 Popup 视图
- (void)hidePopupView;

/// 离开直播房间
- (void)leaveLiveRoom;

@end

NS_ASSUME_NONNULL_END
