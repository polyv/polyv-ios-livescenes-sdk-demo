//
//  PLVSAFinishStreamerSheet.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/11.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAFinishStreamerSheet.h"
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVRoomDataManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat kButtonHeight = 58.0;
static CGFloat kCustomButtonHeight = 65.0;
static CGFloat kLineHeight = 1.0;

@interface PLVSAFinishStreamerSheet ()

/// UI
@property (nonatomic, strong) UIButton *finishButton;
@property (nonatomic, strong) UIButton *pauseButton;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIView *firstLine;
@property (nonatomic, strong) UIView *secondLine;

/// 其他
@property (nonatomic, copy) void(^finishHandler)(void);
@property (nonatomic, copy) void(^pauseHandler)(void);

@end

@implementation PLVSAFinishStreamerSheet

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    CGFloat bottom = [PLVSAUtils sharedUtils].areaInsets.bottom;
    self = [super initWithSheetHeight:2 * kCustomButtonHeight + kButtonHeight + 2 * kLineHeight + bottom];
    if (self) {
        [self.contentView addSubview:self.pauseButton];
        [self.contentView addSubview:self.finishButton];
        [self.contentView addSubview:self.cancelButton];
        [self.contentView addSubview:self.firstLine];
        [self.contentView addSubview:self.secondLine];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat width = self.contentView.bounds.size.width;
    
    self.pauseButton.frame = CGRectMake(0, 0, width, kCustomButtonHeight);
    self.firstLine.frame = CGRectMake(0, CGRectGetMaxY(self.pauseButton.frame), width, kLineHeight);
    self.finishButton.frame = CGRectMake(0, CGRectGetMaxY(self.firstLine.frame), width, kCustomButtonHeight);

    self.secondLine.frame = CGRectMake(0, CGRectGetMaxY(self.finishButton.frame), width, kLineHeight);
    self.cancelButton.frame = CGRectMake(0, CGRectGetMaxY(self.secondLine.frame), width, self.sheetHight - CGRectGetMaxY(self.secondLine.frame));
}

#pragma mark - [ Public Method ]

- (void)showInView:(UIView *)parentView finishAction:(void (^)(void))finishHandler pauseAction:(void (^)(void))pauseHandler {
    [super showInView:parentView];
    
    //倒计时时间
     __block NSInteger timeOut = 3;
     dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
     dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
     //每秒执行一次
     dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), 1.0 * NSEC_PER_SEC, 0);
     dispatch_source_set_event_handler(_timer, ^{
         
         //倒计时结束，关闭
         if (timeOut <= 0) {
             dispatch_source_cancel(_timer);
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self updateFinishButtonWithCountDown:timeOut];
                 self.finishButton.enabled = YES;
             });
         } else {
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self updateFinishButtonWithCountDown:timeOut];
                 self.finishButton.enabled = NO;
             });
             timeOut--;
         }
     });
     dispatch_resume(_timer);
    self.finishHandler = finishHandler;
    self.pauseHandler = pauseHandler;
}

#pragma mark - [ Private Method ]

#pragma mark Getter & Setter

- (UIButton *)finishButton {
    if (!_finishButton) {
        _finishButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _finishButton.titleLabel.numberOfLines = 2;
        [_finishButton addTarget:self action:@selector(finishButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _finishButton;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelButton setTitle:PLVLocalizedString(@"取消") forState:UIControlStateNormal];
        [_cancelButton setTitleColor:[PLVColorUtil colorFromHexString:@"#FFFFFF"] forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_cancelButton addTarget:self action:@selector(cancelButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        CGFloat bottom = [PLVSAUtils sharedUtils].areaInsets.bottom;
        if (bottom > 0) {
            _cancelButton.titleEdgeInsets = UIEdgeInsetsMake(-bottom / 2.0, 0, 0, 0);
        }
    }
    return _cancelButton;
}

- (UIButton *)pauseButton {
    if (!_pauseButton) {
        _pauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
        NSString *firstLine = PLVLocalizedString(@"暂停直播");
        NSString *secondLine = PLVLocalizedString(@"暂时退出，30分钟内可再次恢复直播");
        NSString *buttonText = [NSString stringWithFormat:@"%@\n%@", firstLine, secondLine];
        UIColor *firstLineColor = [PLVColorUtil colorFromHexString:@"#3F76FC"];
        UIColor *secondLineColor = [PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0.4];
        
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:buttonText];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 3;
        paragraphStyle.alignment = NSTextAlignmentCenter;
        
        // 设置第一行文本的属性
        NSDictionary *firstLineAttributes = @{
            NSFontAttributeName: [UIFont systemFontOfSize:16],
            NSForegroundColorAttributeName: firstLineColor,
            NSParagraphStyleAttributeName:paragraphStyle
        };
        [attributedString setAttributes:firstLineAttributes range:NSMakeRange(0, firstLine.length)];

        // 设置第二行文本的属性
        NSDictionary *secondLineAttributes = @{
            NSFontAttributeName: [UIFont systemFontOfSize:10],
            NSForegroundColorAttributeName: secondLineColor,
            NSParagraphStyleAttributeName:paragraphStyle
        };
        [attributedString setAttributes:secondLineAttributes range:NSMakeRange(firstLine.length + 1, secondLine.length)];

        // 将富文本字符串设置为按钮的标题
        [_pauseButton setAttributedTitle:attributedString forState:UIControlStateNormal];
        _pauseButton.titleLabel.numberOfLines = 2;
        [_pauseButton addTarget:self action:@selector(pauseButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _pauseButton;
}

- (UIView *)firstLine {
    if (!_firstLine) {
        _firstLine = [[UIView alloc] init];
        _firstLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0.1];
    }
    return _firstLine;
}

- (UIView *)secondLine {
    if (!_secondLine) {
        _secondLine = [[UIView alloc] init];
        _secondLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0.1];
    }
    return _secondLine;
}

- (void)updateFinishButtonWithCountDown:(NSInteger)countDown {
    NSString *buttonText = countDown <= 0 ? PLVLocalizedString(@"结束直播") : [NSString stringWithFormat:@"%@(%@s)", PLVLocalizedString(@"结束直播"), @(countDown).stringValue];
    UIColor *buttonTextColor = countDown <= 0 ? [PLVColorUtil colorFromHexString:@"#EB4747"] : [PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0.4];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:buttonText];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *firstLineAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:16],
        NSForegroundColorAttributeName: buttonTextColor,
        NSParagraphStyleAttributeName: paragraphStyle
    };
    [attributedString setAttributes:firstLineAttributes range:NSMakeRange(0, buttonText.length)];

    // 将富文本字符串设置为按钮的标题
    [self.finishButton setAttributedTitle:attributedString forState:UIControlStateNormal];
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)finishButtonAction:(id)sender {
    [self removeFromSuperview];
    if (self.finishHandler) {
        self.finishHandler();
    }
}

- (void)pauseButtonAction:(id)sender {
    [self removeFromSuperview];
    if (self.pauseHandler) {
        self.pauseHandler();
    }
}

- (void)cancelButtonAction:(id)sender {
    [self dismiss];
}

@end
