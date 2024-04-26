//
//  PLVLCMenuAreaView.h
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/7/23.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLCChatViewController.h"
#import "PLVLCDescViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class playbackViewModel, PLVChatModel;

typedef NS_ENUM(NSInteger, PLVLCLivePageMenuType) {
    PLVLCLivePageMenuTypeUnknown = -1,  // 未知
    PLVLCLivePageMenuTypeDesc = 0,      // 直播介绍
    PLVLCLivePageMenuTypeChat,          // 互动聊天
    PLVLCLivePageMenuTypeQuiz,          // 咨询提问
    PLVLCLivePageMenuTypeTuwen,         // 图文直播
    PLVLCLivePageMenuTypeText,          // 自定义图文直播
    PLVLCLivePageMenuTypeQA,            // 问答功能
    PLVLCLivePageMenuTypeIframe,        // 推广外链
    PLVLCLivePageMenuTypeBuy            // 边看边买
};

/// 将后端返回的menu字符串转化为枚举值PLVLCLivePageMenuType
PLVLCLivePageMenuType PLVLCMenuTypeWithMenuTypeString(NSString *menuString);

@protocol PLVLCLivePageMenuAreaViewDelegate;

@interface PLVLCLivePageMenuAreaView : UIView

@property (nonatomic, weak) id <PLVLCLivePageMenuAreaViewDelegate> delegate;

/// 互动聊天页，退出直播时需要clearResource，切换全屏时需要提取聊天室的点赞Button
@property (nonatomic, strong) PLVLCChatViewController *chatVctrl;

/// 是否包含边买边看商品库菜单
@property (nonatomic, assign, readonly) BOOL showCommodityMenu;

/// 初始化方法
/// @param liveRoom 直播间控制器，传递给互动聊天室用于弹出拍照、相册控制器
- (instancetype)initWithLiveRoom:(UIViewController *)liveRoom;

/// 直播状态改变时调用
- (void)updateLiveStatus:(PLVLCLiveStatus)liveStatus;

/// 直播用户信息发生改变时调用
- (void)updateLiveUserInfo;

/// 通过菜单视图，更新聊天回放viewModel到聊天室视图
- (void)updatePlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)playbackViewModel;

/// 开启卡片推送
/// @param start 是否开启推送 （YES 开启推送，NO关闭推送）
/// @param dict 卡片推送参数
/// @param callback 开始卡片推送的回调，是否显示挂件（YES 显示，NO不显示）
- (void)startCardPush:(BOOL)start cardPushInfo:(NSDictionary *)dict callback:(void (^)(BOOL show))callback;

/// 更新商品库菜单Tab
/// @param dict 商品菜单参数
- (void)updateProductMenuTab:(NSDictionary *)dict;

- (void)displayProductPageToExternalView:(UIView *)externalView;

- (void)rollbackProductPageContentView;

- (void)leaveLiveRoom;

@end

@protocol PLVLCLivePageMenuAreaViewDelegate <NSObject>

/// 获取当前播放进度
/// @param pageMenuAreaView 菜单视图
- (NSTimeInterval)plvLCLivePageMenuAreaViewGetPlayerCurrentTime:(PLVLCLivePageMenuAreaView *)pageMenuAreaView;

/// 跳转到指定时间
/// @param pageMenuAreaView 菜单视图
/// @param time 跳转指定时间
- (void)plvLCLivePageMenuAreaView:(PLVLCLivePageMenuAreaView *)pageMenuAreaView seekTime:(NSTimeInterval)time;

/// 点击商品库中的商品的回调
/// @param pageMenuAreaView 菜单视图
/// @param linkURL 商品详情的链接url
- (void)plvLCLivePageMenuAreaView:(PLVLCLivePageMenuAreaView *)pageMenuAreaView clickProductLinkURL:(NSURL *)linkURL;

/// 关闭商品库视图的回调
/// @param pageMenuAreaView 菜单视图
- (void)plvLCLivePageMenuAreaViewCloseProductView:(PLVLCLivePageMenuAreaView *)pageMenuAreaView;

/// 在点击卡片领取按钮或者观看领奖倒计时结束后会执行此回调，需要互动视图打开领取入口
/// @param pageMenuAreaView 菜单视图
/// @param dict 打开视图需要的参数
- (void)plvLCLivePageMenuAreaView:(PLVLCLivePageMenuAreaView *)pageMenuAreaView needOpenInteract:(NSDictionary *)dict;

/// 在点击超过500字符的长文本消息时会执行此回调
/// @param pageMenuAreaView 菜单视图
/// @param model 需要展示完整文本的长文本消息数据模型
- (void)plvLCLivePageMenuAreaView:(PLVLCLivePageMenuAreaView *)pageMenuAreaView alertLongContentMessage:(PLVChatModel *)model;

/// 点击互动模块控件的回调
/// @param pageMenuAreaView 菜单视图
/// @param event 互动模块事件
- (void)plvLCLivePageMenuAreaView:(PLVLCLivePageMenuAreaView *)pageMenuAreaView emitInteractEvent:(NSString *)event;

/// 抽奖挂件显示状态改变的的回调
/// @param pageMenuAreaView 菜单视图
/// @param show 当前的显示状态
- (void)plvLCLivePageMenuAreaView:(PLVLCLivePageMenuAreaView *)pageMenuAreaView lotteryWidgetShowStatusChanged:(BOOL)show;

@end
NS_ASSUME_NONNULL_END
