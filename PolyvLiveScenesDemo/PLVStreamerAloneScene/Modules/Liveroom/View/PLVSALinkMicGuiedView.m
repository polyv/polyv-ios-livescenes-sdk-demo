//
//  PLVSALinkMicGuiedView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/10.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSALinkMicGuiedView.h"

// 工具
#import "PLVSAUtils.h"

// 框架
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface  PLVSALinkMicGuiedView()

// UI
@property (nonatomic, strong) UIImageView *menuView;
@property (nonatomic, strong) UILabel *tipLabel; //提示

// 数据
@property (nonatomic, assign) CGSize menuSize;

@end

@implementation PLVSALinkMicGuiedView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.menuView];
        [self.menuView addSubview:self.tipLabel];
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = self.bounds;
    
    self.menuSize = frame.size;
    self.menuView.frame = frame;

    self.tipLabel.frame = frame;
    self.tipLabel.center = self.menuView.center;
}

#pragma mark - [ Public Method ]

- (void)showLinMicGuied:(BOOL)show {
    self.hidden = !show;
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (UIImageView *)menuView {
    if (!_menuView) {
        _menuView = [[UIImageView alloc] init];
        _menuView.image = [PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_bg_linkmic_guied"];
        _menuView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _menuView;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        if (@available(iOS 8.2, *)) {
        _tipLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        } else {
            _tipLabel.font = [UIFont systemFontOfSize:14];
        }
        _tipLabel.textColor = [UIColor whiteColor];
        _tipLabel.text = @"点击可管理上麦成员哦";
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.numberOfLines = 0;
    }
    return _tipLabel;
}


- (UIBezierPath *)BezierPathWithSize:(CGSize)size {
    CGFloat conner = size.height / 2;
    CGFloat trangleHeight = 8.0;
    CGFloat trangleWidth = 6.0;
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    // 起点
    [bezierPath moveToPoint:CGPointMake(conner, trangleHeight)];

    [bezierPath addLineToPoint:CGPointMake(size.width - conner - trangleWidth * 2 , trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(size.width - conner - trangleWidth, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width - conner, trangleHeight)];
    
    [bezierPath addLineToPoint:CGPointMake(size.width - conner, trangleHeight)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width, conner + trangleHeight) controlPoint:CGPointMake(size.width, trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(size.width, size.height-conner)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width-conner, size.height) controlPoint:CGPointMake(size.width, size.height)];
    [bezierPath addLineToPoint:CGPointMake(conner, size.height)];
    [bezierPath addQuadCurveToPoint:CGPointMake(0, size.height-conner) controlPoint:CGPointMake(0, size.height)];
    [bezierPath addLineToPoint:CGPointMake(0, conner + trangleHeight)];
    [bezierPath addQuadCurveToPoint:CGPointMake(conner, trangleHeight) controlPoint:CGPointMake(0, trangleHeight)];
    [bezierPath closePath];
    return bezierPath;
}

@end
