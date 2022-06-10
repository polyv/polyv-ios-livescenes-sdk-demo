//
//  PLVLCTabbarItemCell.m
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/5/26.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCTabbarItemCell.h"

#define kSelectedColor [UIColor whiteColor]
#define kNormalColor [UIColor colorWithRed:173/255.0 green:173/255.0 blue:192/255.0 alpha:1/1.0];

@implementation PLVLCTabbarItemCell

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.frame = self.bounds;
        [self addSubview:self.titleLabel];
        
        CGSize indicatorSize = CGSizeMake(48.0, 2.0);
        self.indicatorView.frame = CGRectMake((self.bounds.size.width - indicatorSize.width) / 2.0, self.bounds.size.height - indicatorSize.height, indicatorSize.width, indicatorSize.height);
        [self addSubview:self.indicatorView];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.titleLabel.frame = self.bounds;
    self.indicatorView.center = CGPointMake(self.bounds.size.width/2, self.indicatorView.center.y);
}

#pragma mark - Getter & Setter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = kNormalColor;
        _titleLabel.font = [UIFont boldSystemFontOfSize:16];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 1;
    }
    return _titleLabel;
}

- (UIView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIView alloc] init];
        _indicatorView.backgroundColor = [UIColor whiteColor];
        _indicatorView.layer.cornerRadius = 1;
        _indicatorView.layer.masksToBounds = YES;
        _indicatorView.hidden = YES;
    }
    return _indicatorView;
}

- (void)setClicked:(BOOL)clicked {
    _clicked = clicked;
    
    _indicatorView.hidden = !clicked;
    _titleLabel.textColor = clicked ? kSelectedColor : kNormalColor;
}

@end
