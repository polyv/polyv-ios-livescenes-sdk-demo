//
//  PLVECHomePageView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/1/22.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVPinMessagePopupView.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

/// HomePage 页面类型
typedef NS_ENUM(NSUInteger, PLVECHomePageType) {
    /// 页面类型为 直播
    PLVECHomePageType_Live = 0,
    /// 页面类型为 直播回放（注：特指直播结束后的回放，有别于‘点播’）
    PLVECHomePageType_Playback = 1
};

@class PLVECHomePageView, PLVChatModel;

@protocol PLVECHomePageViewDelegate <NSObject>

- (BOOL)homePageView_inLinkMic:(PLVECHomePageView *)homePageView;

@optional

- (NSTimeInterval)homePageView_playbackMaxPosition:(PLVECHomePageView *)homePageView;

/// 切换线路
- (void)homePageView:(PLVECHomePageView *)homePageView switchPlayLine:(NSUInteger)line;

/// 切换清晰度
- (void)homePageView:(PLVECHomePageView *)homePageView switchCodeRate:(NSString *)codeRate;

/// 切换音频模式
- (void)homePageView:(PLVECHomePageView *)homePageView switchAudioMode:(BOOL)audioMode;

/// 收到公告消息
- (void)homePageView:(PLVECHomePageView *)homePageView receiveBulletinMessage:(NSString * _Nullable)content open:(BOOL)open;

/// 打开商品详情
- (void)homePageView:(PLVECHomePageView *)homePageView didClickCommodityDetail:(PLVCommodityModel *)commodity;

/// 打开礼物打赏面板
- (void)homePageViewOpenRewardView:(PLVECHomePageView *)homePageView;

/// 打开卡片推送
- (void)homePageView:(PLVECHomePageView *)homePageView openCardPush:(NSDictionary *)cardInfo;

/// 按下暂停、播放按钮
- (void)homePageView:(PLVECHomePageView *)homePageView switchPause:(BOOL)pause;

/// 拖动播放进度条
- (void)homePageView:(PLVECHomePageView *)homePageView seekToTime:(NSTimeInterval)time;

/// 切换播放速率
- (void)homePageView:(PLVECHomePageView *)homePageView switchSpeed:(CGFloat)speed;

/// 切换延迟模式
- (void)homePageView:(PLVECHomePageView *)homePageView switchToNoDelayWatchMode:(BOOL)noDelayWatchMode;

/// 打开小窗播放
- (void)homePageViewClickPictureInPicture:(PLVECHomePageView *)homePageView;

/// 退到后台自动启动小窗控制开关
- (void)homePageView:(PLVECHomePageView *)homePageView autoStartPIP:(BOOL)autoStart;

/// 点击语言切换按钮
- (void)homePageView:(PLVECHomePageView *)homePageView switchLanguageMode:(NSInteger)languageMode;

/// 返回竖屏样式
- (void)homePageViewWannaBackToVerticalScreen:(PLVECHomePageView *)homePageView;

/// 加载打赏信息时触发
/// @param rewardEnable 是否支持打赏
/// @param payWay 打赏方式，CASH为现金打赏，POINT为积分打赏
/// @param modelArray 打赏数据模型数组
/// @param pointUnit 打赏单位
- (void)homePageView_loadRewardEnable:(BOOL)rewardEnable payWay:(NSString * _Nullable)payWay rewardModelArray:(NSArray *_Nullable)modelArray pointUnit:(NSString * _Nullable)pointUnit;

/// 聊天室人数达到并发限制
- (void)homePageView_didLoginRestrict;

/// 在点击超过500字符的长文本消息时会执行此回调
/// @param model 需要展示完整文本的长文本消息数据模型
- (void)homePageView_alertLongContentMessage:(PLVChatModel *)model;

/// 打开互动应用模块
- (void)homePageView_openInteractApp:(PLVECHomePageView *)homePageView eventName:(NSString *)eventName;

/// 点击领取红包时触发
/// @param state 红包消息状态
/// @param model 对应消息数据模型
- (void)homePageView_checkRedpackStateResult:(PLVRedpackState)state chatModel:(PLVChatModel *)model;

/// 点击互动模块控件的回调
/// @param event 互动模块事件
- (void)homePageView:(PLVECHomePageView *)homePageView emitInteractEvent:(NSString *)event;

/// 点击职位详情的回调
/// @param data 商品详情数据
- (void)homePageView:(PLVECHomePageView *)homePageView didShowJobDetail:(NSDictionary *)data;

