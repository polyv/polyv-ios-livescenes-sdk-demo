//
//  PLVECPlayerContolView.h
//  PLVLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 PLV. All rights reserved.
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

/// 更新播放按钮是否播放的状态
/// @param playing YES:播放中  NO:暂停
- (void)updatePlayButtonWithPlaying:(BOOL)playing;

@end

NS_ASSUME_NONNULL_END
