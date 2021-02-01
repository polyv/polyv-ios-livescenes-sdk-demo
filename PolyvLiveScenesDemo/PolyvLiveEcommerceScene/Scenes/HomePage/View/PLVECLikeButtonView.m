//
//  PLVECLikeButtonView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2021/1/21.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVECLikeButtonView.h"
#import "PLVECUtils.h"
#import <PolyvFoundationSDK/PLVColorUtil.h>

@interface PLVECLikeButtonView ()

@property (nonatomic, strong) UIButton *likeButton;

@property (nonatomic, strong) UILabel *likeCountLabel;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation PLVECLikeButtonView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.likeButton];
        [self addSubview:self.likeCountLabel];
    }
    return self;
}

- (void)layoutSubviews {
    self.likeButton.frame = CGRectMake(4, 0, 42, 42);
    self.likeCountLabel.frame = CGRectMake(0, CGRectGetMaxY(self.likeButton.frame) + 3, 50, 12);
}

#pragma mark - Getter & Setter

- (UIButton *)likeButton {
    if (!_likeButton) {
        _likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_likeButton addTarget:self action:@selector(likeAction:) forControlEvents:UIControlEventTouchUpInside];
        UIImage *image = [PLVECUtils imageForWatchResource:@"plv_like_btn"];
        [_likeButton setImage:image forState:UIControlStateNormal];
    }
    return _likeButton;
}

- (UILabel *)likeCountLabel {
    if (!_likeCountLabel) {
        _likeCountLabel = [[UILabel alloc] init];
        _likeCountLabel.textAlignment = NSTextAlignmentCenter;
        _likeCountLabel.textColor = [UIColor whiteColor];
        _likeCountLabel.font = [UIFont systemFontOfSize:12];
    }
    return _likeCountLabel;
}

- (void)setLikeCount:(NSUInteger)likeCount {
    _likeCount = likeCount;
    NSString *string = nil;
    if (likeCount <= 0) {
        string = @"";
    } else if (likeCount > 9999) {
        string = [NSString stringWithFormat:@"%.1fw", likeCount/10000.0];
    } else {
        string = [NSString stringWithFormat:@"%zd", likeCount];
    }
    self.likeCountLabel.text = string;
}

#pragma mark - Action

- (void)likeAction:(id)sender {
    if (self.didTapLikeButton) {
        self.didTapLikeButton();
    }
    [self likeAnimation];
}

#pragma mark - Public

- (void)showLikeAnimation {
    [self likeAnimation];
}

#pragma mark - Private Method

- (void)likeAnimation {
    UIImage *heartImage = [PLVECUtils imageForWatchResource:[NSString stringWithFormat:@"plv_like_heart%@_img",@(rand()%4)]];
    if (!heartImage) {
        return;
    }
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:heartImage];
    imageView.frame = CGRectMake(5.0, 5.0, 18.0, 15.0);
    [imageView setContentMode:UIViewContentModeCenter];
    imageView.clipsToBounds = YES;
    [self.likeButton addSubview:imageView];
    
    CGFloat finishX = round(random() % 84) - 84 + (CGRectGetWidth(self.bounds) - CGRectGetMinX(self.likeButton.frame));
    CGFloat speed = 1.0 / round(random() % 900) + 0.6;
    NSTimeInterval duration = 4.0 * speed;
    if (duration == INFINITY) {
        duration = 2.412346;
    }
    
    [UIView animateWithDuration:duration animations:^{
        imageView.alpha = 0.0;
        imageView.frame = CGRectMake(finishX, - 180, 30.0, 30.0);
    } completion:^(BOOL finished) {
        [imageView removeFromSuperview];
    }];
}

#pragma mark - Timer

- (void)startTimer {
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
    }
}

- (void)invalidTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)timerAction {
    for (int i = 0; i < rand()%4 + 1; i++) {
        [self likeAnimation];
    }
}

@end
