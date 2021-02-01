//
//  PLVECHomePageView.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2021/1/22.
//  Copyright © 2021 polyv. All rights reserved.
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

@class PLVECHomePageView;

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
- (void)homePageView:(PLVECHomePageView *)homePageView openGoodsDetail:(NSURL *)goodsURL;

/// 按下暂停、播放按钮
- (void)homePageView:(PLVECHomePageView *)homePageView switchPause:(BOOL)pause;

/// 拖动播放进度条
- (void)homePageView:(PLVECHomePageView *)homePageView seekToTime:(NSTimeInterval)time;

/// 切换播放速率
- (void)homePageView:(PLVECHomePageView *)homePageView switchSpeed:(CGFloat)speed;

@end

@interface PLVECHomePageView : UIView

/// 初始化方法
- (instancetype)initWithType:(PLVECHomePageType)type delegate:(id<PLVECHomePageViewDelegate>)delegate;

/// 销毁方法
- (void)destroy;

- (void)showShoppingCart:(BOOL)show;

- (void)updateChannelInfo:(NSString *)publisher coverImage:(NSString *)coverImage;

- (void)updateRoomInfoCount:(NSUInteger)roomInfoCount;

- (void)updateLikeCount:(NSUInteger)likeCount;

- (void)updatePlayerState:(BOOL)playing;

- (void)updateLineCount:(NSUInteger)lineCount defaultLine:(NSUInteger)line;

- (void)updateCodeRateItems:(NSArray <NSString *>*)codeRates defaultCodeRate:(NSString *)codeRate;

- (void)updateDowloadProgress:(CGFloat)dowloadProgress
               playedProgress:(CGFloat)playedProgress
                     duration:(NSTimeInterval)duration
          currentPlaybackTime:(NSString *)currentPlaybackTime
                 durationTime:(NSString *)durationTime;

@end

NS_ASSUME_NONNULL_END
