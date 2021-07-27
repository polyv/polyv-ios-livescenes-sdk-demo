//
//  PLVLSLinkMicApplyTipsView.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/4/15.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSLinkMicApplyTipsView.h"
#import <PLVFoundationSDK/PLVColorUtil.h>

@interface PLVLSLinkMicApplyTipsView ()

@property (nonatomic, strong) UILabel *label;

@end

@implementation PLVLSLinkMicApplyTipsView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#1B202D" alpha:0.75];
        self.layer.masksToBounds = YES;

        UIBezierPath *bezierPath = [[self class] BezierPathWithSize:self.frame.size];
        CAShapeLayer* shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = bezierPath.CGPath;
        self.layer.mask = shapeLayer;
        
        self.label.frame = CGRectMake(0, 8, self.frame.size.width, 44);
        [self addSubview:self.label];
    }
    return self;
}

#pragma mark - Getter

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.font = [UIFont systemFontOfSize:14];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
        _label.text = @"收到新的连麦申请";
    }
    return _label;
}

#pragma mark - Public

- (void)showAtView:(UIView *)view {
    [view addSubview:self];
    
    [self performSelector:@selector(dismissInter) withObject:nil afterDelay:3];
}

- (void)dismiss {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissInter) object:nil];
    [self dismissInter];
}

#pragma mark - Private

- (void)dismissInter {
    [self removeFromSuperview];
}

#pragma mark - Utils

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
