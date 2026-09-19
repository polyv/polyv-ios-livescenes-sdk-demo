//
//  PLVPlayerTipBannerView.h
//  PolyvLiveScenesDemo
//
//  Copyright © 2026 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 播放器轻量提示横幅样式（对应原缺省页 type，优先级 3 > 2 > 1）
typedef NS_ENUM(NSUInteger, PLVPlayerTipBannerType) {
    /// 样式1，仅展示错误文案 + 关闭
    PLVPlayerTipBannerTypeErrorCode = 0,
    /// 样式2，网络不稳定 + 可点「刷新」
    PLVPlayerTipBannerTypeRefresh = 1,
    /// 样式3，网络不稳定 + 可点「线路」
    PLVPlayerTipBannerTypeSwitchLine = 2
};

@class PLVPlayerTipBannerView;

@protocol PLVPlayerTipBannerViewDelegate <NSObject>

- (void)plvPlayerTipBannerViewWannaRefresh:(PLVPlayerTipBannerView *)tipBannerView;

- (void)plvPlayerTipBannerViewWannaSwitchLine:(PLVPlayerTipBannerView *)tipBannerView;

@optional
- (void)plvPlayerTipBannerViewDidClose:(PLVPlayerTipBannerView *)tipBannerView;

@end

@interface PLVPlayerTipBannerView : UIView

@property (nonatomic, weak) id <PLVPlayerTipBannerViewDelegate> delegate;

/// 横幅容器（皮肤 hit-test 用）
@property (nonatomic, readonly) UIView *bannerView;

/// 关闭按钮（皮肤 hit-test 用）
@property (nonatomic, readonly) UIButton *closeButton;

/// 可点操作区域（刷新/线路链接所在 textView，皮肤 hit-test 用）
@property (nonatomic, readonly) UIView *actionControl;

- (void)showWithErrorMessage:(NSString * _Nullable)message type:(PLVPlayerTipBannerType)type;

/// @note type 为 Refresh / SwitchLine 时不展示 errorCode；ErrorCode 时可附带错误码
- (void)showWithErrorCode:(NSInteger)errorCode message:(NSString * _Nullable)message type:(PLVPlayerTipBannerType)type;

- (void)hide;

/// 仅隐藏网络不稳定类提示（刷新 / 切线），不影响错误码横幅
- (void)hideIfNetworkUnstableTip;

@end

NS_ASSUME_NONNULL_END
