//
//  PLVHCLinkMicSettingPopView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/8/27.
//  Copyright © 2021 polyv. All rights reserved.
//
// 连麦区域设备设置弹窗

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLinkMicOnlineUser;

@protocol PLVHCLinkMicSettingPopViewDelegate;

@interface PLVHCLinkMicSettingPopView : UIView

@property (nonatomic, weak) id<PLVHCLinkMicSettingPopViewDelegate> delegate;

- (void)showSettingViewWithUser:(PLVLinkMicOnlineUser *)user;

///加载本地预览视图的时候需要显示
- (void)showSettingViewWithLocalConfig:(NSDictionary *)configDict;

@end

/// 连麦区域设置弹窗代理
@protocol PLVHCLinkMicSettingPopViewDelegate <NSObject>

@optional

/// 麦克风开启或者关闭
/// @param enable (YES 开启 NO关闭)
- (void)linkMicPopView:(PLVHCLinkMicSettingPopView *)popView
             enableMic:(BOOL)enable;

/// 摄像头开启或者关闭
/// @param enable (YES 开启 NO关闭)
- (void)linkMicPopView:(PLVHCLinkMicSettingPopView *)popView
          enableCamera:(BOOL)enable;

/// 摄像头方向切换
/// @param switchFront (YES朝前  NO朝后)
- (void)linkMicPopView:(PLVHCLinkMicSettingPopView *)popView
           cameraFront:(BOOL)switchFront;

@end

@interface PLVHCLinkMicSettingPopItemView : UIView

@property (nonatomic, strong) UIButton *button;

@property (nonatomic, strong) UILabel *titleLabel;

@end

NS_ASSUME_NONNULL_END
