//
//  PLVHCLinkMicSettingPopView.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/8/27.
//  Copyright © 2021 PLV. All rights reserved.
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
- (void)showLocalSettingView;

/// 设置本地预览视图 是否在放大区域
/// @param inLinkMicZoom YES: 正在放大区域；NO：不在放大区域
- (void)setupLocalPrevierUserInLinkMicZoom:(BOOL)inLinkMicZoom;

@end

/// 连麦区域设置弹窗代理
@protocol PLVHCLinkMicSettingPopViewDelegate <NSObject>

@optional

/// 连麦视图切换
- (void)linkMicPopView:(PLVHCLinkMicSettingPopView *)popView
           didSwitchLinkMicWithUserModel:(PLVLinkMicOnlineUser *)userModel localPreviewUser:(BOOL)localPreviewUser showInZoom:(BOOL)showInZoom;

@end

@interface PLVHCLinkMicSettingPopItemView : UIView

@property (nonatomic, strong) UIButton *button;

@property (nonatomic, strong) UILabel *titleLabel;

@end

NS_ASSUME_NONNULL_END
