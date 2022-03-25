//
//  PLVLSCountDownView.m
//  PLVCloudClassStreamerDemo
//
//  Created by Lincal on 2019/10/17.
//  Copyright © 2019 PLV. All rights reserved.
//

#import "PLVLSCountDownView.h"

@interface PLVLSCountDownView ()

@property (nonatomic, strong) UILabel * countLb;
@property (nonatomic, assign) NSInteger countDownTime;

@end

@implementation PLVLSCountDownView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.alpha = 0;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        self.countDownTime = 3;
        
        [self addSubview:self.countLb];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.countLb.frame = self.bounds;
}

#pragma mark - Getter

- (UILabel *)countLb {
    if (!_countLb) {
        _countLb = [[UILabel alloc] init];
        _countLb.font = [UIFont systemFontOfSize:80];
        _countLb.textColor = [UIColor whiteColor];
        _countLb.textAlignment = NSTextAlignmentCenter;
    }
    return _countLb;
}

#pragma mark - Public Method

- (void)startCountDownOnView:(UIView *)container {
    [container addSubview:self];
    
    [self reset];
    [self countDown];
}

#pragma mark - Private Method

- (void)countDown {
    self.countLb.text = [NSString stringWithFormat:@"%ld",self.countDownTime];
    [self countDownAnimation];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.countDownTime --;
        if (self.countDownTime > 0) {
            [self countDown];
        }else{
            [self.countLb.layer removeAllAnimations];
            [UIView animateWithDuration:0.3 animations:^{
                self.alpha = 0;
            } completion:^(BOOL finished) {
                if (self.countDownCompletedBlock) { self.countDownCompletedBlock(); }
                [self removeFromSuperview];
            }];
        }
    });
}

- (void)countDownAnimation {
    [UIView animateWithDuration:0.3 delay:0 options:0 animations:^{
        self.countLb.alpha = 1;
    } completion:nil];
    
    float begin = 0.6;
    float duration = 0.95 - begin;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(begin * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:(duration - 0.1) delay:0 options:0 animations:^{
            self.countLb.alpha = 0;
        } completion:nil];
    });
    
    CABasicAnimation * scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.beginTime = CACurrentMediaTime() + begin;
    scaleAnimation.duration = duration;
    scaleAnimation.repeatCount = 1;
    scaleAnimation.removedOnCompletion = NO;
    scaleAnimation.fillMode = kCAFillModeForwards;
    scaleAnimation.fromValue = @(1.0);
    scaleAnimation.toValue = @(0.6);
    [self.countLb.layer addAnimation:scaleAnimation forKey:@"zoom"];
}

- (void)reset {
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 1;
    }];
    self.countDownTime = 3;
}

@end
