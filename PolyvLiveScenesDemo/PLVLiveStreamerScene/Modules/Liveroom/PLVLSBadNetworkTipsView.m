//
//  PLVLSBadNetworkTipsView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/4/28.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVLSBadNetworkTipsView.h"
#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat kBadNetworkTipsViewDismissDuration = 10.0; // 每次显示持续时长
static CGFloat kBadNetworkTipsViewShowInterval = 60 * 10.0; // 两次显示时间最小间隔

@interface PLVLSBadNetworkTipsView ()

@property (nonatomic, assign) BOOL showing;
@property (nonatomic, assign) BOOL cooling;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIButton *switchButton;
@property (nonatomic, strong) UIButton *closeButton;

@end

@implementation PLVLSBadNetworkTipsView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#1B202D" alpha:0.8];
        self.layer.cornerRadius = 12.5;

        [self initUI];
    }
    return self;
}

- (void)layoutSubviews {
    self.closeButton.frame = CGRectMake(self.bounds.size.width - 4 - 24, 0, 24, self.bounds.size.height);
    self.switchButton.frame = CGRectMake(CGRectGetMinX(self.closeButton.frame)- 70, 0, 70, self.bounds.size.height);
    self.label.frame = CGRectMake(12, 5, CGRectGetMinX(self.closeButton.frame) - 12, 15);
}

#pragma mark - [ Public Methods ]

- (void)showAtView:(UIView *)superView aboveSubview:(UIView *)aboveView {
    [superView insertSubview:self aboveSubview:aboveView];
    
    if (self.showing || self.cooling) {
        return;
    }
    
    self.showing = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    [self performSelector:@selector(dismiss) withObject:nil afterDelay:kBadNetworkTipsViewDismissDuration];
}

- (void)dismiss {
    self.showing = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    [self removeFromSuperview];
    
    [self startCooling];
}

- (void)reset {
    [self stopCooling];
}

- (CGFloat)tipsViewWidth {
    CGSize labelSize = [self.label sizeThatFits:CGSizeMake(MAXFLOAT, 15)];
    return labelSize.width + 46;
}

#pragma mark - [ Private Methods ]

- (void)initUI {
    [self addSubview:self.label];
    [self addSubview:self.closeButton];
    [self addSubview:self.switchButton];
    
    [self setupLabelText];
}

- (void)setupLabelText {
    NSMutableAttributedString *muString = [[NSMutableAttributedString alloc] init];
    
    {
        NSString *string = PLVLocalizedString(@"当前网络较差，建议切换为流畅模式 ");
        NSDictionary *attributes = @{
            NSFontAttributeName : [UIFont systemFontOfSize:12],
            NSForegroundColorAttributeName : [PLVColorUtil colorFromHexString:@"#F0F1F5"]
        };
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
        [muString appendAttributedString:attributedString];
    }
    
    {
        NSString *string = PLVLocalizedString(@"马上切换");
        NSDictionary *attributes = @{
            NSFontAttributeName : [UIFont systemFontOfSize:12],
            NSForegroundColorAttributeName : [PLVColorUtil colorFromHexString:@"#FF6363"],
            NSUnderlineStyleAttributeName : @(1)
        };
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
        [muString appendAttributedString:attributedString];
    }
    
    self.label.attributedText = [muString copy];
}

- (void)startCooling {
    self.cooling = YES;
    [self performSelector:@selector(stopCooling) withObject:nil afterDelay:kBadNetworkTipsViewShowInterval];
}

- (void)stopCooling {
    self.cooling = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopCooling) object:nil];
}

#pragma mark Getter & Setter

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] init];
    }
    return _label;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVLSUtils imageForLiveroomResource:@"plvls_video_mode_switch_close_icon"];
        [_closeButton setImage:normalImage forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UIButton *)switchButton {
    if (!_switchButton) {
        _switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_switchButton addTarget:self action:@selector(switchButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _switchButton;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)closeButtonAction {
    [self dismiss];
    
    if (self.closeButtonActionBlock) {
        self.closeButtonActionBlock();
    }
}

- (void)switchButtonAction {
    [self dismiss];
    [self reset];
    
    if (self.switchButtonActionBlock) {
        self.switchButtonActionBlock();
    }
}

@end
