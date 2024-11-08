//
//  PLVSACountDownView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSACountDownView.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVSACountDownView ()

@property (nonatomic, strong) UIView *customMaskView;
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, assign) NSInteger countDownTime;

@end

@implementation PLVSACountDownView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.customMaskView];
        [self addSubview:self.bubbleView];
        [self.bubbleView addSubview:self.countLabel];

    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.customMaskView.frame = self.bounds;
    self.bubbleView.frame = CGRectMake(0, 0, 100, 100);
    self.bubbleView.center = self.customMaskView.center;
    self.countLabel.frame = CGRectMake(0, 0, 100, 100);
}

#pragma mark - [ Public Method ]

- (void)startCountDown {
    self.countDownTime = 3;
    [self countDown];
}

#pragma mark - [ Private Method ]

- (void)countDown {
    self.countLabel.text = [NSString stringWithFormat:@"%zd",self.countDownTime];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.countDownTime --;
        if (self.countDownTime > 0) {
            [self countDown];
        } else {
            [UIView animateWithDuration:0.3 animations:^{
                self.alpha = 0;
            } completion:^(BOOL finished) {
                if (self.countDownCompletedHandler) {
                    self.countDownCompletedHandler();
                }
            }];
        }
    });
}

#pragma mark Getter

- (UIView *)customMaskView {
    if (!_customMaskView) {
        _customMaskView = [[UIView alloc] init];
        _customMaskView.backgroundColor = PLV_UIColorFromRGBA(@"#000000", 0.5);
    }
    return _customMaskView;
}

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = PLV_UIColorFromRGBA(@"#000000", 0.4);
        _bubbleView.layer.masksToBounds = YES;
        _bubbleView.layer.cornerRadius = 50;
    }
    return _bubbleView;
}

- (UILabel *)countLabel {
    if (!_countLabel) {
        _countLabel = [[UILabel alloc] init];
        _countLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:48];
        _countLabel.textColor = [UIColor whiteColor];
        _countLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _countLabel;
}

@end
