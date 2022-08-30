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

@class playbackViewModel;

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

- (void)startCardPush:(BOOL)start cardPushInfo:(NSDictionary *)dict;

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

@end
NS_ASSUME_NONNULL_END
