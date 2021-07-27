//
//  PLVASBottomSheet.m
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/5/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSABottomSheet.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat kBottomSheetAnimationDuration = 0.25;

@interface PLVSABottomSheet ()

@property (nonatomic, strong) UIView *gestureView; // 手势区域
@property (nonatomic, strong) UIView *contentView; // 底部内容区域
@property (nonatomic, strong) UIVisualEffectView *effectView; // 高斯模糊效果图

@end

@implementation PLVSABottomSheet

#pragma mark - Life Cycle

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight {
    self = [super init];
    if (self) {
        self.sheetHight = MAX(0, sheetHeight);
        
        [self addSubview:self.gestureView];
        [self addSubview:self.contentView];
        [self.contentView addSubview:self.effectView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.contentView.bounds;
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.contentView.bounds
                                           byRoundingCorners:UIRectCornerTopRight | UIRectCornerTopLeft
                                                 cornerRadii:CGSizeMake(16, 16)].CGPath;
    self.contentView.layer.mask = maskLayer;
}

#pragma mark - Getter

- (UIView *)gestureView {
    if (!_gestureView) {
        _gestureView = [[UIView alloc] init];
        _gestureView.backgroundColor = PLV_UIColorFromRGBA(@"#000000",0.5);
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
        [_gestureView addGestureRecognizer:tapGesture];
    }
    return _gestureView;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = PLV_UIColorFromRGBA(@"#888888", 0.5);
    }
    return _contentView;
}

- (UIVisualEffectView *)effectView {
    if (!_effectView) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    }
    return _effectView;
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
        if (self.didCloseSheet) {
            self.didCloseSheet();
        }
    }];
}

- (void)reset {
    self.frame = self.superview.bounds;
    self.gestureView.frame = self.bounds;
    self.contentView.frame = CGRectMake(0, self.bounds.size.height, self.bounds.size.width, self.sheetHight);
    self.effectView.frame = self.contentView.bounds;
}

@end
