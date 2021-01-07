//
//  PLVECPlayerContolView.h
//  PolyvLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVECPlayerContolView;
@protocol PLVPlayerContolViewDelegate <NSObject>

@optional
- (void)playerContolView:(PLVECPlayerContolView *)playerContolView switchPause:(BOOL)pause;

- (void)playerContolViewSeeking:(PLVECPlayerContolView *)playerContolView;

@end

/// 播放器控制视图
@interface PLVECPlayerContolView : UIView

@property (nonatomic, weak) id<PLVPlayerContolViewDelegate> delegate;

@property (nonatomic, strong) UIButton *playButton;

@property (nonatomic, strong) UILabel *currentTimeLabel;

@property (nonatomic, strong) UILabel *totalTimeLabel;

@property (nonatomic, strong) UISlider *progressSlider;

@property (nonatomic, assign) BOOL sliderDragging;

@property (nonatomic, assign) NSTimeInterval duration;

@end

NS_ASSUME_NONNULL_END
