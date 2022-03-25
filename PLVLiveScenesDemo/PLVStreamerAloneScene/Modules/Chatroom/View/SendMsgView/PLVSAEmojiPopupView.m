//
//  PLVSAEmojiPopupView.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/7/15.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAEmojiPopupView.h"
#import "PLVEmoticonManager.h"

#import <SDWebImage/UIImageView+WebCache.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat PLVSAEmojiPopupViewArrowRoundRadius = 4.f;//箭头的圆角
static CGFloat PLVSAEmojiPopupViewArrowHeight_R = 12.f;//带圆角箭头的高
static CGFloat PLVSAEmojiPopupViewArrowHeight = 10.f;//不带圆角箭头的高
static CGFloat PLVSAEmojiPopupViewArrowWidth_R = 12.f;//带圆角箭头的宽
static CGFloat PLVSAEmojiPopupViewArrowWidth  = 10.f;//不带圆角箭头的宽
static CGFloat PLVSAEmojiPopupViewSizeWidth = 80;//长按弹出层视图宽

@interface PLVSAEmojiPopupView ()

//展示图片表情的视图
@property (nonatomic, strong) UIImageView *imageView;
//弹出的主视图包括箭头
@property (nonatomic, strong) UIView *mainView;
//视图层包括箭头
@property (nonatomic, strong) CAShapeLayer *backgroundLayer;
//箭头是否是圆角
@property (nonatomic, assign) BOOL allowRoundedArrow;
//主视图的圆角
@property (nonatomic, assign) CGFloat mainViewCornerRadius;

@property (nonatomic, readonly) UIWindow *frontWindow;

@end

@implementation PLVSAEmojiPopupView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
        self.alpha = 0.0f;
        _mainViewCornerRadius = 4.0f;
        
        UITapGestureRecognizer *tapGusture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGustureEvent)];
        [self addGestureRecognizer:tapGusture];
        
        [self addSubview:self.mainView];
        [self.mainView addSubview:self.imageView];
    }
    return self;
}

#pragma mark - Getter && Setter

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.frame = CGRectMake(2, 2, PLVSAEmojiPopupViewSizeWidth - 4, PLVSAEmojiPopupViewSizeWidth - 4);
    }
    return _imageView;
}
- (UIView *)mainView {
    if (!_mainView) {
        _mainView = [[UIView alloc] init];
        _mainView.bounds = CGRectMake(0, 0, PLVSAEmojiPopupViewSizeWidth, PLVSAEmojiPopupViewSizeWidth + 10);
    }
    return _mainView;
}
- (UIWindow *)frontWindow {
    NSEnumerator *frontToBackWindows = [UIApplication.sharedApplication.windows reverseObjectEnumerator];
    for (UIWindow *window in frontToBackWindows) {
        BOOL windowOnMainScreen = window.screen == UIScreen.mainScreen;
        BOOL windowIsVisible = !window.hidden && window.alpha > 0;
        BOOL windowLevelSupported = (window.windowLevel >= UIWindowLevelNormal && window.windowLevel <= UIWindowLevelNormal);
        BOOL windowKeyWindow = window.isKeyWindow;
        if(windowOnMainScreen && windowIsVisible && windowLevelSupported && windowKeyWindow) {
            return window;
        }
    }
    return [UIApplication sharedApplication].keyWindow;;
}

- (void)setImageEmotion:(PLVImageEmotion *)imageEmotion {
    [self.imageView sd_setImageWithURL:[NSURL URLWithString:imageEmotion.url]
                      placeholderImage:nil
                               options:SDWebImageRetryFailed];
}

#pragma mark - Private

