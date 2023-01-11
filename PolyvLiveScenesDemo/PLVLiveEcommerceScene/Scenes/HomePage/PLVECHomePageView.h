//
//  PLVECHomePageView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/1/22.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

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

@optional

/// 切换线路
- (void)homePageView:(PLVECHomePageView *)homePageView switchPlayLine:(NSUInteger)line;

/// 切换清晰度
- (void)homePageView:(PLVECHomePageView *)homePageView switchCodeRate:(NSString *)codeRate;

/// 切换音频模式
- (void)homePageView:(PLVECHomePageView *)homePageView switchAudioMode:(BOOL)audioMode;

/// 收到公告消息
- (void)homePageView:(PLVECHomePageView *)homePageView receiveBulletinMessage:(NSString * _Nullable)content open:(BOOL)open;

/// 打开商品详情
- (void)homePageView:(PLVECHomePageView *)homePageView openCommodityDetail:(NSURL *)commodityURL;

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

@end

@interface PLVECHomePageView : UIView

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

- (void)updateLineCount:(NSUInteger)lineCount defaultLine:(NSUInteger)line;

- (void)updateCodeRateItems:(NSArray <NSString *>*)codeRates defaultCodeRate:(NSString *)codeRate;

- (void)updateNoDelayWatchMode:(BOOL)noDelayWatchMode;

- (void)updateDowloadProgress:(CGFloat)dowloadProgress
               playedProgress:(CGFloat)playedProgress
                     duration:(NSTimeInterval)duration
  currentPlaybackTimeInterval:(NSTimeInterval)currentPlaybackTimeInterval
          currentPlaybackTime:(NSString *)currentPlaybackTime
                 durationTime:(NSString *)durationTime;

- (void)showNetworkQualityMiddleView;

- (void)showNetworkQualityPoorView;

/// 更新更多按钮的显示或隐藏
/// @param show YES:显示  NO:隐藏
- (void)updateMoreButtonShow:(BOOL)show;

@end

NS_ASSUME_NONNULL_END
