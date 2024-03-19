//
//  PLVToast.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/1.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVToast.h"

static CGFloat kToastLabelFontSize = 14.0;
static CGFloat kToastHideDelay = 2.0;

static CGFloat kToastMaxWidth = 196.0;
static CGFloat kToastMaxHeight = 80.0;
static CGFloat kToastPadMaxWidth = 300.0;

/// 确认按钮用到的回调类型
typedef void (^PLVToastCountdownAction)(void);

@interface PLVToast ()

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, weak) NSTimer *hideDelayTimer;
@property (nonatomic, assign) NSTimeInterval countdown; //倒计时长
@property (nonatomic, copy) NSString *message; //显示文本
@property (nonatomic, copy, nullable) PLVToastCountdownAction finishHandler; // 倒计时结束时响应时执行回调

@end

@implementation PLVToast

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0x1b/255.0 green:0x20/255.0 blue:0x2d/255.0 alpha:0.6];
        
        [self addSubview:self.label];
    }
    return self;
}

#pragma mark - Getter

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.font = [UIFont systemFontOfSize:kToastLabelFontSize];
        _label.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1.0];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.numberOfLines = 4;
        _label.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _label;
}

#pragma mark - Show & Hide

+ (void)showToastWithMessage:(NSString *)message inView:(UIView *)view {
    [self showToastWithMessage:message inView:view afterDelay:kToastHideDelay];
}

+ (void)showToastWithMessage:(NSString *)message inView:(UIView *)view afterDelay:(CGFloat)delay {
    if (!message ||
        ![message isKindOfClass:[NSString class]] ||
        message.length == 0 ||
        !view) {
        return;
    }
    
    PLVToast *toast = [[PLVToast alloc] init];
    [toast showMessage:message];
    [view addSubview:toast];
    
    CGPoint superViewCenter = CGPointMake(view.bounds.size.width / 2.0, view.bounds.size.height / 2.0);
    toast.center = superViewCenter;
    [toast hideAfterDelay:delay];
}

+ (void)showToastWithCountMessage:(NSString *)message inView:(UIView *)view afterCountdown:(CGFloat)countdown finishHandler:(void(^)(void))finishHandler {
    if (!message ||
        ![message isKindOfClass:[NSString class]] ||
        message.length == 0 ||
        !view) {
        return;
    }
    
    if (countdown < 1) {
        return;
    }
    
    PLVToast *toast = [[PLVToast alloc] init];
    toast.countdown = floor(countdown);
    toast.message = message;
    toast.finishHandler = finishHandler;
    [toast showCountdownMessage];
    [view addSubview:toast];
    
    CGPoint superViewCenter = CGPointMake(view.bounds.size.width / 2.0, view.bounds.size.height / 2.0);
    toast.center = superViewCenter;
    [toast hideAfterCountdown:toast.countdown];
}

- (void)showMessage:(NSString *)message {
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat maxWidth = isPad ? kToastPadMaxWidth : kToastMaxWidth;
    CGSize messageSize = [message boundingRectWithSize:CGSizeMake(maxWidth, kToastMaxHeight)
                                               options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                            attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:kToastLabelFontSize]}
                                               context:nil].size;
    self.label.text = message;
    
    if (messageSize.height > 20) {
        self.layer.cornerRadius = 8.0;
        self.label.textAlignment = NSTextAlignmentLeft;
        self.label.frame = CGRectMake(16, 10, messageSize.width, messageSize.height);
        self.frame = CGRectMake(0, 0, messageSize.width + 16 * 2, messageSize.height + 10 * 2);
    } else { // 
        self.layer.cornerRadius = 20;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.frame = CGRectMake(0, 10, messageSize.width + 24 * 2, 20);
        self.frame = CGRectMake(0, 0, messageSize.width + 24 * 2, 40);
    }
}

- (void)hide {
    if (self.hideDelayTimer) {
        [self handleHideTimer];
    } else {
        [self removeFromSuperview];
    }
}

- (void)showCountdownMessage {
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat maxWidth = isPad ? kToastPadMaxWidth : kToastMaxWidth;
    NSString *countDownTime = [NSString stringWithFormat:@"（%.0fs）", self.countdown];
    NSString *toastMessage = [NSString stringWithFormat:@"%@%@", self.message, countDownTime];
    CGSize messageSize = [toastMessage boundingRectWithSize:CGSizeMake(maxWidth, kToastMaxHeight)
                                               options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                            attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:kToastLabelFontSize]}
                                               context:nil].size;
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:toastMessage];
    
    NSRange messageRange = [toastMessage rangeOfString:self.message];
    NSRange countdownRange = [toastMessage rangeOfString:countDownTime];
    UIFont *font = [UIFont systemFontOfSize:kToastLabelFontSize];
    [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.847 green:0.847 blue:0.847 alpha: 1] range:messageRange];
    [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:1 green:0.725 blue:0.247 alpha: 1] range:countdownRange];
    [attributedText addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, attributedText.length)];
    self.label.attributedText = attributedText;
    
    if (messageSize.height > 20) {
        self.layer.cornerRadius = 8.0;
        self.label.textAlignment = NSTextAlignmentLeft;
        self.label.frame = CGRectMake(16, 10, messageSize.width, messageSize.height);
        self.frame = CGRectMake(0, 0, messageSize.width + 16 * 2, messageSize.height + 10 * 2);
    } else { //
        self.layer.cornerRadius = 20;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.frame = CGRectMake(0, 10, messageSize.width + 24 * 2, 20);
        self.frame = CGRectMake(0, 0, messageSize.width + 24 * 2, 40);
    }
}

- (void)updateCountdownMessage {
    NSString *countDownTime = [NSString stringWithFormat:@"（%.0fs）", self.countdown];
    NSString *toastMessage = [NSString stringWithFormat:@"%@%@", self.message, countDownTime];
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:toastMessage];
    
    NSRange messageRange = [toastMessage rangeOfString:self.message];
    NSRange countdownRange = [toastMessage rangeOfString:countDownTime];
    UIFont *font = [UIFont systemFontOfSize:kToastLabelFontSize];
    [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.847 green:0.847 blue:0.847 alpha: 1] range:messageRange];
    [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:1 green:0.725 blue:0.247 alpha: 1] range:countdownRange];
    [attributedText addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, attributedText.length)];
    self.label.attributedText = attributedText;
}

- (void)hideAfterDelay:(NSTimeInterval)delay {
    [self.hideDelayTimer invalidate];

    NSTimer *timer = [NSTimer timerWithTimeInterval:delay target:self selector:@selector(handleHideTimer) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.hideDelayTimer = timer;
}

- (void)handleHideTimer {
    [self removeFromSuperview];
    [self.hideDelayTimer invalidate];
    self.hideDelayTimer = nil;
}

- (void)hideAfterCountdown:(NSTimeInterval)countdown {
    [self.hideDelayTimer invalidate];

    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(handleCountDownTimer) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.hideDelayTimer = timer;
}

- (void)handleCountDownTimer {
    self.countdown--;
    if (self.countdown <= 0) {
        [self removeFromSuperview];
        [self.hideDelayTimer invalidate];
        self.hideDelayTimer = nil;
        if (self.finishHandler) {
            self.finishHandler();
        }
    } else {
        [self updateCountdownMessage];
    }
}


@end
