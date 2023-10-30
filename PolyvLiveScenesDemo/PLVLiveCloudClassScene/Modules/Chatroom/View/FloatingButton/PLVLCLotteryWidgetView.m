//
//  PLVLCLotteryWidgetView.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/7/10.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVLCLotteryWidgetView.h"
#import "PLVLCLotteryWidgetPopupView.h"
#import "PLVLCUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVLCLotteryWidgetView ()

#pragma mark 数据
@property (nonatomic, strong) NSTimer *countdownTimer;
@property (nonatomic, assign) NSTimeInterval countdownInterval;
@property (nonatomic, assign) CGSize widgetSize;
@property (nonatomic, copy) NSString *eventName;

#pragma mark UI
@property (nonatomic, strong) UIImageView *lotteryImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) PLVLCLotteryWidgetPopupView *widgetPopupView;

@end

@implementation PLVLCLotteryWidgetView

#pragma mark - [ Life Cycle ]

- (void)dealloc {
    [self stopCountdownTimer];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    CGSize popupViewSize = [self.widgetPopupView.titleLabel sizeThatFits:CGSizeMake(MAXFLOAT, 16)];
    CGFloat popupViewWidth = popupViewSize.width + 16 + (fullScreen ? 0 : 10);
    CGFloat popupViewHeight = 34;
    if (!fullScreen) { // 竖屏
        self.lotteryImageView.frame = CGRectMake(0, self.titleLabel.isHidden ? 12 : 0, self.widgetSize.width, self.widgetSize.width);
        self.widgetPopupView.frame = CGRectMake(- popupViewWidth - 7, CGRectGetMidY(self.lotteryImageView.frame) - popupViewHeight/2, popupViewWidth, popupViewHeight);
    }else{ // 横屏
        self.lotteryImageView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetWidth(self.bounds));
        self.widgetPopupView.frame = CGRectMake((CGRectGetWidth(self.frame) - popupViewWidth)/2, - popupViewHeight - 3, popupViewWidth, popupViewHeight);
    }
    [self.widgetPopupView setPopupViewDirection:fullScreen ? PLVLCLotteryWidgetPopupDirectionTop : PLVLCLotteryWidgetPopupDirectionLeft];
    self.titleLabel.frame = CGRectMake(-10, CGRectGetMaxY(self.lotteryImageView.frame) + 2, self.widgetSize.width + 20, 12);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hidden = YES;
        self.widgetSize = CGSizeMake(40.0, 40.0 + 2.0 + 12.0);
        [self addSubview:self.lotteryImageView];
        [self addSubview:self.titleLabel];
        [self addSubview:self.widgetPopupView];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(widgetTapAction)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

#pragma mark - [ Public Methods ]
- (void)updateLotteryWidgetInfo:(NSDictionary *)dict {
    NSString *eventName = PLV_SafeStringForDictKey(dict, @"event");
    self.eventName = eventName;
    if ([eventName isEqualToString:@"CLICK_LOTTERY_PENDANT"]) {
        BOOL isShow = PLV_SafeBoolForDictKey(dict, @"isShow");
        self.hidden = !isShow;
        if (self.delegate && [self.delegate respondsToSelector:@selector(lotteryWidgetView:showStatusChanged:)]) {
            [self.delegate lotteryWidgetView:self showStatusChanged:isShow];
        }
        if (!isShow) {
            [self hideWidgetView];
            return;
        }
        
        NSString *iconUrl = PLV_SafeStringForDictKey(dict, @"iconUrl");
        NSString *status = PLV_SafeStringForDictKey(dict, @"status");
        if ([PLVFdUtil checkStringUseable:iconUrl]) {
            [self.lotteryImageView sd_setImageWithURL:[NSURL URLWithString:iconUrl]];
        } else {
            UIImage *image = [PLVLCUtils imageForChatroomResource:PLVLocalizedString(@"plvlc_chatroom_lottery_widget_icon")];
            [self.lotteryImageView setImage:image];
        }
        if ([status isEqualToString:@"delayTime"]) {
            // delayTime:倒计时状态（需要显示倒计时时间）
            self.countdownInterval = PLV_SafeIntegerForDictKey(dict, @"delayTime");
            self.titleLabel.text = [PLVFdUtil secondsToString2:self.countdownInterval];
            if (!_countdownTimer) {
                [self startCountdownTimer];
            }
        } else {
            [self stopCountdownTimer];
            self.countdownInterval = 0;
            if ([status isEqualToString:@"running"]) {
                self.titleLabel.text = PLVLocalizedString(@"开奖中");
            } else if ([status isEqualToString:@"over"]) {
                self.titleLabel.text = PLVLocalizedString(@"已开奖");
            }
        }
    }
}

- (void)hideWidgetView {
    self.hidden = YES;
    [self stopCountdownTimer];
    [self hidePopupView];
}

- (void)hidePopupView {
    self.widgetPopupView.hidden = YES;
}

#pragma mark - [ Private Method ]
- (void)startCountdownTimer {
    if (_countdownTimer) { [self stopCountdownTimer]; }
    _countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(countdownTimerEvent:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_countdownTimer forMode:NSRunLoopCommonModes];
}

- (void)stopCountdownTimer{
    if (_countdownTimer) {
        [_countdownTimer invalidate];
        _countdownTimer = nil;
    }
}

- (void)showWidgetPopupViewWithTitle:(NSString *)title {
    if ([PLVFdUtil checkStringUseable:title]) {
        [self.widgetPopupView setPopupViewTitle:title];
        [self setNeedsLayout];
    }
    if (!self.widgetPopupView.hidden) {
        return;
    }
    self.widgetPopupView.hidden = NO;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.widgetPopupView.hidden = YES;
    });
    if (self.delegate && [self.delegate respondsToSelector:@selector(lotteryWidgetViewPopupViewDidShow:)]) {
        [self.delegate lotteryWidgetViewPopupViewDidShow:self];
    }
}

#pragma mark Getter
- (UIImageView *)lotteryImageView {
    if (!_lotteryImageView) {
        _lotteryImageView = [[UIImageView alloc] init];
    }
    return _lotteryImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:10];
        _titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (PLVLCLotteryWidgetPopupView *)widgetPopupView {
    if (!_widgetPopupView) {
        _widgetPopupView = [[PLVLCLotteryWidgetPopupView alloc] init];
        _widgetPopupView.hidden = YES;
    }
    return _widgetPopupView;
}

#pragma mark - [ Event ]
#pragma mark Timer
- (void)countdownTimerEvent:(NSTimer *)timer {
    self.countdownInterval -= 1;
    if (self.countdownInterval < 0) {
        [self hidePopupView];
        [self stopCountdownTimer];
        return;
    }
    if (self.countdownInterval <= 3) {
        [self showWidgetPopupViewWithTitle:PLVLocalizedString(@"抽奖即将开始")];
    }
    self.titleLabel.text = [PLVFdUtil secondsToString2:self.countdownInterval];
}

#pragma mark Action
- (void)widgetTapAction {
    if (self.countdownInterval > 3) {
        [self showWidgetPopupViewWithTitle:PLVLocalizedString(@"抽奖暂未开始")];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(lotteryWidgetViewDidClickAction:eventName:)]) {
        [self.delegate lotteryWidgetViewDidClickAction:self eventName:self.eventName];
    }
}

@end
