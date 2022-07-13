//
//  PLVLCCardPushPopupView.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2022/7/6.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCCardPushPopupView.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVLCCardPushPopupView ()

/// UI
@property (nonatomic, strong) UIBezierPath *bezierPath;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@property (nonatomic, assign) PLVLCCardPushPopupDirection popupDirection;

@end

@implementation PLVLCCardPushPopupView

- (instancetype)init {
    self = [super init];
    if (self) {
        _popupDirection = PLVLCCardPushPopupDirectionTop;
        
        [self addSubview:self.titleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    if (_popupDirection == PLVLCCardPushPopupDirectionTop) {
        self.bezierPath = [[self class] aboveBezierPathWithSize:CGSizeMake(width, height)];
        self.titleLabel.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - 6);
    } else if (_popupDirection == PLVLCCardPushPopupDirectionLeft) {
        self.bezierPath = [[self class] leftBezierPathWithSize:CGSizeMake(width, height)];
        self.titleLabel.frame = CGRectMake(0, 0, self.frame.size.width - 6, self.frame.size.height);
    }
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = self.bezierPath.CGPath;
    self.layer.mask = shapeLayer;
    
    self.gradientLayer.frame = self.layer.bounds;
    [self.layer insertSublayer:self.gradientLayer atIndex:0];
}

#pragma mark - [ Public Method ]

- (void)setPopupViewDirection:(PLVLCCardPushPopupDirection)popupDirection {
    _popupDirection = popupDirection;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setPopupViewTitle:(NSString *)title {
    self.titleLabel.text = [PLVFdUtil checkStringUseable:title] ? title : @"连续观看有奖励哦";
}

#pragma mark - [ Private Method ]

#pragma mark - Getter & Setter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:13];
        _titleLabel.text = @"连续观看有奖励哦";
    }
    return _titleLabel;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.colors = @[(__bridge id)[PLVColorUtil colorFromHexString:@"#FD8121"].CGColor, (__bridge id)[PLVColorUtil colorFromHexString:@"#F6A125"].CGColor];
        gradientLayer.locations = @[@(0), @(1.0f)];
        gradientLayer.endPoint = CGPointMake(0, 0.5);
        _gradientLayer = gradientLayer;
    }
    return _gradientLayer;
}

+ (UIBezierPath *)aboveBezierPathWithSize:(CGSize)size {
    CGFloat conner = 4.0; // 圆角大小
    CGFloat trangleHeight = 6.0; // 箭头高度
    CGFloat trangleWidthForHalf = 6.0; // 箭头宽度的一半

    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    
    // 从左上角开始，顺时针绘制气泡
    [bezierPath moveToPoint:CGPointMake(conner, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width-conner, 0)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width, conner) controlPoint:CGPointMake(size.width, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width, size.height- conner - trangleHeight)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width - conner, size.height - trangleHeight) controlPoint:CGPointMake(size.width, size.height - trangleHeight)];
    
    // 从右往左绘制箭头
    [bezierPath addLineToPoint:CGPointMake(size.width/2 + trangleWidthForHalf, size.height - trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(size.width/2, size.height)];
    [bezierPath addLineToPoint:CGPointMake(size.width/2 - trangleWidthForHalf, size.height - trangleHeight)];
    
    // 继续顺时针绘制气泡
    [bezierPath addLineToPoint:CGPointMake(conner, size.height - trangleHeight)];
    [bezierPath addQuadCurveToPoint:CGPointMake(0, size.height - conner - trangleHeight) controlPoint:CGPointMake(0, size.height - trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(0, conner)];
    [bezierPath addQuadCurveToPoint:CGPointMake(conner, 0) controlPoint:CGPointMake(0, 0)];
    
    // 气泡绘制完毕，关闭贝塞尔曲线
    [bezierPath closePath];
    return bezierPath;
}

+ (UIBezierPath *)leftBezierPathWithSize:(CGSize)size {
    CGFloat conner = 4.0; // 圆角大小
    CGFloat trangleHeight = 6.0; // 箭头高度
    CGFloat trangleWidthForHalf = 6.0; // 箭头宽度的一半

    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    
    // 从左上角开始，顺时针绘制气泡
    [bezierPath moveToPoint:CGPointMake(conner, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width-trangleHeight-conner, 0)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width-trangleHeight, conner) controlPoint:CGPointMake(size.width-trangleHeight, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width-trangleHeight, size.height/2 - trangleWidthForHalf)];
    
    // 从上向下绘制箭头
    [bezierPath addLineToPoint:CGPointMake(size.width, size.height/2)];
    [bezierPath addLineToPoint:CGPointMake(size.width - trangleHeight, size.height/2 + trangleWidthForHalf)];
    
    // 继续顺时针绘制气泡
    [bezierPath addLineToPoint:CGPointMake(size.width-trangleHeight, size.height- conner)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width - conner-trangleHeight, size.height) controlPoint:CGPointMake(size.width-trangleHeight, size.height)];
    [bezierPath addLineToPoint:CGPointMake(conner, size.height)];
    [bezierPath addQuadCurveToPoint:CGPointMake(0, size.height - conner) controlPoint:CGPointMake(0, size.height)];
    [bezierPath addLineToPoint:CGPointMake(0, conner)];
    [bezierPath addQuadCurveToPoint:CGPointMake(conner, 0) controlPoint:CGPointMake(0, 0)];
    
    // 气泡绘制完毕，关闭贝塞尔曲线
    [bezierPath closePath];
    return bezierPath;
}

@end
