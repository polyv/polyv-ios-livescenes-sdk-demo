//
//  PLVChatroomView.h
//  PLVLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVECChatroomView;

@protocol PLVECChatroomViewDelegate <NSObject>

/// 加载打赏信息时触发
/// @param rewardEnable 是否支持打赏
/// @param payWay 打赏方式，CASH为现金打赏，POINT为积分打赏
/// @param modelArray 打赏数据模型数组
/// @param pointUnit 打赏单位
- (void)chatroomView_loadRewardEnable:(BOOL)rewardEnable payWay:(NSString * _Nullable)payWay rewardModelArray:(NSArray *_Nullable)modelArray pointUnit:(NSString * _Nullable)pointUnit;

- (NSTimeInterval)chatroomView_currentPlaybackTime;

/// 聊天室登录达到并发限制时触发
- (void)chatroomView_didLoginRestrict;

@end

/// 聊天室视图
@interface PLVECChatroomView : UIView

@property (nonatomic, weak) id<PLVECChatroomViewDelegate> delegate;

- (void)updateDuration:(NSTimeInterval)duration;

- (void)playbackTimeChanged;

@end

NS_ASSUME_NONNULL_END