/// 收到评论上墙信息的回调
/// @param model 消息模型
/// @param show 是否需要显示评论上墙视图
- (void)homePageView_receiveSpeakTopMessageChatModel:(PLVChatModel *)model showPinMsgView:(BOOL)show;

- (void)homePageViewWannaShowOnlineList:(PLVECHomePageView *)homePageView;

/// 点击福利抽奖挂件的回调
- (void)homePageViewWannaShowWelfareLottery:(PLVECHomePageView *)homePageView;

/// 福利抽奖挂件显示状态改变的的回调
/// @param show 当前的显示状态
- (void)homePageView:(PLVECHomePageView *)homePageView welfareLotteryWidgetShowStatusChanged:(BOOL)show;

@end

@interface PLVECHomePageView : UIView

/// 是否在iPad上显示横屏返回按钮
///
/// @note NO-在iPad上横屏时不显示横屏返回按钮，YES-显示
///       当项目未适配分屏时，建议设置为YES
@property (nonatomic,assign) BOOL backButtonShowOnIpad;

/// 评论上墙视图
@property (nonatomic, strong, readonly) PLVPinMessagePopupView *pinMsgPopupView;

/// 初始化方法
- (instancetype)initWithType:(PLVECHomePageType)type delegate:(id<PLVECHomePageViewDelegate>)delegate;

/// 销毁方法
- (void)destroy;

- (void)showShoppingCart:(BOOL)show;

- (void)showMoreView;

- (void)updateChannelInfo:(NSString *)publisher coverImage:(NSString *)coverImage;

- (void)updateRoomInfoCount:(NSUInteger)roomInfoCount;

- (void)updateLikeCount:(NSUInteger)likeCount;

- (void)updatePlayerState:(BOOL)playing;

- (void)updateLinkMicState:(BOOL)linkMic;

- (void)updateLineCount:(NSUInteger)lineCount defaultLine:(NSUInteger)line;

- (void)updateCodeRateItems:(NSArray <NSString *>*)codeRates defaultCodeRate:(NSString *)codeRate;

- (void)updateNoDelayWatchMode:(BOOL)noDelayWatchMode;

- (void)updateDowloadProgress:(CGFloat)dowloadProgress
               playedProgress:(CGFloat)playedProgress
                     duration:(NSTimeInterval)duration
  currentPlaybackTimeInterval:(NSTimeInterval)currentPlaybackTimeInterval
          currentPlaybackTime:(NSString *)currentPlaybackTime
                 durationTime:(NSString *)durationTime;

- (void)updatePlaybackVideoInfo;

- (void)showNetworkQualityMiddleView;

- (void)showNetworkQualityPoorView;

/// 更新更多按钮的显示或隐藏
/// @param show YES:显示  NO:隐藏
- (void)updateMoreButtonShow:(BOOL)show;

/// 更新进度控件隐藏（包含进度条，进度文本）
- (void)updateProgressControlsHidden:(BOOL)hidden;

/// 更新播放按钮是否启用
- (void)updatePlayButtonEnabled:(BOOL)enabled;

- (void)updateIarEntranceButtonDataArray:(NSArray *)dataArray;

/// 更新更多按钮的按钮状态
/// @param dataArray 按钮数据
- (void)updateMoreButtonDataArray:(NSArray *)dataArray;

- (void)showInScreen:(BOOL)show;

/// 更新抽奖插件信息
/// @param dataArray 抽奖插件数据
- (void)updateLotteryWidgetViewInfo:(NSArray *)dataArray;

/// 更新福利抽奖插件信息
/// @param dict 福利抽奖插件数据
- (void)updateWelfareLotteryWidgetViewInfo:(NSDictionary *)dict;

/// 统计上报商品点击事件
/// @param commodity 商品详情
- (void)reportProductClickedEvent:(PLVCommodityModel *)commodity;

/// 更新往期列表按钮显示/隐藏
/// @param show 显示
- (void)updatePlaybackListButton:(BOOL)show;

/// 更新评论上墙视图
/// @param show 是否显示 评论上墙视图
/// @param message 消息详情模型
- (void)showPinMessagePopupView:(BOOL)show message:(PLVSpeakTopMessage * _Nullable)message;

/// 用于聊天重放时，回放视频记忆播放时通知聊天回放viewModel
- (void)playbackDidShowMemoryPlayTip;

/// 在线人数
- (void)updateOnlineListButton:(NSInteger)onlineCount;

@end

NS_ASSUME_NONNULL_END
