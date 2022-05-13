//
//  PLVAdvertView.h
//  PLVLiveScenesDemo
//
//  Created by Hank on 2020/12/23.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

/// 广告 配置参数类
@interface PLVAdvertParam : NSObject

#pragma mark 片头广告
@property (nonatomic, assign) PLVChannelAdvertType advertType;
/// 图片广告链接
@property (nonatomic, copy) NSString *advertImageUrl;
/// 视频广告链接
@property (nonatomic, copy) NSString *advertFlvUrl;
/// 广告时长
@property (nonatomic, assign) NSUInteger advertDuration;
/// 广告跳转链接
@property (nonatomic, copy) NSString *advertHref;

#pragma mark 暂停广告
/// 广告图片
@property (nonatomic, copy) NSString *stopAdvertImageUrl;
/// 广告图片跳转链接
@property (nonatomic, copy) NSString *stopAdvertHref;

@end

/// 片头广告展示状态
typedef NS_ENUM(NSInteger, PLVAdvertViewPlayState) {
    PLVAdvertViewPlayStateUnKnow = 0,  // 未知类型（初始状态）
    PLVAdvertViewPlayStatePlay,        // 展示中
    PLVAdvertViewPlayStateFinish,      // 展示完成
};

@class PLVAdvertView;

@protocol PLVAdvertViewDelegate <NSObject>

@required
/// 广告播放状态改变
- (void)plvAdvertView:(PLVAdvertView *)advertView playStateDidChange:(PLVAdvertViewPlayState)state;

/// 点击片头广告跳转事件
- (void)plvAdvertView:(PLVAdvertView *)advertView clickStartAdvertWithHref:(NSURL *)advertHref;

/// 点击暂停广告跳转事件
- (void)plvAdvertView:(PLVAdvertView *)advertView clickStopAdvertWithHref:(NSURL *)stopAdvertHref;

@end

@interface PLVAdvertView : UIView

/// 是否正在播放片头广告
@property (nonatomic, readonly) BOOL startAdvertIsPlaying;
/// 播放状态（正在展示广告图片也算作正在播放）
@property (nonatomic, readonly) PLVAdvertViewPlayState playState;

@property (nonatomic, weak) id<PLVAdvertViewDelegate> delegate;

- (instancetype)initWithParam:(PLVAdvertParam *)param;

/// 设置广告视图外部容器
- (void)setupDisplaySuperview:(UIView *)displaySuperview;

/// 显示片头广告
- (void)showTitleAdvert;

/// 销毁片头广告
- (void)destroyTitleAdvert;

/// 展示暂停广告
- (void)showStopAdvertImage;

/// 隐藏暂停广告
- (void)hideStopAdvertView;

@end

NS_ASSUME_NONNULL_END
