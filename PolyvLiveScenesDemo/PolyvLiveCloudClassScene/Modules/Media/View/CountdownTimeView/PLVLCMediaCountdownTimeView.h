//
//  PLVLCMediaCountdownTimeView.h
//  PolyvLiveScenesDemo
//
//  Created by Hank on 2020/11/13.
//  Copyright © 2020 polyv. All rights reserved.
//  直播间开播时间倒计时视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCMediaCountdownTimeView : UIView

@property (nonatomic, assign) NSTimeInterval time;
@property (nonatomic, assign) CGFloat timeTopPadding;

@end

NS_ASSUME_NONNULL_END
