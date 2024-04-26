//
//  PLVLCDocumentToolViewPopup.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/10/20.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLCDocumentToolViewPopup.h"
#import "PLVMultiLanguageManager.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCDocumentToolViewPopup()

#pragma mark UI
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UILabel *tipLabel;

#pragma mark 数据
@property (nonatomic, assign) CGSize menuSize;

@end

@implementation PLVLCDocumentToolViewPopup

#pragma mark - [ Life Cycle ]

- (instancetype)initWithMenuFrame:(CGRect)frame {
    self = [super init];
    if (self) {
        self.frame = [UIScreen mainScreen].bounds;
        self.backgroundColor = [UIColor clearColor];
        
        self.menuSize = frame.size;
        self.menuView.frame = frame;
        
        [self addSubview:self.menuView];
        [self.menuView addSubview:self.tipLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.tipLabel.frame = CGRectMake(0, 0, self.menuSize.width, self.menuSize.height - 6);
    
    UIBezierPath *bezierPath = [self BezierPathWithSize:self.menuSize];
    CAShapeLayer* shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = bezierPath.CGPath;
    _menuView.layer.mask = shapeLayer;
}

#pragma mark - [ Override ]

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *touchView = [super hitTest:point withEvent:event];
    if (touchView != self.menuView) {
        [self dismiss];
    }
    return touchView;
}

#pragma mark - [ Public Method ]

- (void)showInView:(UIView *)parentView {
    if (parentView) {
        [parentView addSubview:self];
    }
}

- (void)dismiss {
    [self removeFromSuperview];
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (UIView *)menuView {
    if (!_menuView) {
        _menuView = [[UIView alloc] init];
        _menuView.backgroundColor = [UIColor whiteColor];
        _menuView.layer.masksToBounds = YES;
    }
    return _menuView;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.font = [UIFont systemFontOfSize:12];
        _tipLabel.textColor = [PLVColorUtil colorFromHexString:@"#333333"];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.text = PLVLocalizedString(@"点击回到当前页");
    }
    return _tipLabel;
}

- (UIBezierPath *)BezierPathWithSize:(CGSize)size {
    CGFloat conner = 6.0; // 圆角角度
    CGFloat trangleHeight = 6.0; // 尖角高度
    CGFloat trangleWidth = 6.0; // 尖角半径
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    // 起点
    [bezierPath moveToPoint:CGPointMake(conner, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width - conner, 0)];
    
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width, conner) controlPoint:CGPointMake(size.width, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width, size.height- conner - trangleHeight)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width-conner, size.height - trangleHeight) controlPoint:CGPointMake(size.width, size.height - trangleHeight)];


    
    [bezierPath addLineToPoint:CGPointMake(size.width / 2 + trangleWidth, size.height - trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(size.width / 2, size.height)];
    [bezierPath addLineToPoint:CGPointMake(size.width / 2 - trangleWidth, size.height - trangleHeight)];
    
    [bezierPath addLineToPoint:CGPointMake(conner, size.height - trangleHeight)];
    [bezierPath addQuadCurveToPoint:CGPointMake(0, size.height - conner - trangleHeight) controlPoint:CGPointMake(0, size.height - trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(0, conner)];
    [bezierPath addQuadCurveToPoint:CGPointMake(conner, 0) controlPoint:CGPointMake(0, 0)];
    

    [bezierPath closePath];
    return bezierPath;
}

@end
