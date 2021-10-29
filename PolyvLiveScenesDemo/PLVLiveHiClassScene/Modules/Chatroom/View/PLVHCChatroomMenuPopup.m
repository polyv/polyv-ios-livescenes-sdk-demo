//
//  PLVHCChatroomMenuPopup.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/8/2.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCChatroomMenuPopup.h"

// 工具
#import "PLVHCUtils.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCChatroomMenuPopup()

#pragma mark UI
@property (nonatomic, strong) UIButton *copyButton;
@property (nonatomic, strong) UIButton *replyButton;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UIView *menuView;

#pragma mark 数据
@property (nonatomic, assign) CGSize menuSize;

@end

@implementation PLVHCChatroomMenuPopup

#pragma mark - [ Life Cycle ]

- (instancetype)initWithMenuFrame:(CGRect)frame buttonFrame:(CGRect)buttonFrame {
    self = [super init];
    if (self) {
        self.frame = [UIScreen mainScreen].bounds;
        self.backgroundColor = [UIColor clearColor];
        
        self.menuSize = frame.size;
        self.menuView.frame = frame;
        
        [self addSubview:self.menuView];
        [self.menuView addSubview:self.copyButton];
        [self.menuView addSubview:self.replyButton];
        [self.menuView addSubview:self.lineView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.allowCopy) {
        self.copyButton.frame = CGRectMake(0, 0, 59, 32);
    }
    
    if (self.allowReply) {
        self.replyButton.frame = CGRectMake(self.menuView.frame.size.width - 59, 0, 59, 32);
    }
    
    self.lineView.frame = CGRectMake((self.menuView.frame.size.width - 1 ) / 2, (self.menuView.frame.size.height - 14 ) / 2, 1, 14);
    UIBezierPath *bezierPath = [self BezierPathWithSize:self.menuSize];
    CAShapeLayer* shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = bezierPath.CGPath;
    _menuView.layer.mask = shapeLayer;
}

#pragma mark - [ Override ]

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *touchView = [super hitTest:point withEvent:event];

    if (touchView != self.menuView &&
        touchView != self.copyButton &&
        touchView != self.replyButton) {
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
    if (self.dismissHandler) {
        self.dismissHandler();
    }
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (UIButton *)copyButton {
    if (!_copyButton) {
        _copyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _copyButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_copyButton setTitleColor:[PLVColorUtil colorFromHexString:@"#333333"] forState:UIControlStateNormal];
        [_copyButton setTitle:@"复制" forState:UIControlStateNormal];
        [_copyButton addTarget:self action:@selector(copyButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _copyButton;
}

- (UIButton *)replyButton {
    if (!_replyButton) {
        _replyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _replyButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_replyButton setTitleColor:[PLVColorUtil colorFromHexString:@"#333333"] forState:UIControlStateNormal];
        [_replyButton setTitle:@"回复" forState:UIControlStateNormal];
        [_replyButton addTarget:self action:@selector(replyButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _replyButton;
}

- (UIView *)menuView {
    if (!_menuView) {
        _menuView = [[UIView alloc] init];
        _menuView.backgroundColor = [UIColor whiteColor];
        _menuView.layer.masksToBounds = YES;
    }
    return _menuView;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1];
    }
    return _lineView;
}

- (UIBezierPath *)BezierPathWithSize:(CGSize)size {
    CGFloat conner = 8.0; // 圆角角度
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

#pragma mark - [ Event ]
#pragma mark Action

- (void)copyButtonAction {
    if (self.copyButtonHandler) {
        self.copyButtonHandler();
    }
    [self dismiss];
}

- (void)replyButtonAction {
    if (self.replyButtonHandler) {
        self.replyButtonHandler();
    }
    [self dismiss];
}

@end
