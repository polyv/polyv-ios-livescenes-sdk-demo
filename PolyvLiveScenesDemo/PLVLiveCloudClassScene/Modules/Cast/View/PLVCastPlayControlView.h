//
//  PLVCastPlayControlView.h
//  PLVCloudClassDemo
//
//  Created by MissYasiky on 2020/7/23.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVCastPlayControlViewDelegate <NSObject>

// 【返回】按钮点击回调
- (void)castControlBackButtonClick;

// 【退出】按钮点击回调
- (void)castControlQuitButtonClick;

// 【换设备】按钮点击回调
- (void)castControlDeviceButtonClick;

// 【清晰度】按钮点击回调
- (void)castControlDefinitionButtonClick;

// 【播放/暂停】按钮点击回调
- (void)castControlPlayButtonClick:(BOOL)play;

// 【半屏/全屏】按钮点击回调
- (void)castControlFullScreenButtonClick;

@end

@interface PLVCastPlayControlView : UIView

@property (nonatomic, weak) id <PLVCastPlayControlViewDelegate> delegate;

@property (nonatomic, strong, readonly) UIView *castBgView;

@property (nonatomic, copy) NSString *deviceName;

@property (nonatomic, copy) NSString *definition;

@property (nonatomic, assign, getter=isPlaying) BOOL playing;

@property (nonatomic, assign, readonly) BOOL isShow; /// 皮肤是否显示中

- (void)show;

- (void)hide;

@end

NS_ASSUME_NONNULL_END
