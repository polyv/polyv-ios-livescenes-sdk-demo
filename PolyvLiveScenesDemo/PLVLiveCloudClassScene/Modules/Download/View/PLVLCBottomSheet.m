//
//  PLVLCBottomSheet.m
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/5/25.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCBottomSheet.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat kBottomSheetAnimationDuration = 0.3;

@interface PLVLCBottomSheet ()

@property (nonatomic, strong) UIView *effectView; // 高斯模糊效果图
@property (nonatomic, strong) UIView *gestureView; // 手势区域
@property (nonatomic, strong) UIView *contentView; // 底部内容区域
@property (nonatomic, assign) CGFloat sheetHight; // 弹层显示时的高度

@end

@implementation PLVLCBottomSheet

#pragma mark - Life Cycle

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight {
    self = [super init];
    if (self) {
        self.sheetHight = MAX(0, sheetHeight);
        
        self.bottomShow = NO;
        [self addSubview:self.effectView];
        [self addSubview:self.gestureView];
        [self addSubview:self.contentView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.bottomShow) {
        self.frame = self.superview.bounds;
        self.gestureView.frame = self.bounds;
        self.effectView.frame = self.bounds;
        
        self.contentView.frame = CGRectMake(0, self.bounds.size.height - self.sheetHight, self.bounds.size.width, self.sheetHight);
    }
}

#pragma mark - Getter

- (UIView *)effectView {
    if (!_effectView) {
        _effectView = [[UIView alloc] init];
        _effectView.backgroundColor = [PLVColorUtil colorFromHexString:@"#000000" alpha:0.65];
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
        _contentView.backgroundColor = [UIColor whiteColor];
    }
    return _contentView;
}

#pragma mark - Show & Hide

- (void)showInView:(UIView *)parentView {
    if (!parentView) {
        return;
    }
    
    [parentView addSubview:self];
    [parentView insertSubview:self atIndex:parentView.subviews.count - 1];
    
    [self reset];
    [UIView animateWithDuration:kBottomSheetAnimationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.contentView.frame = CGRectMake(0, self.bounds.size.height - self.sheetHight, self.bounds.size.width, self.sheetHight);
    } completion:^(BOOL finished) {
        self.bottomShow = YES;
    }];
}

- (void)dismiss {
    if (!self.superview) {
        return;
    }
    
    [UIView animateWithDuration:kBottomSheetAnimationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.contentView.frame = CGRectMake(0, self.bounds.size.height, self.bounds.size.width, self.sheetHight);
    } completion:^(BOOL finished) {
        self.bottomShow = NO;
        [self removeFromSuperview];
    }];
}

- (void)reset {
    self.frame = self.superview.bounds;
    self.gestureView.frame = self.bounds;
    self.contentView.frame = CGRectMake(0, self.bounds.size.height, self.bounds.size.width, self.sheetHight);
    self.effectView.frame = self.bounds;
}

- (void)refreshWithSheetHeight:(CGFloat)sheetHeight {
    self.sheetHight = MAX(0, sheetHeight);
    self.frame = self.superview.bounds;
    self.gestureView.frame = self.bounds;
    self.contentView.frame = CGRectMake(0, self.bounds.size.height - self.sheetHight, self.bounds.size.width, self.sheetHight);
    self.effectView.frame = self.bounds;
}

@end
