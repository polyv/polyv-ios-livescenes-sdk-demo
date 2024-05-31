//
//  PLVCommodityPushView.h
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/8/20.
//  Copyright © 2020 PLV. All rights reserved.
//  推送商品

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVCommodityModel.h>

NS_ASSUME_NONNULL_BEGIN

/// 直播场景
typedef NS_ENUM(NSUInteger, PLVCommodityPushViewType) {
    /// 云课堂场景
    PLVCommodityPushViewTypeLC = 0,
    /// 直播带货场景
    PLVCommodityPushViewTypeEC = 1
};

@protocol PLVCommodityPushViewDelegate <NSObject>

- (void)plvCommodityPushViewJumpToCommodityDetail:(NSURL *)commodityURL commodity:(PLVCommodityModel *)commodity;

@end

@interface PLVCommodityPushView : UIView

- (instancetype)initWithType:(PLVCommodityPushViewType)type;

- (void)showOnView:(UIView *)superView initialFrame:(CGRect)initialFrame;

- (void)hide;

// 上报日志
- (void)reportTrackEvent;

@property (nonatomic, strong) PLVCommodityModel *model;

@property (nonatomic, weak) id<PLVCommodityPushViewDelegate> delegate;

/// 更新商品点击的次数
- (void)updateProductClickTimes:(NSDictionary *)dict;

/// 发送商品点击事件
- (void)sendProductClickedEvent:(PLVCommodityModel *)model;

@end

NS_ASSUME_NONNULL_END
