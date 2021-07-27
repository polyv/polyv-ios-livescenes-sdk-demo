//
//  PLVLSLinkMicMenuPopup.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/4/15.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSLinkMicMenuPopup.h"
#import "PLVLSUtils.h"
#import <PLVFoundationSDK/PLVColorUtil.h>

@interface PLVLSLinkMicMenuPopup ()

@property (nonatomic, strong) UIView *linkMicButtonMask;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIButton *videoLinkMicBtn;
@property (nonatomic, strong) UIButton *audioLinkMicBtn;
@property (nonatomic, strong) UIView *line;

@property (nonatomic, assign) CGSize menuSize;
@property (nonatomic, assign) CGRect firstButtonRect;
@property (nonatomic, assign) CGRect secondButtonRect;

@end

@implementation PLVLSLinkMicMenuPopup

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
        
        self.firstButtonRect = CGRectMake(0, 8, frame.size.width, 44);
        self.videoLinkMicBtn.frame = self.firstButtonRect;
        [self.menuView addSubview:self.videoLinkMicBtn];
        
        self.secondButtonRect = CGRectMake(0, 44 + 8, frame.size.width, 44);
        self.audioLinkMicBtn.frame = self.secondButtonRect;
        [self.menuView addSubview:self.audioLinkMicBtn];
        
        self.line.frame = CGRectMake(12, 8 + 44, frame.size.width - 24, 1);
        [self.menuView addSubview:self.line];
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
        touchView != self.videoLinkMicBtn &&
        touchView != self.audioLinkMicBtn) {
        [self dismiss];
    }
    return touchView;
}

#pragma mark - [ Public Method ]

#pragma mark UI

- (void)showAtView:(UIView *)superView {
    [superView addSubview:self];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    if (self.audioLinkMicBtn.selected ||
        self.videoLinkMicBtn.selected) {
        [self performSelector:@selector(dismiss) withObject:nil afterDelay:3.0];
    }
}

- (void)dismiss {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    [self removeFromSuperview];
    
    if (self.dismissHandler) {
        self.dismissHandler();
    }
}

- (void)resetStatus{
    self.videoLinkMicBtn.selected = NO;
    self.audioLinkMicBtn.selected = NO;
    
    self.videoLinkMicBtn.hidden = NO;
    self.audioLinkMicBtn.hidden = NO;
    
    [self updateMenu];
    
    self.audioLinkMicBtn.frame = self.videoLinkMicBtn.hidden ? self.firstButtonRect : self.secondButtonRect;
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

- (UIButton *)videoLinkMicBtn {
    if (!_videoLinkMicBtn) {
        _videoLinkMicBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVLSUtils imageForStatusResource:@"plvls_status_linkmic_camera_icon"];
        UIImage *selectedImage = [PLVLSUtils imageForStatusResource:@"plvls_status_linkmic_camera_icon_selected"];
        [_videoLinkMicBtn setImage:normalImage forState:UIControlStateNormal];
        [_videoLinkMicBtn setImage:selectedImage forState:UIControlStateSelected];
        [_videoLinkMicBtn setTitle:@"视频连麦" forState:UIControlStateNormal];
        [_videoLinkMicBtn setTitle:@"结束连麦" forState:UIControlStateSelected];
        _videoLinkMicBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_videoLinkMicBtn setTitleColor:[PLVColorUtil colorFromHexString:@"#F0F1F5"] forState:UIControlStateNormal];
        [_videoLinkMicBtn setTitleColor:[PLVColorUtil colorFromHexString:@"#4399FF"] forState:UIControlStateSelected];
        [_videoLinkMicBtn addTarget:self action:@selector(videoLinkMicBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _videoLinkMicBtn;
}

- (UIButton *)audioLinkMicBtn {
    if (!_audioLinkMicBtn) {
        _audioLinkMicBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *normalImage = [PLVLSUtils imageForStatusResource:@"plvls_status_linkmic_micro_icon"];
        UIImage *selectedImage = [PLVLSUtils imageForStatusResource:@"plvls_status_linkmic_micro_icon_selected"];
        [_audioLinkMicBtn setImage:normalImage forState:UIControlStateNormal];
        [_audioLinkMicBtn setImage:selectedImage forState:UIControlStateSelected];
        [_audioLinkMicBtn setTitle:@"语音连麦" forState:UIControlStateNormal];
        [_audioLinkMicBtn setTitle:@"结束连麦" forState:UIControlStateSelected];
        _audioLinkMicBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_audioLinkMicBtn setTitleColor:[PLVColorUtil colorFromHexString:@"#F0F1F5"] forState:UIControlStateNormal];
        [_audioLinkMicBtn setTitleColor:[PLVColorUtil colorFromHexString:@"#4399FF"] forState:UIControlStateSelected];
        [_audioLinkMicBtn addTarget:self action:@selector(audioLinkMicBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _audioLinkMicBtn;
}

- (UIView *)line {
    if (!_line) {
        _line = [[UIView alloc] init];
        _line.backgroundColor = [PLVColorUtil colorFromHexString:@"#1B202D" alpha:0.3];
    }
    return _line;
}

#pragma mark UI

- (void)updateMenu {
    BOOL unSelected = !self.videoLinkMicBtn.selected && !self.audioLinkMicBtn.selected;
    self.menuSize = CGSizeMake(106, 44 * (unSelected ? 2 : 1) + 8);
    
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

- (void)videoLinkMicBtnAction:(id)sender {
    if (self.videoLinkMicButtonHandler) {
        BOOL needChange = self.videoLinkMicButtonHandler(!self.videoLinkMicBtn.selected);
        if (needChange) {
            self.videoLinkMicBtn.selected = !self.videoLinkMicBtn.selected;
            self.audioLinkMicBtn.hidden = self.videoLinkMicBtn.selected;
            [self updateMenu];
        }
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    [self dismiss];
}

- (void)audioLinkMicBtnAction:(id)sender {
    if (self.audioLinkMicButtonHandler) {
        BOOL needChange = self.audioLinkMicButtonHandler(!self.audioLinkMicBtn.selected);
        if (needChange) {
            self.audioLinkMicBtn.selected = !self.audioLinkMicBtn.selected;
            self.videoLinkMicBtn.hidden = self.audioLinkMicBtn.selected;
            [self updateMenu];
            
            self.audioLinkMicBtn.frame = self.videoLinkMicBtn.hidden ? self.firstButtonRect : self.secondButtonRect;
        }
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    [self dismiss];
}

@end
