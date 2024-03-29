//
//  PLVSAStreamerFinishView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAStreamerFinishView.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"

@interface PLVSAStreamerFinishView ()

@property (nonatomic, strong) UIButton *finishButton;
@property (nonatomic, strong) UILabel *liveEndLable;
@property (nonatomic, strong) UIImageView *liveEndImageView;
/// 分界线
@property (nonatomic, strong) UIView *dividingLineView;
/// 直播开始时间到结束时间
@property (nonatomic, strong) UILabel *liveDetailTimeLable;
/// 直播总时长
@property (nonatomic, strong) UILabel *liveDurationTimeLable;

@property (nonatomic, strong) UILabel *detailTimeTitleLable;

@property (nonatomic, strong) UILabel *durationTimeTitleLable;

@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end

@implementation PLVSAStreamerFinishView


#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    
    CGFloat top = [PLVSAUtils sharedUtils].areaInsets.top;
    CGFloat bottom = [PLVSAUtils sharedUtils].areaInsets.bottom;
    CGFloat finishButtonWidth = 180;
    CGFloat finishButtonBottom = isLandscape ? 44 : 85;
    CGFloat liveEndImageViewTop = isLandscape ? 38 : 40;
    CGFloat liveTimeLableTop = isLandscape ? 20 : 42;
    CGFloat liveTimeLineTop = isLandscape ? 18 : 40;
    if (isPad) {
        finishButtonWidth = self.bounds.size.width * 0.468;
        finishButtonBottom = self.bounds.size.height * 0.117;
        liveEndImageViewTop = self.bounds.size.height * 0.224;
    }
    
    self.finishButton.frame = CGRectMake((self.bounds.size.width - finishButtonWidth) / 2.0, self.bounds.size.height - bottom - finishButtonBottom - 50, finishButtonWidth, 50);
    self.gradientLayer.frame = self.finishButton.bounds;
    
    self.liveEndImageView.frame = CGRectMake((CGRectGetWidth(self.bounds) - 100) / 2, top + liveEndImageViewTop, 100, 84);
    self.liveEndLable.frame = CGRectMake((CGRectGetWidth(self.bounds) - 180) / 2, UIViewGetBottom(self.liveEndImageView) + 6, 180, 33);
    self.dividingLineView.frame = CGRectMake((CGRectGetWidth(self.bounds) - 2) / 2, UIViewGetBottom(self.liveEndLable) + liveTimeLineTop, 2, 52);
    self.liveDetailTimeLable.frame = CGRectMake(UIViewGetLeft(self.dividingLineView) - 20 - 150, UIViewGetBottom(self.liveEndLable) + liveTimeLableTop, 150, 22);
    self.liveDurationTimeLable.frame = CGRectMake(UIViewGetRight(self.dividingLineView) + 56, UIViewGetTop(self.liveDetailTimeLable), 80, 22);
    
    self.detailTimeTitleLable.frame = CGRectMake(CGRectGetMidX(self.liveDetailTimeLable.frame) - 70 / 2, UIViewGetBottom(self.liveDetailTimeLable) + 8, 70, 20);
    self.durationTimeTitleLable.frame = CGRectMake(CGRectGetMidX(self.liveDurationTimeLable.frame) - 90 / 2, UIViewGetBottom(self.liveDetailTimeLable) + 8, 90, 20);
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self addSubview:self.finishButton];
    [self addSubview:self.liveEndLable];
    [self addSubview:self.liveEndImageView];
    
    [self addSubview:self.liveDetailTimeLable];
    [self addSubview:self.dividingLineView];
    [self addSubview:self.liveDurationTimeLable];
    [self addSubview:self.detailTimeTitleLable];
    [self addSubview:self.durationTimeTitleLable];
}

#pragma mark Getter & Setter

- (UIButton *)finishButton {
    if (!_finishButton) {
        _finishButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _finishButton.layer.cornerRadius = 25;
        _finishButton.layer.masksToBounds = YES;
        [_finishButton setTitle:PLVLocalizedString(@"确定") forState:UIControlStateNormal];
        [_finishButton addTarget:self action:@selector(finishButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [_finishButton.layer insertSublayer:self.gradientLayer atIndex:0];
    }
    return _finishButton;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)PLV_UIColorFromRGB(@"#0080FF").CGColor, (__bridge id)PLV_UIColorFromRGB(@"#3399FF").CGColor];
        _gradientLayer.locations = @[@0.5, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
    }
    return _gradientLayer;
}

