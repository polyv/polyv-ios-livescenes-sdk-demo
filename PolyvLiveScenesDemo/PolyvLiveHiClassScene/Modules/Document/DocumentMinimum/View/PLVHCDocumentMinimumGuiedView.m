//
//  PLVHCDocumentMinimumGuiedView.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/7/26.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCDocumentMinimumGuiedView.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCDocumentMinimumGuiedView()

#pragma mark UI
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UILabel *guiedLabel;

#pragma mark 数据
@property (nonatomic, assign) CGSize menuSize;

@end

@implementation PLVHCDocumentMinimumGuiedView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self.menuView addSubview:self.guiedLabel];
        [self addSubview:self.menuView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.menuView.frame = self.bounds;
    self.guiedLabel.frame = self.menuView.bounds;
    self.menuSize = self.menuView.frame.size;
    
    UIBezierPath *bezierPath = [self BezierPathWithSize:self.menuSize];
    CAShapeLayer* shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = bezierPath.CGPath;
    self.menuView.layer.mask = shapeLayer;
}

#pragma mark - [ Public Method ]

- (void)showInView:(UIView *)parentView {
    if (!parentView) {
        return;
    }
    [parentView addSubview:self];
}

- (void)dismiss {
    [self removeFromSuperview];
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (UIView *)menuView {
    if (!_menuView) {
        _menuView = [[UIView alloc] init];
        _menuView.layer.masksToBounds = YES;
        _menuView.backgroundColor = [PLVColorUtil colorFromHexString:@"#232840"];
    }
    return _menuView;
}

- (UILabel *)guiedLabel {
    if (!_guiedLabel) {
        _guiedLabel = [[UILabel alloc] init];
        _guiedLabel.textColor = [UIColor colorWithWhite:1 alpha:0.8];
        _guiedLabel.textAlignment = NSTextAlignmentCenter;
        _guiedLabel.text = @"课件窗口收起在这里了";
        _guiedLabel.font = [UIFont systemFontOfSize:14];
    }
    return _guiedLabel;
}

#pragma mark UIBezierPath

- (UIBezierPath *)BezierPathWithSize:(CGSize)size {
    CGFloat conner = 8.0; // 圆角角度
    CGFloat trangleHeight = 8.0; // 尖角高度
    CGFloat trangleWidth = 6.0; // 尖角半径
    CGFloat leftPadding = 8.0;
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    // 起点
    [bezierPath moveToPoint:CGPointMake(conner + leftPadding, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width - leftPadding - conner, 0)];
    
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width, conner) controlPoint:CGPointMake(size.width, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width, size.height- conner - trangleHeight)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width-conner, size.height) controlPoint:CGPointMake(size.width, size.height)];

    [bezierPath addLineToPoint:CGPointMake(conner + leftPadding, size.height)];
    [bezierPath addQuadCurveToPoint:CGPointMake(leftPadding, size.height - conner) controlPoint:CGPointMake(leftPadding, size.height)];
    [bezierPath addLineToPoint:CGPointMake(leftPadding, conner)];
    [bezierPath addQuadCurveToPoint:CGPointMake(conner + leftPadding, 0) controlPoint:CGPointMake(leftPadding, 0)];
    
    // 画尖角
    [bezierPath moveToPoint:CGPointMake(leftPadding, size.height - conner - trangleHeight)];
    // 顶点
    [bezierPath addLineToPoint:CGPointMake(0, size.height - conner - trangleHeight - trangleWidth)];
    
    [bezierPath addLineToPoint:CGPointMake(leftPadding, size.height - conner - trangleHeight - trangleWidth * 2)];
    [bezierPath closePath];
    return bezierPath;
}

@end
