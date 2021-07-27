//
//  PLVLSBottomSheet.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/2/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSBottomSheet.h"

static CGFloat kBottomSheetAnimationDuration = 0.5;

@interface PLVLSBottomSheet ()

@property (nonatomic, strong) UIVisualEffectView *effectView; // 高斯模糊效果图
@property (nonatomic, strong) UIView *gestureView; // 手势区域
@property (nonatomic, strong) UIView *contentView; // 底部内容区域
@property (nonatomic, strong) UIView *sliderGesturView; // 顶部滑块拖动区域
@property (nonatomic, strong) UIView *sliderView; // 顶部滑块
@property (nonatomic, assign) CGFloat sheetHight; // 弹层显示时的高度

@end

@implementation PLVLSBottomSheet

#pragma mark - Life Cycle

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight showSlider:(BOOL)showSlider {
    self = [super init];
    if (self) {
        self.sheetHight = MAX(0, sheetHeight);
        
        [self addSubview:self.gestureView];
        [self addSubview:self.contentView];
        [self.contentView addSubview:self.effectView];
        
        if (showSlider) {
            [self.contentView addSubview:self.sliderView];
            [self.contentView addSubview:self.sliderGesturView];
        }
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.sliderView.frame = CGRectMake((self.bounds.size.width - 40) / 2.0, 8, 40, 4);
    self.sliderGesturView.frame = CGRectMake((self.bounds.size.width - 80) / 2.0, 0, 80, 24);
}

#pragma mark - Getter

- (UIVisualEffectView *)effectView {
    if (!_effectView) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    }
    return _effectView;
}

- (UIView *)gestureView {
    if (!_gestureView) {
        _gestureView = [[UIView alloc] init];
        _gestureView.backgroundColor = [UIColor clearColor];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
        [_gestureView addGestureRecognizer:tapGesture];
    }
    return _gestureView;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = [UIColor colorWithRed:0x1B/255.0 green:0x20/255.0 blue:0x2D/255.0 alpha:0.75];
    }
    return _contentView;
}

- (UIView *)sliderView {
    if (!_sliderView) {
        _sliderView = [[UIView alloc] init];
        _sliderView.backgroundColor = [UIColor colorWithRed:0x87/255.0 green:0x8B/255.0 blue:0x93/255.0 alpha:1.0];
        _sliderView.layer.cornerRadius = 3.0;
        _sliderView.layer.masksToBounds = YES;
    }
    return _sliderView;
}

- (UIView *)sliderGesturView {
    if (!_sliderGesturView) {
        _sliderGesturView = [[UIView alloc] init];
        _sliderGesturView.backgroundColor = [UIColor clearColor];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
        [_sliderGesturView addGestureRecognizer:panGesture];
    }
    return _sliderGesturView;
}

#pragma mark - Action

- (void)panGestureAction:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        return;
    }
    
    CGPoint location = [gesture translationInView:self.contentView];
    if (location.x < -20 || location.x > 80 + 20 ||
        location.y < -20 || location.y > 24 + 20) { // 触碰点远离响应热区时取消手势，响应热区大小为 80pt x 24pt
        gesture.state = UIGestureRecognizerStateEnded;
        self.contentView.frame = CGRectMake(0, self.bounds.size.height - self.sheetHight, self.bounds.size.width, self.sheetHight);
        return;
    }
    
    CGPoint translatedPoint = [gesture translationInView:[UIApplication sharedApplication].keyWindow];
    CGFloat yZoom = translatedPoint.y;
    CGRect contentViewRect = self.contentView.frame;
    CGFloat panOriginY = contentViewRect.origin.y + yZoom;
    panOriginY = MAX(panOriginY, self.bounds.size.height - self.sheetHight);
    contentViewRect.origin.y = panOriginY;
    self.contentView.frame = contentViewRect;
    [gesture setTranslation:CGPointMake(0, 0) inView:self.contentView];
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        if (self.contentView.frame.origin.y > self.bounds.size.height - self.sheetHight * 0.5) {
            [self dismissWithoutAnimation];
        } else {
            [self recoverWithoutAnimation];
        }
    }
}

- (void)dismissWithoutAnimation {
    if (!self.superview) {
        return;
    }
    self.contentView.frame = CGRectMake(0, self.bounds.size.height, self.bounds.size.width, self.sheetHight);
    [self removeFromSuperview];
}

- (void)recoverWithoutAnimation {
    self.contentView.frame = CGRectMake(0, self.bounds.size.height - self.sheetHight, self.bounds.size.width, self.sheetHight);
    self.effectView.frame = self.contentView.bounds;
}

#pragma mark - Show & Hide

- (void)showInView:(UIView *)parentView {
    if (!parentView) {
        return;
    }
    
    [parentView addSubview:self];
    [parentView insertSubview:self atIndex:parentView.subviews.count - 1];
    
    [self reset];
    [UIView animateWithDuration:kBottomSheetAnimationDuration animations:^{
        self.contentView.frame = CGRectMake(0, self.bounds.size.height - self.sheetHight, self.bounds.size.width, self.sheetHight);
        self.effectView.frame = self.contentView.bounds;
    } completion:nil];
}

- (void)dismiss {
    if (!self.superview) {
        return;
    }
    
    [UIView animateWithDuration:kBottomSheetAnimationDuration animations:^{
        self.contentView.frame = CGRectMake(0, self.bounds.size.height, self.bounds.size.width, self.sheetHight);
        self.effectView.frame = self.contentView.bounds;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)reset {
    self.frame = self.superview.bounds;
    self.gestureView.frame = self.bounds;
    self.contentView.frame = CGRectMake(0, self.bounds.size.height, self.bounds.size.width, self.sheetHight);
    self.effectView.frame = self.contentView.bounds;
}

@end
