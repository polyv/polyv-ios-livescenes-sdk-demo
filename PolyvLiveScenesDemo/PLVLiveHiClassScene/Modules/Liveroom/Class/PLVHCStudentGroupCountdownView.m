//
//  PLVHCStudentGroupCountdownView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/10/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCStudentGroupCountdownView.h"
// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCStudentGroupCountdownView()

#pragma mark UI
#pragma mark 有标题、按钮倒计时样式
@property (nonatomic, strong) UILabel *titleLabel; // 标题
@property (nonatomic, strong) UIButton *confirmButton; // 确认按钮

#pragma mark 大字体倒计时样式
@property (nonatomic, strong) UILabel *countdownLabel; // 倒计时
@property (nonatomic, strong) UILabel *countdownContentLabel; // 大字体倒计时标题

#pragma mark 数据
@property (nonatomic, strong) dispatch_source_t countdownTimer; /// 倒计时器
@property (nonatomic, copy) PLVHCStudentGroupCountdownViewEndCallBlock endCallBlock; /// 倒计时结束时的回调

@end

@implementation PLVHCStudentGroupCountdownView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#2B2F48"];
        self.layer.cornerRadius = 16.0f;
        self.clipsToBounds = YES;
        
        [self addSubview:self.titleLabel];
        [self addSubview:self.confirmButton];
        
        [self addSubview:self.countdownLabel];
        [self addSubview:self.countdownContentLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.titleLabel.frame = CGRectMake(0, 31, CGRectGetWidth(self.bounds), 15);
    self.confirmButton.center = CGPointMake(self.titleLabel.center.x, CGRectGetMaxY(self.titleLabel.frame) + 24 + CGRectGetHeight(self.confirmButton.bounds)/2);
    
    self.countdownLabel.frame = CGRectMake(0, 26, CGRectGetWidth(self.bounds), 60);
    self.countdownContentLabel.frame = CGRectMake(0, CGRectGetMaxY(self.countdownLabel.frame) + 14, CGRectGetWidth(self.bounds), 18);
}

#pragma mark - [ Public Method ]

- (void)countdownViewEndCallback:(PLVHCStudentGroupCountdownViewEndCallBlock)callback {
    self.titleLabel.hidden = YES;
    self.confirmButton.hidden = YES;
    
    self.countdownLabel.hidden = NO;
    self.countdownContentLabel.hidden = NO;
    
    __block NSInteger countdown = 3;
    __weak typeof(self)weakSelf = self;
    dispatch_queue_t quene = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.countdownTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, quene);
    dispatch_source_set_timer(self.countdownTimer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(self.countdownTimer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (countdown == 0) {
                [weakSelf clear];
                callback ? callback() : nil;
            } else {
                weakSelf.countdownLabel.text = [NSString stringWithFormat:@"%zd", countdown];
                countdown--;
            }
        });
    });
    dispatch_resume(self.countdownTimer);
}

- (void)countdownViewWithTitleString:(NSString *)titleString confirmActionTitle:(NSString *)confirmActionTitle endCallback:(PLVHCStudentGroupCountdownViewEndCallBlock)callback {
    self.titleLabel.hidden = NO;
    self.confirmButton.hidden = NO;
    
    self.countdownLabel.hidden = YES;
    self.countdownContentLabel.hidden = YES;
    
    if ([PLVFdUtil checkStringUseable:titleString]) {
        self.titleLabel.text = titleString;
    }
    NSString *btnTitle = @"好的";
    if ([PLVFdUtil checkStringUseable:confirmActionTitle]) {
        btnTitle = confirmActionTitle;
    }
    self.endCallBlock = callback;
    
    __block NSInteger countdown = 5;
    __weak typeof(self)weakSelf = self;
    dispatch_queue_t quene = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.countdownTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, quene);
    dispatch_source_set_timer(self.countdownTimer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(self.countdownTimer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (countdown == 0) {
                [weakSelf clear];
                callback ? callback() : nil;
            } else {
                [weakSelf.confirmButton setTitle:[NSString stringWithFormat:@"%@（%lds）", btnTitle, (long)countdown] forState:UIControlStateNormal];
                countdown--;
            }
        });
    });
    dispatch_resume(self.countdownTimer);
}

- (void)clear {
    if (self.countdownTimer) {
        dispatch_source_cancel(self.countdownTimer);
        self.countdownTimer = nil;
    }
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC" size:16];;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = @"";
    }
    return _titleLabel;
}

- (UIButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _confirmButton.bounds = CGRectMake(0, 0, 126, 36);
        _confirmButton.layer.masksToBounds = YES;
        _confirmButton.layer.cornerRadius = 18.0f;
        _confirmButton.layer.borderWidth = 1.0f;
        _confirmButton.layer.borderColor = [UIColor whiteColor].CGColor;
        if (@available(iOS 8.2, *)) {
            _confirmButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        } else {
            _confirmButton.titleLabel.font = [UIFont systemFontOfSize:14];
        }
        _confirmButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_confirmButton setTitle:@"" forState:UIControlStateNormal];
        [_confirmButton addTarget:self action:@selector(confirmButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

- (UILabel *)countdownLabel {
    if (!_countdownLabel) {
        _countdownLabel = [[UILabel alloc] init];
        _countdownLabel.textColor = [UIColor whiteColor];
        if (@available(iOS 8.2, *)) {
            _countdownLabel.font = [UIFont systemFontOfSize:60 weight:UIFontWeightMedium];
        } else {
            _countdownLabel.font = [UIFont systemFontOfSize:60];
        }
        _countdownLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _countdownLabel;
}

- (UILabel *)countdownContentLabel {
    if (!_countdownContentLabel) {
        _countdownContentLabel = [[UILabel alloc] init];
        _countdownContentLabel.textColor = [UIColor whiteColor];
        if (@available(iOS 8.2, *)) {
            _countdownContentLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        } else {
            _countdownContentLabel.font = [UIFont systemFontOfSize:14];
        }
        _countdownContentLabel.textAlignment = NSTextAlignmentCenter;
        _countdownContentLabel.text = @"即将进入小组讨论";
    }
    return _countdownContentLabel;
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)confirmButtonAction {
    if (self.endCallBlock) {
        self.endCallBlock();
    }
    [self clear];
}

@end
