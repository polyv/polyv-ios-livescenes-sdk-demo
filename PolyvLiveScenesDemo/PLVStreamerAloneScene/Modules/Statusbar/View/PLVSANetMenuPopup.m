//
//  PLVSANetMenuPopup.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/25.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSANetMenuPopup.h"
//utils
#import "PLVSAUtils.h"
// SDK
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVSANetMenuPopup()

// UI
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UILabel *delayLabel; // 网络延迟
@property (nonatomic, strong) UILabel *lossLabel; // 丢包率

// 数据
@property (nonatomic, assign) CGSize menuSize;

@end

@implementation PLVSANetMenuPopup

#pragma mark - [ Life Cycle ]

- (instancetype)initWithMenuFrame:(CGRect)frame {
    self = [super init];
    if (self) {
        self.frame = [UIScreen mainScreen].bounds;
        self.backgroundColor = [UIColor clearColor];
        
        self.menuSize = frame.size;
        self.menuView.frame = frame;
        [self addSubview:self.menuView];
        
        self.delayLabel.frame = CGRectMake(10, 14, frame.size.width - 10, 12);
        self.lossLabel.frame = CGRectMake(10, 14 + 12 + 4, frame.size.width - 10, 12);
        [self.menuView addSubview:self.delayLabel];
        [self.menuView addSubview:self.lossLabel];
    }
    return self;
}

#pragma mark - [ Override ]
#pragma mark - [ Public Method ]
/// 显示menu
/// @param superView 准备显示在哪个控件上
- (void)showAtView:(UIView *)superView {
    [superView addSubview:self];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    
    [self performSelector:@selector(dismiss) withObject:nil afterDelay:3.0];
}

/// 关闭menu
- (void)dismiss {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    [self removeFromSuperview];
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (UIView *)menuView {
    if (!_menuView) {
        _menuView = [[UIView alloc] init];
        _menuView.backgroundColor = [PLVColorUtil colorFromHexString:@"#1B202D" alpha:0.75];
        _menuView.layer.masksToBounds = YES;

        UIBezierPath *bezierPath = [[self class] BezierPathWithSize:self.menuSize];
        CAShapeLayer* shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = bezierPath.CGPath;
        _menuView.layer.mask = shapeLayer;
    }
    return _menuView;
}

- (UILabel *)delayLabel {
    if (!_delayLabel) {
        _delayLabel = [[UILabel alloc] init];
        _delayLabel.font = [UIFont systemFontOfSize:12];
        _delayLabel.textColor = [UIColor whiteColor];
        _delayLabel.text = @"网络延迟:10ms";
    }
    return _delayLabel;
}

- (UILabel *)lossLabel {
    if (!_lossLabel) {
        _lossLabel = [[UILabel alloc] init];
        _lossLabel.font = [UIFont systemFontOfSize:12];
        _lossLabel.textColor = [UIColor whiteColor];
        _lossLabel.text = @"丢包率:2%";
    }
    return _lossLabel;
}

+ (UIBezierPath *)BezierPathWithSize:(CGSize)size {
    CGFloat conner = 8.0;
    CGFloat trangleHeight = 8.0;
    CGFloat trangleWidthForHalf = 6.0;

    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(conner, trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(size.width/2. - trangleWidthForHalf, trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(size.width/2., 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width/2. + trangleWidthForHalf, trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(size.width-conner, trangleHeight)];
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
