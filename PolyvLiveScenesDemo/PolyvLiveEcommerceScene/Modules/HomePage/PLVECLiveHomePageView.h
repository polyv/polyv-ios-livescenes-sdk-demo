//
//  PLVECLiveHomePageView.h
//  PolyvLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLiveRoomData.h"
#import "PLVSocketLoginManager.h"

@class PLVECLiveHomePageView;
@protocol PLVECLiveHomePageViewDelegate <NSObject>

@required

/// 授权验证失败
- (void)homePageView:(PLVECLiveHomePageView *)homePageView authorizationVerificationFailed:(PLVLiveRoomErrorReason)reason message:(NSString *)message;

@optional

/// 切换线路
- (void)homePageView:(PLVECLiveHomePageView *)homePageView switchPlayLine:(NSUInteger)line;

/// 切换清晰度
- (void)homePageView:(PLVECLiveHomePageView *)homePageView switchCodeRate:(NSString *)codeRate;

/// 切换音频模式
- (void)homePageView:(PLVECLiveHomePageView *)homePageView switchAudioMode:(BOOL)audioMode;

/// 播放器是否正在播放
- (BOOL)playerIsPlaying;

/// 收到公告消息
- (void)homePageView:(PLVECLiveHomePageView *)homePageView receiveBulletinMessage:(NSString *)content open:(BOOL)open;

/// 打开商品详情
- (void)homePageView:(PLVECLiveHomePageView *)homePageView openGoodsDetail:(NSURL *)goodsURL;

@end

/// 直播主页视图容器
@interface PLVECLiveHomePageView : UIView

@property (nonatomic, strong) UIButton *shoppingCardButton;

/// 初始化方法
- (instancetype)initWithDelegate:(id<PLVECLiveHomePageViewDelegate>)delegate roomData:(PLVLiveRoomData *)roomData;

- (void)destroy;

- (void)updateChannelInfo:(NSString *)publisher coverImage:(NSString *)coverImage;

- (void)updateOnlineCount:(NSUInteger)onlineCount;

- (void)updateLikeCount:(NSUInteger)likeCount;

- (void)updateLineCount:(NSUInteger)lineCount defaultLine:(NSUInteger)line;

- (void)updateCodeRateItems:(NSArray <NSString *>*)codeRates defaultCodeRate:(NSString *)codeRate;

- (void)updatePlayerState:(BOOL)playing;

@end
