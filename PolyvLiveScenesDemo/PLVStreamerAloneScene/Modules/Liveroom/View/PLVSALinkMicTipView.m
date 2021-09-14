//
//  PLVSALinkMicTipView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSALinkMicTipView.h"

// 工具
#import "PLVSAUtils.h"

// 框架
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVSALinkMicTipView()

@property (nonatomic, strong) UIImageView *tipImageView;
@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) UIButton *checkButton;

@end

@implementation PLVSALinkMicTipView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        self.layer.cornerRadius = 16;
        self.layer.masksToBounds = YES;
        
        [self addSubview:self.tipImageView];
        [self addSubview:self.tipLabel];
        [self addSubview:self.checkButton];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(checkButtonAction)];
        [self addGestureRecognizer:tap];
    }
    return self;
}
#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat viewHeight = self.bounds.size.height;
    CGFloat viewWidth = self.bounds.size.width;
    
    self.tipImageView.frame = CGRectMake(12, (viewHeight - 18 ) / 2, 18, 18);
    self.checkButton.frame = CGRectMake(viewWidth - 50 - 5, (viewHeight - 24 ) / 2, 50, 24);
    self.tipLabel.frame = CGRectMake(CGRectGetMaxY(self.tipImageView.frame) + 8, 0, viewWidth - 18 - 50 - 12 - 5 -5, viewHeight);
}

#pragma mark - [ Public Method ]

- (void)show {
    self.alpha = 1.0;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dissmiss) object:nil];
    [self performSelector:@selector(dissmiss) withObject:nil afterDelay:10.0];
}

- (void)dissmiss {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dissmiss) object:nil];
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.0;
    }];
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (UIImageView *)tipImageView {
    if (!_tipImageView) {
        _tipImageView = [[UIImageView alloc] init];
        _tipImageView.image = [PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_linkmic_tip"];
    }
    return _tipImageView;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.text = @"有人正在申请连麦";
        _tipLabel.textAlignment = NSTextAlignmentLeft;
        _tipLabel.font = [UIFont systemFontOfSize:14];
        _tipLabel.textColor = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:1/1.0];
    }
    return _tipLabel;
}

- (UIButton *)checkButton {
    if (!_checkButton) {
        _checkButton = [[UIButton alloc] init];
        _checkButton.layer.cornerRadius = 12;
        _checkButton.layer.masksToBounds = YES;
        _checkButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _checkButton.titleLabel.textColor = [UIColor whiteColor];
        _checkButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#3399FF"];
        [_checkButton setTitle:@"查看" forState:UIControlStateNormal];
        [_checkButton addTarget:self action:@selector(checkButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _checkButton;
}

#pragma mark - Event

#pragma mark Action

- (void)checkButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(linkMicTipViewDidTapCheckButton:)]) {
        [self.delegate linkMicTipViewDidTapCheckButton:self];
    }
}

@end
