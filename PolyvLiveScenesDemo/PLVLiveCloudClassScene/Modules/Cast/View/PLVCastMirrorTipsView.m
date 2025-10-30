//
//  PLVCastMirrorTipsView.m
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/9/10.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVCastMirrorTipsView.h"
#import "PLVLCUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>


@interface PLVCastMirrorTipsView()

#pragma mark UI
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIView *lineView;

@property (nonatomic, strong) UILabel *tipsLabel;

@property (nonatomic, strong) UIView *firstStepView;

@property (nonatomic, strong) UIView *secondStepView;

@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic, strong) UIButton *confirmButton;

@property (nonatomic, strong) UIImageView *tipsImageView;

@end

@implementation PLVCastMirrorTipsView

#pragma mark - [ Life Cycle]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        self.needShow = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.contentView.frame = CGRectMake(0, CGRectGetHeight(self.frame) - 520, CGRectGetWidth(self.frame), 520);
    
    self.titleLabel.frame = CGRectMake((CGRectGetWidth(self.contentView.frame) - 32) / 2, 5, 32, 48);
    self.lineView.frame = CGRectMake(0, CGRectGetMaxY(self.titleLabel.frame) + 8, CGRectGetWidth(self.contentView.frame), 1);
    self.tipsLabel.frame = CGRectMake(22, CGRectGetMaxY(self.lineView.frame) + 22, 128, 22);
    self.firstStepView.frame = CGRectMake(CGRectGetMinX(self.tipsLabel.frame), CGRectGetMaxY(self.tipsLabel.frame) + 12, CGRectGetWidth(self.contentView.frame) - 22 * 2, 47);
    self.secondStepView.frame = CGRectMake(CGRectGetMinX(self.tipsLabel.frame), CGRectGetMaxY(self.firstStepView.frame) + 20, CGRectGetWidth(self.firstStepView.frame), 80);
    self.tipsImageView.frame = CGRectMake(CGRectGetMinX(self.tipsLabel.frame), CGRectGetMaxY(self.secondStepView.frame) + 20, CGRectGetWidth(self.firstStepView.frame), 155);
    
    self.confirmButton.frame = CGRectMake(24, CGRectGetMaxY(self.tipsImageView.frame) + 20, CGRectGetWidth(self.contentView.frame) - 24 * 2, 48);
    self.closeButton.frame = CGRectMake(CGRectGetWidth(self.contentView.frame) - 18 - 28, CGRectGetMidY(self.titleLabel.frame) - 28 / 2, 28, 28);
    
    // 顶部设置圆角
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(8, 8)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    self.layer.mask = maskLayer;
}


#pragma mark - [ Private Methods ]

- (void)setupUI {
    [self addSubview:self.contentView];
    
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.lineView];
    [self.contentView addSubview:self.tipsLabel];
    [self.contentView addSubview:self.firstStepView];
    [self.contentView addSubview:self.secondStepView];
    [self.contentView addSubview:self.tipsImageView];
    [self.contentView addSubview:self.closeButton];
    [self.contentView addSubview:self.confirmButton];
}

- (UIView *)setupTitle:(NSString *)title content:(NSString *)content {
    UIView *view = [[UIView alloc] init];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.layer.cornerRadius = 10;
    titleLabel.layer.masksToBounds = YES;
    titleLabel.layer.borderWidth = 1;
    titleLabel.layer.borderColor = PLV_UIColorFromRGBA(@"#FFFFFF",0.2).CGColor;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [view addSubview:titleLabel];
    titleLabel.frame = CGRectMake(0, 0, 51, 20);
    
    UILabel *contentLabel = [[UILabel alloc] init];
    contentLabel.text = content;
    contentLabel.numberOfLines = 0;
    contentLabel.textColor = PLV_UIColorFromRGB(@"#ADADC0");
    contentLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
    [view addSubview:contentLabel];
    CGFloat contentLabelHeight = [contentLabel sizeThatFits:CGSizeMake(337, MAXFLOAT)].height;
    contentLabel.frame = CGRectMake(CGRectGetMinX(titleLabel.frame), CGRectGetMaxY(titleLabel.frame) + 10, 337, contentLabelHeight);
    
    return view;;
}

- (void)hide {
    if (self.alpha == 0) { return; }
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.33 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.alpha = 0;
    } completion:^(BOOL finished) {
        [weakSelf removeFromSuperview];
    }];
}

#pragma mark [ Getter & Setter ]

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = PLV_UIColorFromRGB(@"#202127");
    }
    return _contentView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"投屏";
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = [UIColor whiteColor];
    }
    return _titleLabel;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = PLV_UIColorFromRGBA(@"#FFFFFF",0.1);
    }
    return _lineView;
}

- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [[UILabel alloc] init];
        _tipsLabel.text = @"如何投文档到电视";
        _tipsLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.textColor = [UIColor whiteColor];
    }
    return _tipsLabel;
}

- (UIView *)firstStepView {
    if (!_firstStepView) {
        _firstStepView = [self setupTitle:@"第一步" content:@"电视/盒子开机，确认电视/盒子与手机连接着同一个WLAN"];
    }
    return _firstStepView;
}

- (UIView *)secondStepView {
    if (!_secondStepView) {
        _secondStepView = [self setupTitle:@"第二步" content:@"顶部右侧的菜单栏往下拉，在显示的页面中，选择“屏幕镜像”，在弹出的选择中，选择投屏的电视/盒子"];
    }
    return _secondStepView;
}

- (UIImageView *)tipsImageView {
    if (!_tipsImageView) {
        _tipsImageView = [[UIImageView alloc] initWithImage:[PLVLCUtils imageForCastResource:@"plv_cast_mirror_tips_image"]];
        _tipsImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _tipsImageView;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [[UIButton alloc] init];
        [_closeButton addTarget:self action:@selector(closeAction:) forControlEvents:UIControlEventTouchUpInside];
        [_closeButton setImage:[PLVLCUtils imageForCastResource:@"plv_cast_mirror_tips_close_btn"] forState:UIControlStateNormal];
    }
    return _closeButton;
}

- (UIButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[UIButton alloc] init];
        [_confirmButton addTarget:self action:@selector(closeAction:) forControlEvents:UIControlEventTouchUpInside];
        _confirmButton.backgroundColor = PLV_UIColorFromRGB(@"#3082FE");
        _confirmButton.layer.masksToBounds = YES;
        _confirmButton.layer.cornerRadius = 24;
        [_confirmButton setTitle:@"我知道了" forState:UIControlStateNormal];
        _confirmButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
        _confirmButton.titleLabel.textColor = [UIColor whiteColor];
    }
    return _confirmButton;
}

#pragma mark - [ Public Methods ]
- (void)showOnView:(UIView *)superView {
    if (!self.needShow) {
        return;
    }
    
    self.frame = superView.bounds;
    [superView addSubview:self];
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.33 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.needShow = NO;
        weakSelf.alpha = 1;
    } completion:nil];
}

#pragma mark - [ Event ]

#pragma mark Action
- (void)closeAction:(UIButton *)button {
    [self hide];
}



@end
