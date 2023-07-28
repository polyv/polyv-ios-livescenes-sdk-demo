//
//  PLVECFloatingWindow.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/2.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECFloatingWindow.h"
#import "PLVECUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVECFloatingWindow ()

#pragma mark - 数据
@property (nonatomic, strong) UINavigationController *holdingNavigation;

#pragma mark - UI
/// 悬浮窗尺寸
@property (nonatomic, assign) CGSize windowSize;
/// 悬浮窗初始位置，默认为离屏幕底部 16pt，离屏幕右侧 16pt
@property (nonatomic, assign) CGPoint originPoint;
/// 需要在悬浮窗上显示的，由外部带入的视图，与悬浮窗口等尺寸
@property (nonatomic, strong) UIView *containerView;
/// 外部视图
@property (nonatomic, strong) UIView *contentView;
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutSubviews {
    self.containerView.frame = self.bounds;
    self.contentView.frame = self.containerView.bounds;
    self.closeButton.frame = CGRectMake(self.windowSize.width - 24, 0, 24, 24);
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeOrientation:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    }
    return self;
}

- (void)resetPosition {
    [self resetPositionWithSize:CGSizeMake(90, 160)];
}

- (void)resetPositionWithSize:(CGSize)size {
    CGSize newSize = !CGSizeEqualToSize(size, CGSizeZero) ? size : CGSizeMake(90, 160);
    self.windowSize = newSize;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    self.originPoint = CGPointMake(screenSize.width - self.windowSize.width - 16, screenSize.height - self.windowSize.height - 16);
    
    self.frame = CGRectMake(self.originPoint.x, self.originPoint.y, self.windowSize.width, self.windowSize.height);
    self.backButton.frame = self.bounds;
    self.containerView.frame = self.bounds;
}

#pragma mark - Getter & Setter

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

- (void)setHoldingViewController:(UIViewController *)holdingViewController {
    _holdingViewController = holdingViewController;
    self.holdingNavigation = holdingViewController.navigationController;
}

#pragma mark - Action

- (void)closeAction {
    [self closeAndBack:NO];
}

- (void)backAction {
    [self closeAndBack:YES];
}

- (void)closeAndBack:(BOOL)back {
    self.hidden = YES;
    [self resetPosition];
    
    if (back) {
        if (self.holdingNavigation) {
            NSArray *vcArray = self.holdingNavigation.viewControllers;
            NSInteger index = -1;
            for (NSInteger i = 0; i < vcArray.count; i++) {
                UIViewController *child = vcArray[i];
                if ([child isEqual:self.holdingViewController]) {
                    index = i;
                }
            }
            if (index == -1) {
                // 不在导航栈内
                [self.holdingNavigation pushViewController:self.holdingViewController animated:YES];
            } else if (index == vcArray.count - 1) {
                // 在栈顶，则直接恢复
            } else {
                [self.holdingNavigation popToViewController:self.holdingViewController animated:YES];
            }
        } else {
            UIViewController *currentViewController = [PLVFdUtil getCurrentViewController];
            if (currentViewController != self.holdingViewController) {
                if (self.restoreWithPresent) {
                    [currentViewController presentViewController:self.holdingViewController animated:YES completion:nil];
                }else {
                    [currentViewController dismissViewControllerAnimated:YES completion:nil];
                }
            }
        }
    }
    
    [self cleanRestoreSource];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(floatingWindow_closeWindowAndBack:)]) {
        [self.delegate floatingWindow_closeWindowAndBack:back];
    }
}

#pragma mark Notification

- (void)didChangeOrientation:(NSNotification *)notification {
    // 延迟1秒布局优化旋转后画面黑屏的问题
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.containerView.frame = self.bounds;
        self.contentView.frame = self.containerView.bounds;
        [self layoutIfNeeded];
    });
}

#pragma mark - Public

- (void)showContentView:(UIView *)contentView {
    [self showContentView:contentView size:CGSizeZero];
}

- (void)showContentView:(UIView *)contentView size:(CGSize)size {
    self.hidden = NO;
    
    for (UIView * subview in self.containerView.subviews) {
        [subview removeFromSuperview];
    }
    
    if (!contentView) {
        return;
    }
    
    if (size.width == 0 || size.height == 0) {
        [self resetPosition];
    } else {
        CGFloat scale = size.width / size.height;
        CGSize newSize = scale > 1 ? CGSizeMake(90 * scale, 90) : CGSizeMake(160 * scale, 160);
        [self resetPositionWithSize:newSize];
    }
    
    self.contentView = contentView;
    [self.containerView addSubview:self.contentView];
    self.contentView.frame = self.containerView.bounds;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.contentView.userInteractionEnabled = YES;
}

- (void)close {
    self.hidden = YES;
    [self.contentView removeFromSuperview];
    self.contentView = nil;
    [self resetPosition];
    [self cleanRestoreSource];
}

- (void)closeAndBack {
    [self closeAndBack:YES];
}

#pragma mark - Pravite

- (void)cleanRestoreSource {
    self.holdingViewController = nil;
    self.holdingNavigation = nil;
    self.restoreWithPresent = NO;
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
