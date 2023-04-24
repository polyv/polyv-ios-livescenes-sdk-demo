//
//  PLVECFloatingWindow.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/2.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECFloatingWindow.h"
#import "PLVECUtils.h"

@interface PLVECFloatingWindow ()

#pragma mark - UI
/// 悬浮窗尺寸
@property (nonatomic, assign) CGSize windowSize;
/// 悬浮窗初始位置，默认为离屏幕底部 16pt，离屏幕右侧 16pt
@property (nonatomic, assign) CGPoint originPoint;
/// 需要在悬浮窗上显示的，由外部带入的视图，与悬浮窗口等尺寸
@property (nonatomic, strong) UIView *containerView;
/// 关闭按钮
@property (nonatomic, strong) UIButton *closeButton;
/// 返回按钮
@property (nonatomic, strong) UIButton *backButton;

#pragma mark 手势
/// 拖动手势
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;

@end

@implementation PLVECFloatingWindow

#pragma mark - [ Life Cycle ]

- (void)layoutSubviews {
    self.containerView.frame = self.bounds;
}

#pragma mark - 初始化

+ (instancetype)sharedInstance {
    static PLVECFloatingWindow *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [self new];
    });
    return _sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.backgroundColor = [UIColor blackColor];
        self.hidden = YES;
        self.windowLevel = UIWindowLevelNormal + 1;
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = YES;
        
        [self resetPosition];
        
        // 添加手势
        [self addGestureRecognizer:self.panGestureRecognizer];
        
        [self addSubview:self.containerView];
        [self addSubview:self.backButton];
        [self addSubview:self.closeButton];
    }
    return self;
}

- (void)resetPosition {
    self.windowSize = CGSizeMake(90, 160);
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    self.originPoint = CGPointMake(screenSize.width - self.windowSize.width - 16, screenSize.height - self.windowSize.height - 16);
    
    self.frame = CGRectMake(self.originPoint.x, self.originPoint.y, self.windowSize.width, self.windowSize.height);
    self.backButton.frame = self.bounds;
}

#pragma mark - Getter

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
        _containerView.backgroundColor = [UIColor clearColor];
    }
    return _containerView;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeButton.frame = CGRectMake(self.windowSize.width - 24, 0, 24, 24);
        UIImage *image = [PLVECUtils imageForWatchResource:@"plv_floating_winow_close_btn"];
        [_closeButton setImage:image forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

#pragma mark - Action

- (void)closeAction {
    [self closeAndBack:NO];
}

- (void)backAction {
    [self closeAndBack:YES];
}

- (void)closeAndBack:(BOOL)back {
    [self close];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(floatingWindow_closeWindowAndBack:)]) {
        [self.delegate floatingWindow_closeWindowAndBack:back];
    }
}

#pragma mark - Public

- (void)showContentView:(UIView *)contentView {
    self.hidden = NO;
    
    for (UIView * subview in self.containerView.subviews) {
        [subview removeFromSuperview];
    }
    
    if (!contentView) {
        return;
    }
    
    [self.containerView addSubview:contentView];
    contentView.frame = self.containerView.bounds;
    contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    contentView.userInteractionEnabled = YES;
}

- (void)close {
    self.hidden = YES;
    [self resetPosition];
}

#pragma mark - 手势

- (UIPanGestureRecognizer *)panGestureRecognizer {
    if (!_panGestureRecognizer) {
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragWindow:)];
    }
    return _panGestureRecognizer;
}

- (void)dragWindow:(UIPanGestureRecognizer *)gesture {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    CGPoint translatedPoint = [gesture translationInView:[UIApplication sharedApplication].keyWindow];
    CGFloat x = gesture.view.center.x + translatedPoint.x;
    CGFloat y = gesture.view.center.y + translatedPoint.y;
    
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        gesture.view.center = CGPointMake(x, y);
        [gesture setTranslation:CGPointMake(0, 0) inView:[UIApplication sharedApplication].keyWindow];
        return;
    }
    
    CGFloat navigationHeight = [[UIApplication sharedApplication] statusBarFrame].size.height + 44;
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    
    if (x > screenSize.width - 0.5 * width) {// 不允许拖离屏幕右侧
        x = screenSize.width - 0.5 * width;
    } else if (x < width * 0.5) { // 不允许拖离屏幕左侧
        x = width * 0.5;
    }
    
    if (y > screenSize.height - height * 0.5) { // 不允许拖离屏幕底部
        y = screenSize.height - height * 0.5;
    } else if (y < height * 0.5 + navigationHeight) { // 不允许往上拖到挡住导航栏
        y = height * 0.5 + navigationHeight;
    }
    
    gesture.view.center = CGPointMake(x, y);
    [gesture setTranslation:CGPointMake(0, 0) inView:[UIApplication sharedApplication].keyWindow];
}

@end
