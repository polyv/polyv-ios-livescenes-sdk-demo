//
//  PLVSACameraAndMicphoneStateView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/10.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSACameraAndMicphoneStateView.h"

// 工具
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"

// 框架
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVSACameraAndMicphoneStateView()

@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UILabel *notifyLabel;
@property (nonatomic, strong) UILabel *tipLabel;

// 数据
@property (nonatomic, assign) CGFloat bgWidth;

@end

@implementation PLVSACameraAndMicphoneStateView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.bgWidth = 200;
        
        self.hidden = YES;
        self.backgroundColor = [UIColor clearColor];

        [self addSubview:self.bgView];
        [self.bgView addSubview:self.notifyLabel];
        [self.bgView addSubview:self.tipLabel];
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat padding = isPad ? 24 : 8;
    self.bgView.frame = CGRectMake(padding, 0, self.bgWidth, self.frame.size.height);
    
    CGFloat viewHeight = self.bgView.frame.size.height;
    CGFloat viewWidth = self.bgView.frame.size.width;
    
    self.notifyLabel.frame = CGRectMake(12, (viewHeight - 24 ) / 2, 50, 24);
    self.tipLabel.frame = CGRectMake(CGRectGetMaxX(self.notifyLabel.frame) + 5, 0, viewWidth - 12 - 50 - 5, viewHeight);
    
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self) {
        return nil;
    }
    return hitView;
}

#pragma mark - [ Public Method ]

- (void)updateCameraOpen:(BOOL)cameraOpen micphoneOpen:(BOOL)micphoneOpen {
    NSString *tipString = @"";
    CGRect frame = self.bgView.frame;
    
    if (!cameraOpen) {
        tipString = PLVLocalizedString(@"你的摄像头已关闭");
    }
    if (!micphoneOpen) {
        tipString = PLVLocalizedString(@"你的麦克风已关闭");
    }
    
    if (!cameraOpen &&
        !micphoneOpen) {
        tipString = PLVLocalizedString(@"你的摄像头和麦克风已关闭");
    }
    self.tipLabel.text = tipString;
    CGSize tipLabelSize = [self.tipLabel sizeThatFits:CGSizeMake(MAXFLOAT, self.bgView.frame.size.height)];
    CGFloat width = tipLabelSize.width + 12 + 50 + 5;
    frame.size.width = width;
    self.bgWidth = width;
    self.bgView.frame = frame;
    
    self.hidden = cameraOpen && micphoneOpen;
    
    [self.superview setNeedsLayout];
    [self.superview layoutIfNeeded];
}
#pragma mark - [ Private Method ]

#pragma mark Getter

- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc] init];
        _bgView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        _bgView.layer.cornerRadius = 18;
        _bgView.layer.masksToBounds = YES;
    }
    return _bgView;
}

- (UILabel *)notifyLabel {
    if (!_notifyLabel) {
        _notifyLabel = [[UILabel alloc] init];
        _notifyLabel.text = PLVLocalizedString(@"通知");
        _notifyLabel.textAlignment = NSTextAlignmentCenter;
        _notifyLabel.font = [UIFont systemFontOfSize:12];
        _notifyLabel.textColor = [UIColor whiteColor];
        _notifyLabel.backgroundColor = [PLVColorUtil colorFromHexString:@"#3399FF"];
        _notifyLabel.layer.cornerRadius = 12;
        _notifyLabel.layer.masksToBounds = YES;
    }
    return _notifyLabel;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.text = @"";
        _tipLabel.textAlignment = NSTextAlignmentLeft;
        _tipLabel.font = [UIFont systemFontOfSize:14];
        _tipLabel.textColor = [UIColor whiteColor];
    }
    return _tipLabel;
}

@end
