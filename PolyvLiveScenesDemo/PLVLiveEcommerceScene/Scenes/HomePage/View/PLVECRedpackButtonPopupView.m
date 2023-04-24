//
//  PLVECRedpackButtonPopupView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/1/13.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVECRedpackButtonPopupView.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVECRedpackButtonPopupView ()

@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) NSString *labelString;

@end

@implementation PLVECRedpackButtonPopupView

#pragma mark - [ Life Cycle ]

- (void)layoutSubviews {
    self.bgView.frame = self.gradientLayer.frame = self.bounds;
    self.label.frame = CGRectMake(0, (self.bounds.size.height - 16) / 2.0, self.bounds.size.width - 6, 16);
    
    //UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:corners cornerRadii:CGSizeMake(4, 4)];
    UIBezierPath *maskPath = [PLVECRedpackButtonPopupView bgViewBezierPathWithSize:self.bounds.size];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    self.bgView.layer.mask = maskLayer;
}

#pragma mark - [ Public Methods ]

- (instancetype)initWithLabelString:(NSString *)string {
    self = [super init];
    if (self) {
        if (string && [string isKindOfClass:[NSString class]]) {
            self.labelString = string;
        } else {
            self.labelString = @"";
        }
        
        [self addSubview:self.bgView];
        [self addSubview:self.label];
    }
    return self;
}

#pragma mark - [ Private Methods ]

+ (UIBezierPath *)bgViewBezierPathWithSize:(CGSize)size {
    CGFloat conner = 4.0; // 圆角大小
    CGFloat trangleWidth = 6.0; // 箭头宽度
    CGFloat trangleHeight = 10.0; // 箭头高度
    CGFloat tranglePadding = (size.height - trangleHeight) / 2.0;// 箭头与上下的间隔

    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    
    // 从左上角开始，顺时针绘制气泡
    [bezierPath moveToPoint:CGPointMake(conner, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width-conner-trangleWidth, 0)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width-trangleWidth, conner) controlPoint:CGPointMake(size.width-trangleWidth, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width-trangleWidth, tranglePadding)];
    [bezierPath addLineToPoint:CGPointMake(size.width, tranglePadding+trangleHeight/2.0)];
    [bezierPath addLineToPoint:CGPointMake(size.width-trangleWidth, tranglePadding+trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(size.width-trangleWidth, size.height-conner)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width-trangleWidth-conner, size.height) controlPoint:CGPointMake(size.width-trangleWidth, size.height)];
    [bezierPath addLineToPoint:CGPointMake(conner, size.height)];
    [bezierPath addQuadCurveToPoint:CGPointMake(0, size.height-conner) controlPoint:CGPointMake(0, size.height)];
    [bezierPath addLineToPoint:CGPointMake(0, conner)];
    [bezierPath addQuadCurveToPoint:CGPointMake(conner, 0) controlPoint:CGPointMake(0, 0)];
    
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
        _label.font = [UIFont systemFontOfSize:14];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.text = self.labelString;
        _label.adjustsFontSizeToFitWidth = YES;
    }
    return _label;
}

@end
