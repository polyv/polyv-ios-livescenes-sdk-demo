//
//  PLVLSSwitchSuccessTipsView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/4/28.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVLSSwitchSuccessTipsView.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat kBadNetworkTipsViewDismissDuration = 10.0;

@interface PLVLSSwitchSuccessTipsView ()

@property (nonatomic, assign) BOOL showing;
@property (nonatomic, strong) UILabel *label;

@end

@implementation PLVLSSwitchSuccessTipsView

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
    self.label.frame = CGRectMake(0, 5, self.bounds.size.width, 15);
}

#pragma mark - [ Public Methods ]

- (void)showAtView:(UIView *)superView aboveSubview:(UIView *)aboveView {
    self.showing = YES;
    [superView insertSubview:self aboveSubview:aboveView];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    [self performSelector:@selector(dismiss) withObject:nil afterDelay:kBadNetworkTipsViewDismissDuration];
}

- (void)dismiss {
    self.showing = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    [self removeFromSuperview];
}

- (CGFloat)tipsViewWidth {
    CGSize labelSize = [self.label sizeThatFits:CGSizeMake(MAXFLOAT, 15)];
    return labelSize.width + 22;
}

#pragma mark - [ Private Methods ]

- (void)initUI {
    [self addSubview:self.label];
}

#pragma mark Getter & Setter

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.font = [UIFont systemFontOfSize:12];
        _label.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
        _label.text = PLVLocalizedString(@"已切换到流畅模式");
    }
    return _label;
}

@end
