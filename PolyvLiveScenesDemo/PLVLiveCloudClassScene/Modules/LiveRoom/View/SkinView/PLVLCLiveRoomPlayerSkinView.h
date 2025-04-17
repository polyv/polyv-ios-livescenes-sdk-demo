//
//  PLVLCLiveRoomPlayerSkinView.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/10/6.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLCBasePlayerSkinView.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVChatModel;

@protocol PLVLCLiveRoomPlayerSkinViewDelegate;

/// 直播间播放器皮肤视图 (用于 横屏时 显示)
///
/// @note 外部对 SkinView 的frame布局，无需特别考虑安全区域。SkinView 内部具备对安全区域的判断及兼容。
///       注意：在观看页中，横屏与竖屏场景，各用了对应的皮肤视图类，并会存在两个皮肤视图对象，即：
///       横屏场景 --> PLVLCLiveRoomPlayerSkinView
///       竖屏场景 --> PLVLCMediaPlayerSkinView
///       分开两个类，两个对象，目的是便于对两种场景的自定义需求；
///       但需注意的地方是，调试过程中，要有意识区分 ”当前你调试的是哪个对象？" 特别是当你在父类 PLVLCBasePlayerSkinView 中 输出打印 或 查看状态值 时；
@interface PLVLCLiveRoomPlayerSkinView : PLVLCBasePlayerSkinView

/// 此类是 PLVLCBasePlayerSkinView 的子类，更多API详见 PLVLCBasePlayerSkinView.h

/// 当前类自有的delegate
@property (nonatomic, weak) id <PLVLCLiveRoomPlayerSkinViewDelegate> delegate;

/// 弹幕开关按钮是否显示，默认为 NO，只有后台开启了弹幕功能才显示弹幕开关按钮
@property (nonatomic, assign) BOOL danmuButtonShow;

/// 是否需要显示皮肤控件，当通过外部控件 调用 hiddenLiveRoomPlayerSkinView 关闭皮肤时内部会记录此皮肤当前显示状态
@property (nonatomic, assign) BOOL needShowSkin;

/// 弹幕开关按钮，用于外部读取弹幕开关状态
@property (nonatomic, strong, readonly) UIButton * danmuButton;

/// 礼物打赏按钮，用于外部读取礼物打赏开关后控制是否显示该按钮
@property (nonatomic, strong, readonly) UIButton *rewardButton;

/// 商品库按钮，用于外部控制是否显示该按钮
@property (nonatomic, strong, readonly) UIButton *commodityButton;

/// 横屏聊天室输入框，用于外部控制是否显示该输入框
@property (nonatomic, strong, readonly) UILabel * guideChatLabel;

/// 隐藏和显示 直播间播放器皮肤视图 控件
/// @param isHidden YES 隐藏控件，NO显示控件
- (void)hiddenLiveRoomPlayerSkinView:(BOOL)isHidden;

- (void)displayLikeButtonView:(UIView *)likeButtonView;

- (void)displayRedpackButtonView:(UIView *)redpackButtonView;

- (void)displayCardPushButtonView:(UIView *)cardPushButtonView;

- (void)displayLotteryWidgetView:(UIView *)lotteryWidgetView;

/// 是否显示打开商品库的按钮
/// @param show YES 显示 NO 不显示
- (void)showCommodityButton:(BOOL)show;

/// 是否显示红包按钮视图
/// @param show YES 显示 NO 不显示
- (void)showRedpackButtonView:(BOOL)show;

/// 是否显示卡片推送按钮视图
/// @param show YES 显示 NO 不显示
- (void)showCardPushButtonView:(BOOL)show;

/// 是否显示抽奖挂件视图
/// @param show YES 显示 NO 不显示
- (void)showLotteryWidgetView:(BOOL)show;

/// 切换聊天室关闭状态，开启/禁用输入框
///  @param closeRoom YES关闭 NO 不关闭
- (void)changeCloseRoomStatus:(BOOL)closeRoom;

/// 切换聊天室专注模式开启/关闭状态，开启/禁用输入框
///  @param focusMode YES开启 NO 不关闭
- (void)changeFocusModeStatus:(BOOL)focusMode;

/// 点击回复某条消息
- (void)didTapReplyChatModel:(PLVChatModel *)model;

@end

@protocol PLVLCLiveRoomPlayerSkinViewDelegate <NSObject>

- (void)plvLCLiveRoomPlayerSkinViewBulletinButtonClicked:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView;

- (void)plvLCLiveRoomPlayerSkinViewDanmuButtonClicked:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView userWannaShowDanmu:(BOOL)showDanmu;

- (void)plvLCLiveRoomPlayerSkinViewDanmuSettingButtonClicked:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView;

- (void)plvLCLiveRoomPlayerSkinView:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView
           userWannaSendChatContent:(NSString *)chatContent
                         replyModel:(PLVChatModel *)replyModel;

- (void)plvLCLiveRoomPlayerSkinViewRewardButtonClicked:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView;

/// 打开商品库按钮点击的回调
/// @param liveRoomPlayerSkinView 横屏 直播间播放器皮肤视图
- (void)plvLCLiveRoomPlayerSkinViewCommodityButtonClicked:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView;

- (void)plvLCLiveRoomPlayerSkinViewLinkMicFullscreenButtonClicked:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView userWannaLinkMicAreaViewShow:(BOOL)show;

@end

NS_ASSUME_NONNULL_END