- (UIView *)dividingLineView {
    if (!_dividingLineView) {
        _dividingLineView = [[UIView alloc] init];
        _dividingLineView.backgroundColor = PLV_UIColorFromRGBA(@"#FFFFFF",0.2);
    }
    return _dividingLineView;
}

- (UILabel *)liveEndLable {
    if (!_liveEndLable) {
        _liveEndLable = [[UILabel alloc] init];
        _liveEndLable.text = PLVLocalizedString(@"直播已结束");
        _liveEndLable.font = [UIFont fontWithName:@"PingFangSC-Regular" size:24];
        _liveEndLable.textAlignment = NSTextAlignmentCenter;
        [_liveEndLable setTextColor:PLV_UIColorFromRGB(@"#F0F1F5")];
    }
    return _liveEndLable;
}

- (UIImageView *)liveEndImageView {
    if (!_liveEndImageView) {
        _liveEndImageView = [[UIImageView alloc] initWithImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_live_end"]];
    }
    return _liveEndImageView;
}

- (UILabel *)liveDetailTimeLable {
    if (!_liveDetailTimeLable) {
        _liveDetailTimeLable = [[UILabel alloc] init];
        _liveDetailTimeLable.text = @"00:00:00～00:00:00";
        _liveDetailTimeLable.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:16];
        [_liveDetailTimeLable setTextColor:PLV_UIColorFromRGB(@"#F0F1F5")];
        _liveDetailTimeLable.textAlignment = NSTextAlignmentCenter;
    }
    return _liveDetailTimeLable;
}

- (UILabel *)liveDurationTimeLable {
    if (!_liveDurationTimeLable) {
        _liveDurationTimeLable = [[UILabel alloc] init];
        _liveDurationTimeLable.text = @"00:00:00";
        _liveDurationTimeLable.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:16];
        [_liveDurationTimeLable setTextColor:PLV_UIColorFromRGB(@"#F0F1F5")];
        _liveDurationTimeLable.textAlignment = NSTextAlignmentCenter;
    }
    return _liveDurationTimeLable;
}

- (UILabel *)detailTimeTitleLable {
    if (!_detailTimeTitleLable) {
        _detailTimeTitleLable = [[UILabel alloc] init];
        _detailTimeTitleLable.text = PLVLocalizedString(@"直播时间");
        _detailTimeTitleLable.textAlignment = NSTextAlignmentCenter;
        _detailTimeTitleLable.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        [_detailTimeTitleLable setTextColor:PLV_UIColorFromRGB(@"#F0F1F5")];
    }
    return _detailTimeTitleLable;
}

- (UILabel *)durationTimeTitleLable {
    if (!_durationTimeTitleLable) {
        _durationTimeTitleLable = [[UILabel alloc] init];
        _durationTimeTitleLable.text = PLVLocalizedString(@"直播时长");
        _durationTimeTitleLable.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        [_durationTimeTitleLable setTextColor:PLV_UIColorFromRGB(@"#F0F1F5")];
        _durationTimeTitleLable.textAlignment = NSTextAlignmentCenter;
    }
    return _durationTimeTitleLable;
}

- (void)setDuration:(NSTimeInterval)duration {
     _duration = duration;
    NSString *durTimeString = [NSString stringWithFormat:@"%02ld:%02ld:%02ld", lround(floor(duration)) / 3600, lround(floor(duration / 60)) % 60, lround(floor(duration)) % 60];
    self.liveDurationTimeLable.text = durTimeString;
}

- (void)setStartTime:(NSTimeInterval)startTime {
    _startTime = startTime;
    NSTimeInterval endTime = _startTime + _duration;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"HH:mm:ss";
    NSDate *startTimeDate = [NSDate dateWithTimeIntervalSince1970:startTime];
    NSDate *endTimeDate = [NSDate dateWithTimeIntervalSince1970:endTime];
    NSString *startTimeString = [formatter stringFromDate:startTimeDate];
    NSString *endTimeString = [formatter stringFromDate:endTimeDate];

    self.liveDetailTimeLable.text = [NSString stringWithFormat:@"%@~%@", startTimeString, endTimeString];
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)finishButtonAction:(id)sender {
    if (self.finishButtonHandler) {
        self.finishButtonHandler();
    }
}

@end
