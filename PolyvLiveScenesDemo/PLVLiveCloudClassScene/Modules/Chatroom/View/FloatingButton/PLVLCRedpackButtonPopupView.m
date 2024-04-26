//
//  PLVLCRedpackButtonPopupView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/1/13.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVLCRedpackButtonPopupView.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat kLabelContainerHeight = 28.0;
static CGFloat kArrowWidth = 10.0;
static CGFloat kArrowHeight = 6.0;

@interface PLVLCRedpackButtonPopupView ()

@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) NSString *labelString;
@property (nonatomic, assign) BOOL isLandscape;
@property (nonatomic, assign) CGSize caculateSize;

@end

@implementation PLVLCRedpackButtonPopupView

#pragma mark - [ Life Cycle ]

- (void)layoutSubviews {
    self.bgView.frame = self.gradientLayer.frame = self.bounds;
    
    CGFloat labelHeight = 16.0;
    CGFloat labelWidth = self.caculateSize.width - (self.isLandscape ? 0 : kArrowHeight);
    self.label.frame = CGRectMake(0, (kLabelContainerHeight - labelHeight) / 2.0, labelWidth, labelHeight);
    
    UIBezierPath *maskPath = [self bgViewBezierPathWithSize:self.bounds.size];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    self.bgView.layer.mask = maskLayer;
}

#pragma mark - [ Public Methods ]

- (instancetype)initWithLabelString:(NSString *)string isLandscape:(BOOL)isLandscape {
    self = [super init];
    if (self) {
        if (string && [string isKindOfClass:[NSString class]]) {
            self.labelString = string;
        } else {
            self.labelString = @"";
        }
        
        self.isLandscape = isLandscape;
        [self addSubview:self.bgView];
        [self addSubview:self.label];
        
        CGFloat labelWidth = [self.label sizeThatFits:CGSizeMake(MAXFLOAT, kLabelContainerHeight)].width + 14;
        if (self.isLandscape) {
            self.caculateSize = CGSizeMake(labelWidth, kLabelContainerHeight + kArrowHeight);
        } else {
            self.caculateSize = CGSizeMake(labelWidth + kArrowHeight, kLabelContainerHeight);
        }
    }
    return self;
}

#pragma mark - [ Private Methods ]

- (UIBezierPath *)bgViewBezierPathWithSize:(CGSize)size {
    CGFloat conner = 4.0; // 圆角大小

    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    
    if (self.isLandscape) {
        CGFloat tranglePadding = (size.width - kArrowWidth) / 2.0;// 箭头与左右的间隔
        
        // 从左上角开始，顺时针绘制气泡
        [bezierPath moveToPoint:CGPointMake(conner, 0)];
        [bezierPath addLineToPoint:CGPointMake(size.width-conner, 0)];
        [bezierPath addQuadCurveToPoint:CGPointMake(size.width, conner) controlPoint:CGPointMake(size.width, 0)];
        [bezierPath addLineToPoint:CGPointMake(size.width, size.height-kArrowHeight-conner)];
        [bezierPath addQuadCurveToPoint:CGPointMake(size.width-conner, size.height-kArrowHeight) controlPoint:CGPointMake(size.width, size.height-kArrowHeight)];
        [bezierPath addLineToPoint:CGPointMake(tranglePadding + kArrowWidth, size.height-kArrowHeight)];
        [bezierPath addLineToPoint:CGPointMake(tranglePadding + kArrowWidth/2.0, size.height)];
        [bezierPath addLineToPoint:CGPointMake(tranglePadding, size.height-kArrowHeight)];
        [bezierPath addLineToPoint:CGPointMake(conner, size.height-kArrowHeight)];
        [bezierPath addQuadCurveToPoint:CGPointMake(0, size.height-kArrowHeight-conner) controlPoint:CGPointMake(0, size.height-kArrowHeight)];
        [bezierPath addLineToPoint:CGPointMake(0, conner)];
        [bezierPath addQuadCurveToPoint:CGPointMake(conner, 0) controlPoint:CGPointMake(0, 0)];
    } else {
        CGFloat tranglePadding = (size.height - kArrowWidth) / 2.0;// 箭头与上下的间隔
        
        // 从左上角开始，顺时针绘制气泡
        [bezierPath moveToPoint:CGPointMake(conner, 0)];
        [bezierPath addLineToPoint:CGPointMake(size.width-conner-kArrowHeight, 0)];
        [bezierPath addQuadCurveToPoint:CGPointMake(size.width-kArrowHeight, conner) controlPoint:CGPointMake(size.width-kArrowHeight, 0)];
        [bezierPath addLineToPoint:CGPointMake(size.width-kArrowHeight, tranglePadding)];
        [bezierPath addLineToPoint:CGPointMake(size.width, tranglePadding+kArrowWidth/2.0)];
        [bezierPath addLineToPoint:CGPointMake(size.width-kArrowHeight, tranglePadding+kArrowWidth)];
        [bezierPath addLineToPoint:CGPointMake(size.width-kArrowHeight, size.height-conner)];
        [bezierPath addQuadCurveToPoint:CGPointMake(size.width-kArrowHeight-conner, size.height) controlPoint:CGPointMake(size.width-kArrowHeight, size.height)];
        [bezierPath addLineToPoint:CGPointMake(conner, size.height)];
        [bezierPath addQuadCurveToPoint:CGPointMake(0, size.height-conner) controlPoint:CGPointMake(0, size.height)];
        [bezierPath addLineToPoint:CGPointMake(0, conner)];
        [bezierPath addQuadCurveToPoint:CGPointMake(conner, 0) controlPoint:CGPointMake(0, 0)];
    }
    
    // 气泡绘制完毕，关闭贝塞尔曲线
    [bezierPath closePath];
    return bezierPath;
}

#pragma mark Getter

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)[PLVColorUtil colorFromHexString:@"#FF9D4D"].CGColor, (__bridge id)[PLVColorUtil colorFromHexString:@"#F65F49"].CGColor];
        _gradientLayer.locations = @[@0.0, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1, 0);
    }
    return _gradientLayer;
}

- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc] init];
        _bgView.layer.masksToBounds = YES;
        _bgView.layer.borderColor = [PLVColorUtil colorFromHexString:@"#FD7232"].CGColor;
        _bgView.layer.borderWidth = 1.0;
        [_bgView.layer addSublayer:self.gradientLayer];
    }
    return _bgView;
}

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.textColor = [UIColor whiteColor];
        _label.font = [UIFont systemFontOfSize:12];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.text = self.labelString;
    }
    return _label;
}

@end
