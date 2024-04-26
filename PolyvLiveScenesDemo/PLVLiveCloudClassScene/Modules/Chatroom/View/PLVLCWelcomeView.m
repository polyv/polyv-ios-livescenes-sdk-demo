//
//  PLVLCWelcomeView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/10/12.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCWelcomeView.h"
#import "PLVLCUtils.h"
#import "PLVMultiLanguageManager.h"

@interface PLVLCWelcomeView ()

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *marqueeLabel;
@property (nonatomic, strong) UIImageView *leftStarsImageView;
@property (nonatomic, strong) UIImageView *rightStarsImageView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end

@implementation PLVLCWelcomeView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.clipsToBounds = YES;
        self.hidden = YES;
        
        [self addSubview:self.contentView];
        [self.contentView addSubview:self.marqueeLabel];
        [self.contentView addSubview:self.leftStarsImageView];
        [self.contentView addSubview:self.rightStarsImageView];
        [self.layer insertSublayer:self.gradientLayer atIndex:0];
    }
    return self;
}

#pragma mark - Getter & Setter

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = [UIColor clearColor];
    }
    return _contentView;
}

- (UILabel *)marqueeLabel {
    if (!_marqueeLabel) {
        _marqueeLabel = [[UILabel alloc] init];
        _marqueeLabel.textAlignment = NSTextAlignmentLeft;
        _marqueeLabel.textColor = [UIColor whiteColor];
        _marqueeLabel.font = [UIFont systemFontOfSize:14];
    }
    return _marqueeLabel;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.startPoint = CGPointMake(0, 0.5);
        _gradientLayer.endPoint = CGPointMake(1, 0.5);
        _gradientLayer.colors = @[(__bridge id)[UIColor colorWithRed:228/255.0 green:158/255.0 blue:37/255.0 alpha:0.0].CGColor, (__bridge id)[UIColor colorWithRed:222/255.0 green:153/255.0 blue:33/255.0 alpha:0.9].CGColor, (__bridge id)[UIColor colorWithRed:222/255.0 green:153/255.0 blue:33/255.0 alpha:0.9].CGColor, (__bridge id)[UIColor colorWithRed:228/255.0 green:158/255.0 blue:37/255.0 alpha:0.0].CGColor];
        _gradientLayer.locations = @[@(0), @(0.3f), @(0.7f), @(1.0f)];
        
    }
    return _gradientLayer;
}

- (UIImageView *)leftStarsImageView {
    if (!_leftStarsImageView) {
        _leftStarsImageView = [[UIImageView alloc] initWithImage:[PLVLCUtils imageForChatroomResource:@"plvlc_chatroom_stars_left"]];
    }
    return _leftStarsImageView;
}

- (UIImageView *)rightStarsImageView {
    if (!_rightStarsImageView) {
        _rightStarsImageView = [[UIImageView alloc] initWithImage:[PLVLCUtils imageForChatroomResource:@"plvlc_chatroom_stars_right"]];
    }
    return _rightStarsImageView;
}

#pragma mark - Public Method

- (void)showWelcomeWithNickName:(NSString *)nickName {
    if (!nickName || ![nickName isKindOfClass:[NSString class]] || nickName.length == 0) {
        return;
    }
    
    NSString *welcomeMessage = [NSString stringWithFormat:PLVLocalizedString(@"欢迎%@加入"), nickName];
    self.marqueeLabel.text = welcomeMessage;
    
    [self beginAnimation];
}

#pragma mark - Pravite Method

- (void)beginAnimation {
    self.hidden = NO;
    
    self.contentView.frame = self.bounds;
    self.gradientLayer.frame = self.contentView.bounds;
    
    CGFloat padding = 64 + 16;
    CGFloat maxLabelWidth = self.bounds.size.width - padding;
    CGFloat labelWidth = [self.marqueeLabel sizeThatFits:CGSizeMake(MAXFLOAT, 24)].width;
    
    if (labelWidth > maxLabelWidth) {
        labelWidth = maxLabelWidth;
    }
        
    CGRect contentViewRect = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    contentViewRect.origin.x += contentViewRect.size.width;
    self.contentView.frame = contentViewRect;
    self.marqueeLabel.frame = CGRectMake(CGRectGetMidX(self.contentView.bounds) - labelWidth / 2, 0, labelWidth, 24);
    self.leftStarsImageView.frame = CGRectMake(CGRectGetMinX(self.marqueeLabel.frame) - 8 - 16, (CGRectGetHeight(self.bounds) - 15) / 2, 16, 15);
    self.rightStarsImageView.frame = CGRectMake(CGRectGetMaxX(self.marqueeLabel.frame) + 8, CGRectGetMinY(self.leftStarsImageView.frame), 16, 15);

    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:2.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.contentView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    } completion:nil];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(animationFinish) object:nil];
    [self performSelector:@selector(animationFinish) withObject:nil afterDelay:4.0];
}

- (void)animationFinish {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:2.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect contentViewRect = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
        contentViewRect.origin.x -= contentViewRect.size.width;
        weakSelf.contentView.frame = contentViewRect;
    } completion:^(BOOL finished) {
        weakSelf.hidden = YES;
    }];
}

@end
