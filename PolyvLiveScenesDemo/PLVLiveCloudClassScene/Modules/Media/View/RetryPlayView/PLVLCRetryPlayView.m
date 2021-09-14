//
//  PLVLCRetryPlayView.m
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/7/13.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLCRetryPlayView.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCRetryPlayView()

@property (nonatomic, strong) UIButton *replayButton;

@end

@implementation PLVLCRetryPlayView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.replayButton.frame = CGRectMake(CGRectGetWidth(self.frame) / 2 - 40, CGRectGetHeight(self.frame) / 2 - 15, 80, 30);
}

#pragma mark - [ Private method ]

- (void)initUI {
    [self addSubview:self.replayButton];
}

#pragma mark Getter & Setter

- (UIButton *)replayButton {
    if (!_replayButton) {
        _replayButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_replayButton setTitle:@"重试" forState:UIControlStateNormal];
        [_replayButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _replayButton.titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:14];
        _replayButton.backgroundColor = PLV_UIColorFromRGBA(@"#000000", 0.1);
        _replayButton.layer.cornerRadius = 15;
        _replayButton.layer.masksToBounds = YES;
        _replayButton.layer.borderColor = [UIColor whiteColor].CGColor;
        _replayButton.layer.borderWidth = 1.0;
        [_replayButton addTarget:self action:@selector(replayButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _replayButton;
}

#pragma mark - [ Override ]

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self.replayButton) {
        return view;
    } else {
        return nil;
    }
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)replayButtonAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCRetryPlayViewReplayButtonClicked)]) {
        [self.delegate plvLCRetryPlayViewReplayButtonClicked];
    }
}



@end