- (void)showPopupView {
    [self updateUI];
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1.0f;
        [self.frontWindow addSubview:self];
    }];
}
- (void)dismissView {
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}
- (void)updateUI {
    //弹出视图到父视图两边的最近距离
    CGFloat marginHorizontal = 15;
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
//    相对于屏幕的位置
    CGRect absoluteFrame = [self.relyView convertRect:self.relyView.bounds toView:window];
    //计算弹出视图需要显示的位置
    CGRect mainScreenBounds = [UIScreen mainScreen].bounds;
    CGRect mainViewFrame = self.mainView.bounds;
    //箭头的位置
    CGPoint anglePoint = CGPointMake(0, CGRectGetHeight(mainViewFrame));
    //纵坐标不用判断统一在上面显示
    mainViewFrame.origin.y = absoluteFrame.origin.y - CGRectGetHeight(mainViewFrame) - 4;
    //横坐标需要判断位置如果在最左边或者最右边需要特殊处理
    if (absoluteFrame.origin.x < marginHorizontal) {
        mainViewFrame.origin.x = marginHorizontal;
        CGFloat relyViewCentetX = CGRectGetWidth(self.relyView.bounds)/2 + absoluteFrame.origin.x;
        anglePoint.x = relyViewCentetX - marginHorizontal;
    } else if (CGRectGetMaxX(absoluteFrame) > CGRectGetWidth(mainScreenBounds) - marginHorizontal) {
        CGFloat relyViewCentetX = CGRectGetWidth(self.relyView.bounds)/2 + absoluteFrame.origin.x;
        mainViewFrame.origin.x = CGRectGetWidth(mainScreenBounds) - marginHorizontal - CGRectGetWidth(mainViewFrame);
        anglePoint.x = CGRectGetWidth(mainViewFrame) - ([UIScreen mainScreen].bounds.size.width - relyViewCentetX - marginHorizontal);

    } else {
        mainViewFrame.origin.x = absoluteFrame.origin.x - (CGRectGetWidth(mainViewFrame) - CGRectGetWidth(self.relyView.bounds))/2;
        anglePoint.x = CGRectGetWidth(mainViewFrame)/2;
    }
    self.mainView.frame = mainViewFrame;

    [self drawBackgroundLayerWithAnglePoint:anglePoint addView:self.mainView];
}
///绘制箭头和填充背景
- (void)drawBackgroundLayerWithAnglePoint:(CGPoint)anglePoint addView:(UIView *)addView {
    if (_backgroundLayer) {
        [_backgroundLayer removeFromSuperlayer];
    }
    CGFloat arrowHeight = _allowRoundedArrow ? PLVSAEmojiPopupViewArrowHeight_R : PLVSAEmojiPopupViewArrowHeight;
    CGFloat arrowWidth = _allowRoundedArrow ? PLVSAEmojiPopupViewArrowWidth_R : PLVSAEmojiPopupViewArrowWidth;
    UIBezierPath *path = [UIBezierPath bezierPath];
    BOOL allowRoundedArrow = _allowRoundedArrow;
    CGFloat offset = 2.f*PLVSAEmojiPopupViewArrowRoundRadius*sinf(M_PI_4/2.f);
    CGFloat roundcenterHeight = offset + PLVSAEmojiPopupViewArrowRoundRadius*sqrtf(2.f);
    CGFloat mainViewCornerRadius = self.mainViewCornerRadius;
    CGPoint roundcenterPoint = CGPointMake(anglePoint.x, anglePoint.y - roundcenterHeight);
    if (allowRoundedArrow) {
        [path addArcWithCenter:CGPointMake(anglePoint.x + arrowWidth, anglePoint.y - arrowHeight + 2.f*PLVSAEmojiPopupViewArrowRoundRadius) radius:2.f*PLVSAEmojiPopupViewArrowRoundRadius startAngle:M_PI_2*3 endAngle:M_PI_4*5.f clockwise:NO];
        [path addLineToPoint:CGPointMake(anglePoint.x + PLVSAEmojiPopupViewArrowRoundRadius/sqrtf(2.f), roundcenterPoint.y + PLVSAEmojiPopupViewArrowRoundRadius/sqrtf(2.f))];
        [path addArcWithCenter:roundcenterPoint radius:PLVSAEmojiPopupViewArrowRoundRadius startAngle:M_PI_4 endAngle:M_PI_4*3.f clockwise:YES];
        [path addLineToPoint:CGPointMake(anglePoint.x - arrowWidth + (offset * (1.f+1.f/sqrtf(2.f))), anglePoint.y - arrowHeight + offset/sqrtf(2.f))];
        [path addArcWithCenter:CGPointMake(anglePoint.x - arrowWidth, anglePoint.y - arrowHeight + 2.f*PLVSAEmojiPopupViewArrowRoundRadius) radius:2.f*PLVSAEmojiPopupViewArrowRoundRadius startAngle:M_PI_4*7 endAngle:M_PI_2*3 clockwise:NO];
    } else {
        [path moveToPoint:CGPointMake(anglePoint.x + arrowWidth, anglePoint.y - arrowHeight)];
        [path addLineToPoint:anglePoint];
        [path addLineToPoint:CGPointMake(anglePoint.x - arrowWidth, anglePoint.y - arrowHeight)];
    }
    
    [path addLineToPoint:CGPointMake( mainViewCornerRadius, anglePoint.y - arrowHeight)];
    [path addArcWithCenter:CGPointMake(mainViewCornerRadius, anglePoint.y - arrowHeight - mainViewCornerRadius) radius:mainViewCornerRadius startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
    [path addLineToPoint:CGPointMake( 0, mainViewCornerRadius)];
    [path addArcWithCenter:CGPointMake(mainViewCornerRadius, mainViewCornerRadius) radius:mainViewCornerRadius startAngle:M_PI endAngle:-M_PI_2 clockwise:YES];
    [path addLineToPoint:CGPointMake( addView.bounds.size.width - mainViewCornerRadius, 0)];
    [path addArcWithCenter:CGPointMake(addView.bounds.size.width - mainViewCornerRadius, mainViewCornerRadius) radius:mainViewCornerRadius startAngle:-M_PI_2 endAngle:0 clockwise:YES];
    [path addLineToPoint:CGPointMake(addView.bounds.size.width , anglePoint.y - (mainViewCornerRadius + arrowHeight))];
    [path addArcWithCenter:CGPointMake(addView.bounds.size.width - mainViewCornerRadius, anglePoint.y - (mainViewCornerRadius + arrowHeight)) radius:mainViewCornerRadius startAngle:0 endAngle:M_PI_2 clockwise:YES];
    [path closePath];
    
    _backgroundLayer = [CAShapeLayer layer];
    _backgroundLayer.path = path.CGPath;
    _backgroundLayer.lineWidth = 1.0;
    UIColor *backgroundColor = [PLVColorUtil colorFromHexString:@"#000000" alpha:0.8];
    _backgroundLayer.fillColor = backgroundColor.CGColor;
    _backgroundLayer.strokeColor = backgroundColor.CGColor;
    [addView.layer insertSublayer:_backgroundLayer atIndex:0];
}

#pragma mark - Gusture

- (void)tapGustureEvent {
    [self dismissView];
}

@end
