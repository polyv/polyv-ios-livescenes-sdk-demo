//
//  PLVSABeautyFilterTitleView.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/4/21.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSABeautyFilterTitleView.h"
// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVSABeautyFilterTitleView()

@property (nonatomic, strong) UILabel *filterTypeLabel;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UILabel *filterLabel;

@end

@implementation PLVSABeautyFilterTitleView

#pragma mark - [ Life Cycle ]
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.filterTypeLabel];
        [self addSubview:self.lineView];
        [self addSubview:self.filterLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.filterTypeLabel.frame = CGRectMake(0, self.bounds.size.height - 22, 45, 22);
    self.lineView.frame = CGRectMake(CGRectGetMaxX(self.filterTypeLabel.frame) + 4, self.bounds.size.height - 12, 1, 12);
    self.filterLabel.frame = CGRectMake(CGRectGetMaxX(self.lineView.frame) + 4, self.bounds.size.height - 14, 29, 14);
}

#pragma mark - [ Public Method ]
- (void)showAtView:(UIView *)superView title:(NSString *)title {
    if (![PLVFdUtil checkStringUseable:title]) {
        return;
    }
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowBlurRadius = 1;
    shadow.shadowOffset = CGSizeMake(0, 0);
    shadow.shadowColor = [PLVColorUtil colorFromHexString:@"#000000" alpha:0.4];
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:title attributes:@{NSShadowAttributeName:shadow}];
    self.filterTypeLabel.attributedText = attributedString;
    
    [superView addSubview:self];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    [self performSelector:@selector(dismiss) withObject:nil afterDelay:3.0];
}

- (void)dismiss {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    [self removeFromSuperview];
}

#pragma mark - [ Private Method ]
#pragma mark Getter
- (UILabel *)filterTypeLabel {
    if (!_filterTypeLabel) {
        _filterTypeLabel = [[UILabel alloc] init];
        _filterTypeLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
        _filterTypeLabel.font = [UIFont systemFontOfSize:22];
        _filterTypeLabel.text = @"";
    }
    return _filterTypeLabel;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
    }
    return _lineView;
}

- (UILabel *)filterLabel {
    if (!_filterLabel) {
        _filterLabel = [[UILabel alloc] init];
        _filterLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
        _filterLabel.font = [UIFont systemFontOfSize:14];
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowBlurRadius = 1;
        shadow.shadowOffset = CGSizeMake(0, 0);
        shadow.shadowColor = [PLVColorUtil colorFromHexString:@"#000000" alpha:0.4];
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"滤镜" attributes:@{NSShadowAttributeName:shadow}];
        _filterLabel.attributedText = attributedString;
    }
    return _filterLabel;
}

@end
