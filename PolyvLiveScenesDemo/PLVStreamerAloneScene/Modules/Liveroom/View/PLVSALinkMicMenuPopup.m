//
//  PLVSALinkMicMenuPopup.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/5/9.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSALinkMicMenuPopup.h"
//模块
#import "PLVRoomDataManager.h"
// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVSALinkMicMenuPopup ()

@property (nonatomic, strong) UIView *linkMicButtonMask;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIButton *videoLinkMicBtn;
@property (nonatomic, strong) UIButton *audioLinkMicBtn;
@property (nonatomic, strong) UIView *line;

@property (nonatomic, assign) CGSize menuSize;
@property (nonatomic, assign) CGRect firstButtonRect;
@property (nonatomic, assign) CGRect secondButtonRect;

@end

@implementation PLVSALinkMicMenuPopup

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
        
        self.firstButtonRect = CGRectMake(0, 0, frame.size.width, 44);
        self.videoLinkMicBtn.frame = self.firstButtonRect;
        [self.menuView addSubview:self.videoLinkMicBtn];
        
        self.secondButtonRect = CGRectMake(0, 44 + 1, frame.size.width, 44);
        self.audioLinkMicBtn.frame = self.secondButtonRect;
        [self.menuView addSubview:self.audioLinkMicBtn];
        
        self.line.frame = CGRectMake(12, 44, frame.size.width - 24, 1);
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

        UIBezierPath *bezierPath = [self BezierPathWithSize:self.menuSize];
        CAShapeLayer* shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = bezierPath.CGPath;
        _menuView.layer.mask = shapeLayer;
    }
    return _menuView;
}

- (UIButton *)videoLinkMicBtn {
    if (!_videoLinkMicBtn) {
        _videoLinkMicBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_videoLinkMicBtn setTitle:@"视频连麦" forState:UIControlStateNormal];
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
        [_audioLinkMicBtn setTitle:@"语音连麦" forState:UIControlStateNormal];
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
- (UIBezierPath *)BezierPathWithSize:(CGSize)size {
    CGFloat conner = 8.0; // 圆角角度
    CGFloat trangleHeight = 8.0; // 尖角高度
    CGFloat trangleWidth = 6.0; // 尖角半径
    CGFloat bottomPadding = 8.0; // 底部间隔
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    // 起点
    [bezierPath moveToPoint:CGPointMake(conner , 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width - conner, 0)];
    
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width, conner) controlPoint:CGPointMake(size.width, 0)]; // 右上角圆角
    [bezierPath addLineToPoint:CGPointMake(size.width, size.height - conner - trangleHeight - bottomPadding)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width-conner, size.height - bottomPadding) controlPoint:CGPointMake(size.width, size.height - bottomPadding)]; // 右下角圆角

    [bezierPath addLineToPoint:CGPointMake(conner, size.height - bottomPadding)];
    [bezierPath addQuadCurveToPoint:CGPointMake(0, size.height - conner - bottomPadding) controlPoint:CGPointMake(0, size.height - bottomPadding)]; // 左下角圆角
    [bezierPath addLineToPoint:CGPointMake(0, conner)];
    [bezierPath addQuadCurveToPoint:CGPointMake(conner, 0) controlPoint:CGPointMake(0, 0)]; // 左上角圆角
    
    // 画尖角
    [bezierPath moveToPoint:CGPointMake(size.width / 2 - trangleWidth, size.height - trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(size.width / 2, size.height)]; // 顶点
    [bezierPath addLineToPoint:CGPointMake(size.width / 2 + trangleWidth, size.height - trangleHeight)];
    
    [bezierPath closePath];
    return bezierPath;
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)videoLinkMicBtnAction:(id)sender {
    self.videoLinkMicButtonHandler ? self.videoLinkMicButtonHandler() : nil;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    [self dismiss];
}

- (void)audioLinkMicBtnAction:(id)sender {
    self.audioLinkMicButtonHandler ? self.audioLinkMicButtonHandler() : nil;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    [self dismiss];
}

@end
