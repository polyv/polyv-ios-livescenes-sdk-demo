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
    
    self.bgView.frame = CGRectMake(8, 0, self.bgWidth, self.frame.size.height);
    
    CGFloat viewHeight = self.bgView.frame.size.height;
    CGFloat viewWidth = self.bgView.frame.size.width;
    
    self.notifyLabel.frame = CGRectMake(12, (viewHeight - 24 ) / 2, 50, 24);
    self.tipLabel.frame = CGRectMake(CGRectGetMaxX(self.notifyLabel.frame) + 5, 0, viewWidth - 12 - 50 - 5, viewHeight);
    
}
#pragma mark - [ Public Method ]

- (void)updateCameraOpen:(BOOL)cameraOpen micphoneOpen:(BOOL)micphoneOpen {
    NSString *tipString = @"";
    CGRect frame = self.bgView.frame;
    CGFloat width = frame.size.width;
    
    if (!cameraOpen) {
        tipString = @"你的摄像头已关闭";
        width = 200;
    }
    if (!micphoneOpen) {
        tipString = @"你的麦克风已关闭";
        width = 200;
    }
    
    if (!cameraOpen &&
        !micphoneOpen) {
        tipString = @"你的摄像头和麦克风已关闭";
        width = 250;
    }
    
    frame.size.width = width;
    self.bgWidth = width;
    self.bgView.frame = frame;
    
    self.tipLabel.text = tipString;
    self.hidden = cameraOpen && micphoneOpen;
    
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
        _notifyLabel.text = @"通知";
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
