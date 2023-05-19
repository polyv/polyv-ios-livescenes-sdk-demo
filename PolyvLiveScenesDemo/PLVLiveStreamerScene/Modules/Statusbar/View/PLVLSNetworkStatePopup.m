//
//  PLVLSNetworkStatePopup.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/4/15.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSNetworkStatePopup.h"
#import <PLVFoundationSDK/PLVColorUtil.h>

@interface PLVLSNetworkStatePopup ()

@property (nonatomic, assign) BOOL showing;
@property (nonatomic, strong) UIView *outsideButtonMask;
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *firstLineLabel;
@property (nonatomic, strong) UILabel *secondLineLabel;

@property (nonatomic, assign) CGSize bubbleSize;
@property (nonatomic, assign) CGRect firstLabelRect;
@property (nonatomic, assign) CGRect secondLabelRect;

@end

@implementation PLVLSNetworkStatePopup

#pragma mark - [ Life Cycle ]

- (instancetype)initWithBubbleFrame:(CGRect)frame buttonFrame:(CGRect)buttonFrame {
    self = [super init];
    if (self) {
        self.frame = [UIScreen mainScreen].bounds;
        self.backgroundColor = [UIColor clearColor];
        
        self.bubbleSize = frame.size;
        self.bubbleView.frame = frame;
        [self addSubview:self.bubbleView];
        
        self.outsideButtonMask.frame = buttonFrame;
        [self addSubview:self.outsideButtonMask];
        
        CGFloat labelXPadding = 12.0;
        CGFloat labelHeight = 16.0;
        CGFloat labelWidth = frame.size.width - labelXPadding * 2;
        
        self.firstLabelRect = CGRectMake(labelXPadding, 20, labelWidth, labelHeight);
        self.firstLineLabel.frame = self.firstLabelRect;
        [self.bubbleView addSubview:self.firstLineLabel];
        
        self.secondLabelRect = CGRectMake(labelXPadding, CGRectGetMaxY(self.firstLineLabel.frame) + 8, labelWidth, labelHeight);
        self.secondLineLabel.frame = self.secondLabelRect;
        [self.bubbleView addSubview:self.secondLineLabel];
    }
    return self;
}

#pragma mark - [ Override ]

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *touchView = [super hitTest:point withEvent:event];
    if (touchView == self.outsideButtonMask) {
        return nil;
    }
    if (touchView != self.bubbleView &&
        touchView != self.firstLineLabel &&
        touchView != self.secondLineLabel) {
        [self dismiss];
    }
    return touchView;
}

#pragma mark - [ Public Method ]

#pragma mark UI

- (void)showAtView:(UIView *)superView {
    self.showing = YES;
    [superView addSubview:self];
}

- (void)dismiss {
    self.showing = NO;
    [self removeFromSuperview];
}

- (void)refreshWithBubbleFrame:(CGRect)frame buttonFrame:(CGRect)buttonFrame {
    self.frame = [UIScreen mainScreen].bounds;
    
    self.bubbleSize = frame.size;
    self.bubbleView.frame = frame;
    
    self.outsideButtonMask.frame = buttonFrame;
}

- (void)updateRTT:(NSInteger)rtt upLoss:(NSInteger)upLoss downLoss:(NSInteger)downLoss {
    self.firstLineLabel.text = [NSString stringWithFormat:@"网络延迟：%zdms", rtt];
    self.secondLineLabel.text = [NSString stringWithFormat:@"丢包率：↑%zd.0%% ↓%zd.0%%", upLoss, downLoss];
}

#pragma mark - [ Private Method ]

#pragma mark Getter & Setter

- (UIView *)outsideButtonMask {
    if (!_outsideButtonMask) {
        _outsideButtonMask = [[UIView alloc] init];
    }
    return _outsideButtonMask;
}

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [PLVColorUtil colorFromHexString:@"#1B202D" alpha:0.75];
        _bubbleView.layer.masksToBounds = YES;

        UIBezierPath *bezierPath = [[self class] BezierPathWithSize:self.bubbleSize];
        CAShapeLayer* shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = bezierPath.CGPath;
        _bubbleView.layer.mask = shapeLayer;
    }
    return _bubbleView;
}

- (UILabel *)firstLineLabel {
    if (!_firstLineLabel) {
        _firstLineLabel = [[UILabel alloc] init];
        _firstLineLabel.font = [UIFont systemFontOfSize:14];
        _firstLineLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
        _firstLineLabel.text = @"网络延迟：ms";
    }
    return _firstLineLabel;
}

- (UILabel *)secondLineLabel {
    if (!_secondLineLabel) {
        _secondLineLabel = [[UILabel alloc] init];
        _secondLineLabel.font = [UIFont systemFontOfSize:14];
        _secondLineLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
        _secondLineLabel.text = @"丢包率：↑0.0% ↓0.0%";
    }
    return _secondLineLabel;
}

#pragma mark UI

+ (UIBezierPath *)BezierPathWithSize:(CGSize)size {
    CGFloat conner = 8.0;
    CGFloat trangleHeight = 8.0;
    CGFloat trangleWidthForHalf = 6.0;

    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint:CGPointMake(conner, trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(150, trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(150 + trangleWidthForHalf, 0)];
    [bezierPath addLineToPoint:CGPointMake(150 + trangleWidthForHalf * 2.0, trangleHeight)];
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
