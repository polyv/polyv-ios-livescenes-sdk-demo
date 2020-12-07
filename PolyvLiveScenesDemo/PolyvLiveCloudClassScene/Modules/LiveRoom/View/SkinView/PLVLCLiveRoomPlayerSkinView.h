//
//  PLVLCLiveRoomPlayerSkinView.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/10/6.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PLVLCBasePlayerSkinView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLCLiveRoomPlayerSkinViewDelegate;

/// 直播间播放器皮肤视图 (用于 横屏时 显示)
///
/// @note 外部对 SkinView 的frame布局，无需特别考虑安全区域。SkinView 内部具备对安全区域的判断及兼容。
@interface PLVLCLiveRoomPlayerSkinView : PLVLCBasePlayerSkinView

/// 此类是 PLVLCBasePlayerSkinView 的子类，更多API详见 PLVLCBasePlayerSkinView.h

/// 当前类自有的delegate
@property (nonatomic, weak) id <PLVLCLiveRoomPlayerSkinViewDelegate> delegate;

/// 弹幕开关按钮是否显示，默认为 NO，只有后台开启了弹幕功能才显示弹幕开关按钮
@property (nonatomic, assign) BOOL danmuButtonShow;

/// 弹幕开关按钮，用于外部读取弹幕开关状态
@property (nonatomic, strong, readonly) UIButton * danmuButton;

- (void)displayLikeButtonView:(UIView *)likeButtonView;

@end

@protocol PLVLCLiveRoomPlayerSkinViewDelegate <NSObject>

- (void)plvLCLiveRoomPlayerSkinViewBulletinButtonClicked:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView;

- (void)plvLCLiveRoomPlayerSkinViewDanmuButtonClicked:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView userWannaShowDanmu:(BOOL)showDanmu;

- (void)plvLCLiveRoomPlayerSkinView:(PLVLCLiveRoomPlayerSkinView *)liveRoomPlayerSkinView userWannaSendChatContent:(NSString *)chatContent;

@end

NS_ASSUME_NONNULL_END
