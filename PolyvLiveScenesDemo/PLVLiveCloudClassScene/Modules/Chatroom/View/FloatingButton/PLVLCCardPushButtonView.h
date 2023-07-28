//
//  PLVLCCardPushButtonView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2022/7/6.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#define PLVLCCardPushButtonViewWidth (40.0)
#define PLVLCCardPushButtonViewHeight (40.0 + 2.0 + 12.0)

NS_ASSUME_NONNULL_BEGIN

@class PLVLCCardPushButtonView;

@protocol PLVLCCardPushButtonViewDelegate <NSObject>

/// 在点击卡片领取按钮或者观看领奖倒计时结束后会执行此回调，需要互动视图打开领取入口
/// @param pushButtonView 卡片推送领取按钮挂件
/// @param dict 打开视图需要的参数
- (void)cardPushButtonView:(PLVLCCardPushButtonView *)pushButtonView needOpenInteract:(NSDictionary *)dict;

/// 卡片推送挂件的 PopupView 显示的的回调
/// @param pushButtonView 卡片推送挂件
- (void)cardPushButtonViewPopupViewDidShow:(PLVLCCardPushButtonView *)pushButtonView;

@end

@interface PLVLCCardPushButtonView : UIView

@property (nonatomic, weak) id<PLVLCCardPushButtonViewDelegate> delegate;

/// 开启卡片推送
/// @param start 是否是开启推送 YES开启 NO取消
/// @param dict 卡片推送信息
/// @param callback 开始卡片推送的回调，是否显示挂件（YES 显示，NO不显示）
- (void)startCardPush:(BOOL)start cardPushInfo:(NSDictionary *)dict callback:(void (^)(BOOL show))callback;

/// 隐藏 Popup 视图
- (void)hidePopupView;

/// 离开直播房间
- (void)leaveLiveRoom;

@end

NS_ASSUME_NONNULL_END
