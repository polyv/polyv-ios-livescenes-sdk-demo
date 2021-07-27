//
//  PLVSAFinishStreamerSheet.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/11.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAFinishStreamerSheet.h"
#import "PLVSAUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat kButtonHeight = 58.0;
static CGFloat kLineHeight = 1.0;

@interface PLVSAFinishStreamerSheet ()

/// UI
@property (nonatomic, strong) UIButton *finishButton;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIView *line;

/// 其他
@property (nonatomic, copy) void(^finishHandler)(void);

@end

@implementation PLVSAFinishStreamerSheet

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    CGFloat bottom = [PLVSAUtils sharedUtils].areaInsets.bottom;
    self = [super initWithSheetHeight:2 * kButtonHeight + kLineHeight + bottom];
    if (self) {
        [self.contentView addSubview:self.finishButton];
        [self.contentView addSubview:self.cancelButton];
        [self.contentView addSubview:self.line];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.finishButton.frame = CGRectMake(0, 0, self.contentView.bounds.size.width, kButtonHeight);
    self.line.frame = CGRectMake(0, kButtonHeight, self.contentView.bounds.size.width, kLineHeight);
    self.cancelButton.frame = CGRectMake(0, kButtonHeight + kLineHeight, self.contentView.bounds.size.width, self.sheetHight - kLineHeight - kButtonHeight);
}

#pragma mark - [ Public Method ]

- (void)showInView:(UIView *)parentView finishAction:(void (^)(void))finishHandler {
    [super showInView:parentView];
    self.finishHandler = finishHandler;
}

#pragma mark - [ Private Method ]

#pragma mark Getter & Setter

- (UIButton *)finishButton {
    if (!_finishButton) {
        _finishButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_finishButton setTitle:@"结束直播" forState:UIControlStateNormal];
        [_finishButton setTitleColor:[PLVColorUtil colorFromHexString:@"#FF5459"] forState:UIControlStateNormal];
        _finishButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_finishButton addTarget:self action:@selector(finishButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _finishButton;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
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

- (UIView *)line {
    if (!_line) {
        _line = [[UIView alloc] init];
        _line.backgroundColor = [PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0.1];
    }
    return _line;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)finishButtonAction:(id)sender {
    [self removeFromSuperview];
    if (self.finishHandler) {
        self.finishHandler();
    }
}

- (void)cancelButtonAction:(id)sender {
    [self dismiss];
}

@end
