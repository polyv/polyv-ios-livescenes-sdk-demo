//
//  PLVECRedpackButtonView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/1/11.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVECRedpackButtonView.h"
#import "PLVECRedpackButtonPopupView.h"
#import "PLVECUtils.h"
#import "PLVMultiLanguageManager.h"

// 点击红包按钮弹出气泡显示时长
static NSInteger kPopupViewShowInterval = 6.0;

@interface PLVECRedpackButtonView ()

/// UI
@property (nonatomic, strong) UIButton *redpackButton;
@property (nonatomic, strong) UILabel *countdownLabel; // 倒计时文本
@property (nonatomic, strong) PLVECRedpackButtonPopupView *popupView; // 点击后弹出气泡
@property (nonatomic, assign) BOOL isLandscape; // 是否处于横屏状态

/// 数据
@property (nonatomic, assign) PLVRedpackMessageType redpackType; // 红包类型
@property (nonatomic, strong) NSTimer *popupTimer; // 弹出气泡倒计时
@property (nonatomic, assign) NSInteger popupShowTime; // 气泡显示时长，单位秒

@end

@implementation PLVECRedpackButtonView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hidden = YES;
        
        self.redpackType = PLVRedpackMessageTypeUnknown;
        
        [self addSubview:self.redpackButton];
        [self addSubview:self.countdownLabel];
    }
    return self;
}

- (void)layoutSubviews {
    BOOL isLandscape = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    BOOL isDeviceOrientationChanged = (isLandscape != self.isLandscape);
    if (isDeviceOrientationChanged) { // 横竖屏切换时隐藏弹出气泡
        [_popupView removeFromSuperview];
        _popupView = nil;
    }
    
    self.isLandscape = isLandscape;
    if (self.isLandscape) { // 横屏
        self.countdownLabel.hidden = YES;
        CGFloat viewWidth = CGRectGetWidth(self.bounds);
        self.redpackButton.frame = CGRectMake(-5, -5, viewWidth + 10, viewWidth + 10);
    } else { // 竖屏
        self.countdownLabel.hidden = NO;
        self.redpackButton.frame = CGRectMake(0, 0, PLVECRedpackButtonViewWidth, PLVECRedpackButtonViewWidth);
        self.countdownLabel.frame = CGRectMake(0, PLVECRedpackButtonViewWidth, PLVECRedpackButtonViewWidth, 12);
    }
}

#pragma mark - [ Public Method ]

- (void)showWithRedpackMessageType:(PLVRedpackMessageType)redpackMessageType delayTime:(NSInteger)delayTime {
    self.redpackType = redpackMessageType;
    
    UIImage *image = [self redpackImageWithRedpackType:redpackMessageType];
    [self.redpackButton setImage:image forState:UIControlStateNormal];
    self.countdownLabel.text =  [self countDownStringWithDelayTime:delayTime];
    
    self.hidden = NO;
}

- (void)dismiss {
    self.hidden = YES;
    
    [_popupView removeFromSuperview];
    _popupView = nil;
}

#pragma mark - [ Private Method ]

- (UIImage *)redpackImageWithRedpackType:(PLVRedpackMessageType)type {
    UIImage *image = nil;
    switch (type) {
        case PLVRedpackMessageTypeUnknown:
            image = [PLVECUtils imageForWatchResource:PLVLocalizedString(@"plvec_chatroom_delay_password_redpack")];
            break;
        case PLVRedpackMessageTypeAliPassword:
            image = [PLVECUtils imageForWatchResource:PLVLocalizedString(@"plvec_chatroom_delay_password_redpack")];
            break;
    }
    return image;
}

- (NSString *)countDownStringWithDelayTime:(NSInteger)delayTime {
    if (delayTime <= 0) {
        return @"";
    } else if (delayTime < 60) {
        NSString *string = [NSString stringWithFormat:@"00:%02zd", delayTime];
        return string;
    } else if (delayTime < 3600) {
        NSInteger min = delayTime / 60;
        NSInteger sec = delayTime % 60;
        NSString *string = [NSString stringWithFormat:@"%02zd:%02zd", min, sec];
        return string;
    } else {
        return @"59:59";
    }
}

- (NSString *)popupLabelStringWithRedpackType:(PLVRedpackMessageType)type {
    NSString *labelString = @"";
    switch (type) {
        case PLVRedpackMessageTypeUnknown:
            labelString = PLVLocalizedString(@"倒计时红包即将来袭");
            break;
        case PLVRedpackMessageTypeAliPassword:
            labelString = PLVLocalizedString(@"口令红包即将来袭");
            break;
    }
    return labelString;
}

- (void)startPopupTimer {
    if (_popupTimer) {
        [self stopPopupTimer];
    }
    
    self.popupShowTime = kPopupViewShowInterval;
    self.popupTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                       target:self
                                                     selector:@selector(popupTimerAction)
                                                     userInfo:nil
                                                      repeats:YES];
}

- (void)stopPopupTimer {
    [_popupTimer invalidate];
    _popupTimer = nil;
}

#pragma mark Getter & Setter

- (UIButton *)redpackButton {
    if (!_redpackButton) {
        _redpackButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [self redpackImageWithRedpackType:PLVRedpackMessageTypeUnknown];
        [_redpackButton setImage:image forState:UIControlStateNormal];
        [_redpackButton addTarget:self action:@selector(redpackButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _redpackButton;
}

- (UILabel *)countdownLabel {
    if (!_countdownLabel) {
        _countdownLabel = [[UILabel alloc] init];
        _countdownLabel.textAlignment = NSTextAlignmentCenter;
        _countdownLabel.textColor = [UIColor colorWithWhite:1 alpha:0.8];
        _countdownLabel.font = [UIFont systemFontOfSize:12];
        _countdownLabel.backgroundColor = [PLVColorUtil colorFromHexString:@"#202127" alpha:0.8];
        _countdownLabel.layer.cornerRadius = 8.0;
        _countdownLabel.layer.masksToBounds = YES;
    }
    return _countdownLabel;
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)redpackButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(didTpaRedpackButtonView:)]) {
        [self.delegate didTpaRedpackButtonView:self];
    }
    
    if (self.popupView && self.popupView.superview) {
        return;
    }
    
    NSString *labelString = [self popupLabelStringWithRedpackType:self.redpackType];
    self.popupView = [[PLVECRedpackButtonPopupView alloc] initWithLabelString:labelString];
    [self.superview addSubview:self.popupView];
    
    if (self.isLandscape) {
        // 预留以后横屏弹出气泡布局，目前横屏没提供点击交互
    } else {
        CGRect rect = self.frame;
        rect.size.width = self.popupView.caculateSize.width;
        rect.size.height = self.popupView.caculateSize.height;
        rect.origin.x -= self.popupView.caculateSize.width;
        rect.origin.y = self.center.y - self.popupView.caculateSize.height/2.0;
        self.popupView.frame = rect;
    }
    
    [self startPopupTimer];
}

- (void)popupTimerAction {
    if (--self.popupShowTime > 0) {
        return;
    }
    
    [self stopPopupTimer];
    
    [_popupView removeFromSuperview];
    _popupView = nil;
}

@end
