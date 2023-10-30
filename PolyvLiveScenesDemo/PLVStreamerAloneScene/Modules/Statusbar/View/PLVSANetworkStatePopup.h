//
//  PLVSANetworkStatePopup.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/4/15.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVSANetworkStatePopup : UIView

@property (nonatomic, assign, readonly) BOOL showing;

@property (nonatomic, assign, readonly) CGSize bubbleSize;

- (void)setupBubbleFrame:(CGRect)frame buttonFrame:(CGRect)buttonFrame;

- (void)showAtView:(UIView *)superView;

- (void)dismiss;

- (void)refreshWithBubbleFrame:(CGRect)frame buttonFrame:(CGRect)buttonFrame;

- (void)updateRTT:(NSInteger)rtt upLoss:(NSInteger)upLoss downLoss:(NSInteger)downLoss;

@end

NS_ASSUME_NONNULL_END
