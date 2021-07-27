//
//  PLVLCMediaCountdownTimeView.m
//  PLVLiveScenesDemo
//
//  Created by PLV on 2020/11/13.
//  Copyright © 2020 PLV. All rights reserved.
//  直播间开播时间倒计时视图

#import "PLVLCMediaCountdownTimeView.h"
#import <PLVFoundationSDK/PLVColorUtil.h>

@interface PLVLCMediaCountdownTimeView()

#pragma mark UI

@property (nonatomic, strong) UILabel *lbCountdown;

@end

@implementation PLVLCMediaCountdownTimeView

#pragma mark - [ Life Period ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.lbCountdown.frame = CGRectMake(0, self.timeTopPadding, CGRectGetWidth(self.bounds),
                                        CGRectGetHeight(self.bounds) - self.timeTopPadding);
}

#pragma mark - [ Public Methods ]

- (void)setTime:(NSTimeInterval)time {
    _time = time;
    
    NSInteger daySeconds = 3600 * 24;
    NSInteger day = time / daySeconds;
    NSInteger hour = (time - day * daySeconds) / 3600;
    NSInteger min = (time - day * daySeconds - hour * 3600) / 60;
    NSInteger sec = time - day * daySeconds - hour * 3600 - min * 60;
    
    NSMutableString *timeStr = [NSMutableString new];
    [timeStr appendString:@"倒计时："];
    if (day > 0)
        [timeStr appendFormat:@"%@天 ", [NSString stringWithFormat:day < 10 ? @"0%ld" : @"%ld", day]];
    
    if (day > 0 || hour > 0)
        [timeStr appendFormat:@"%@小时 ", [NSString stringWithFormat:hour < 10 ? @"0%ld" : @"%ld", hour]];
    
    if (day > 0 || hour > 0 || min > 0)
        [timeStr appendFormat:@"%@分 ", [NSString stringWithFormat:min < 10 ? @"0%ld" : @"%ld", min]];
    
    [timeStr appendFormat:@"%@秒", [NSString stringWithFormat:sec < 10 ? @"0%ld" : @"%ld", sec]];
    
    self.lbCountdown.text = timeStr;
}

- (void)setTimeTopPadding:(CGFloat)timeTopPadding
{
    _timeTopPadding = timeTopPadding;
    [self layoutIfNeeded];
}

#pragma mark - [ Private Methods ]
- (void)setupUI{
    self.backgroundColor = [PLVColorUtil colorFromHexString:@"#6DA7FF"];
    [self addSubview:self.lbCountdown];
}

- (UILabel *)lbCountdown {
    if (! _lbCountdown) {
        _lbCountdown = [UILabel new];
        _lbCountdown.font = [UIFont fontWithName:@"PingFang SC" size:15];
        _lbCountdown.textColor = [UIColor whiteColor];
        _lbCountdown.textAlignment = NSTextAlignmentCenter;
    }
    
    return _lbCountdown;
}

@end
