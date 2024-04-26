//
//  PLVLSLinkMicGuestMenuPopup.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/5/18.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVLSLinkMicGuestMenuPopup.h"

#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVColorUtil.h>

@interface PLVLSLinkMicGuestMenuPopup ()

@property (nonatomic, strong) UIView *linkMicButtonMask;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIButton *cancelRequestLinkMicBtn;
@property (nonatomic, strong) UIButton *closeLinkMicBtn;

/// 数据
@property (nonatomic, assign) CGSize menuSize;
@property (nonatomic, assign) CGRect firstButtonRect;
@property (nonatomic, assign, getter=isGuest) BOOL guest; // 是否为嘉宾

@end

@implementation PLVLSLinkMicGuestMenuPopup

#pragma mark - [ Life Cycle ]

- (instancetype)initWithMenuFrame:(CGRect)frame buttonFrame:(CGRect)buttonFrame {
    self = [super init];
    if (self) {
        self.frame = [UIScreen mainScreen].bounds;
        self.backgroundColor = [UIColor clearColor];
        
        self.menuSize = frame.size;
        self.menuView.frame = frame;
        [self addSubview:self.menuView];
        self.linkMicButtonMask.frame = buttonFrame;
        [self addSubview:self.linkMicButtonMask];
        
        [self setupUI];
    }
    return self;
}

#pragma mark - [ Override ]

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *touchView = [super hitTest:point withEvent:event];
    if (touchView == self.linkMicButtonMask) {
        return nil;
    }
    if (touchView != self.menuView &&
        touchView != self.cancelRequestLinkMicBtn &&
        touchView != self.closeLinkMicBtn) {
        [self dismiss];
    }
    return touchView;
}

#pragma mark - [ Public Method ]

#pragma mark UI

- (void)showAtView:(UIView *)superView {
    [superView addSubview:self];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    [self performSelector:@selector(dismiss) withObject:nil afterDelay:3.0];
}

- (void)updateMenuPopupInLinkMic:(BOOL)inLinkMic {
    self.cancelRequestLinkMicBtn.hidden = inLinkMic;
    self.closeLinkMicBtn.hidden = !inLinkMic;
}

- (void)dismiss {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    [self removeFromSuperview];
    
    if (self.dismissHandler) {
        self.dismissHandler();
    }
}

#pragma mark - [ Private Method ]

#pragma mark Getter & Setter
- (UIView *)linkMicButtonMask {
    if (!_linkMicButtonMask) {
        _linkMicButtonMask = [[UIView alloc] init];
    }
    return _linkMicButtonMask;
}

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

- (UIButton *)cancelRequestLinkMicBtn {
    if (!_cancelRequestLinkMicBtn) {
        _cancelRequestLinkMicBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelRequestLinkMicBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_cancelRequestLinkMicBtn setTitle:PLVLocalizedString(@"取消申请连麦") forState:UIControlStateNormal];
        [_cancelRequestLinkMicBtn setTitleColor:[PLVColorUtil colorFromHexString:@"#4399FF"] forState:UIControlStateNormal];
        [_cancelRequestLinkMicBtn addTarget:self action:@selector(cancelRequestLinkMicBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelRequestLinkMicBtn;
}

- (UIButton *)closeLinkMicBtn {
    if (!_closeLinkMicBtn) {
        _closeLinkMicBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeLinkMicBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        UIImage *normalImage = [PLVLSUtils imageForStatusResource:@"plvls_status_linkmic_camera_icon_selected"];
        [_closeLinkMicBtn setImage:normalImage forState:UIControlStateNormal];
        [_closeLinkMicBtn setTitle:PLVLocalizedString(@"结束连麦") forState:UIControlStateNormal];
        [_closeLinkMicBtn setTitleColor:[PLVColorUtil colorFromHexString:@"#4399FF"] forState:UIControlStateNormal];
        [_closeLinkMicBtn addTarget:self action:@selector(closeLinkMicBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeLinkMicBtn;
}

#pragma mark UI
- (void)setupUI {
    self.firstButtonRect = CGRectMake(0, 8, self.menuView.frame.size.width, 44);
    self.cancelRequestLinkMicBtn.frame = self.firstButtonRect;
    self.closeLinkMicBtn.frame = self.firstButtonRect;
    [self.menuView addSubview:self.cancelRequestLinkMicBtn];
    [self.menuView addSubview:self.closeLinkMicBtn];
    UIBezierPath *bezierPath = [[self class] BezierPathWithSize:self.menuSize];
    CAShapeLayer* shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = bezierPath.CGPath;
    self.menuView.layer.mask = shapeLayer;
    
    CGRect menuRect =  self.menuView.frame;
    menuRect.size = self.menuSize;
    self.menuView.frame = menuRect;
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

#pragma mark - [ Event ]
#pragma mark Action
- (void)cancelRequestLinkMicBtnAction:(id)sender {
    _cancelRequestLinkMicButtonHandler ? _cancelRequestLinkMicButtonHandler() : nil;
    [self dismiss];
}

- (void)closeLinkMicBtnAction:(id)sender {
    _closeLinkMicButtonHandler ? _closeLinkMicButtonHandler() : nil;
    [self dismiss];
}

@end
