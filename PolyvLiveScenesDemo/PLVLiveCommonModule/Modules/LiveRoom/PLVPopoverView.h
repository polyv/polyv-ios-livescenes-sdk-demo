//
//  PLVPopoverView.h
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/2/24.
//  Copyright © 2021 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVGiveRewardView.h"
#import "PLVInteractGenericView.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

/// 直播场景
typedef NS_ENUM(NSUInteger, PLVPopoverViewLiveType) {
    /// 云课堂场景
    PLVPopoverViewLiveTypeLC = 0,
    /// 直播带货场景
    PLVPopoverViewLiveTypeEC = 1
};

@protocol PLVPopoverViewDelegate <NSObject>

///  积分打赏请求失败回调
/// @note 回调在主线程执行
- (void)popoverViewDidDonatePointWithError:(NSString *)error;

@end
/// 负责展示礼物打赏面板以及互动视图
@interface PLVPopoverView : UIView

/// 互动视图
@property (nonatomic, strong, readonly) PLVInteractGenericView *interactView;

@property (nonatomic, weak) id<PLVPopoverViewDelegate> delegate;

- (instancetype)initWithLiveType:(PLVPopoverViewLiveType)liveType liveRoom:(BOOL)liveRoom;

- (void)loadRewardViewDataWithCompletion:(void (^)(void))completion failure:(void (^)(NSString *))failure;

- (void)setRewardViewData:(NSString * _Nullable)payWay rewardModelArray:(NSArray * _Nullable)modelArray pointUnit:(NSString * _Nullable)pointUnit;

- (void)showRewardView;

- (void)hidRewardView;

@end

NS_ASSUME_NONNULL_END
