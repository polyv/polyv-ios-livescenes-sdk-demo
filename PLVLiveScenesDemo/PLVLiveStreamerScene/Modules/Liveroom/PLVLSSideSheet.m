//
//  PLVLSSideSheet.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/2/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSSideSheet.h"

static CGFloat kSideSheetAnimationDuration = 0.5;

@interface PLVLSSideSheet ()

@property (nonatomic, strong) UIVisualEffectView *effectView; // 高斯模糊效果图
@property (nonatomic, strong) UIView *gestureView; // 弹层左侧手势区域
@property (nonatomic, strong) UIView *contentView; // 弹层右侧内容区域
@property (nonatomic, assign) CGFloat sheetWidth; // 弹层显示时的宽度

@end

@implementation PLVLSSideSheet

#pragma mark - Life Cycle

- (instancetype)initWithSheetWidth:(CGFloat)sheetWidth {
    self = [super init];
    if (self) {
        self.sheetWidth = MAX(0, sheetWidth);
        
        [self addSubview:self.gestureView];
        [self addSubview:self.contentView];
        [self.contentView addSubview:self.effectView];
    }
    return self;
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

#pragma mark - Show & Hide

- (void)showInView:(UIView *)parentView {
    if (!parentView) {
        return;
    }
    
    [parentView addSubview:self];
    [parentView insertSubview:self atIndex:parentView.subviews.count - 1];
    
    [self reset];
    [UIView animateWithDuration:kSideSheetAnimationDuration animations:^{
        self.contentView.frame = CGRectMake(self.bounds.size.width - self.sheetWidth, 0, self.sheetWidth, self.bounds.size.height);
        self.effectView.frame = self.contentView.bounds;
    } completion:nil];
}

- (void)dismiss {
    if (!self.superview) {
        return;
    }
    
    [UIView animateWithDuration:kSideSheetAnimationDuration animations:^{
        self.contentView.frame = CGRectMake(self.bounds.size.width, 0, self.sheetWidth, self.bounds.size.height);
        self.effectView.frame = self.contentView.bounds;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)reset {
    self.frame = self.superview.bounds;
    self.gestureView.frame = self.bounds;
    self.contentView.frame = CGRectMake(self.bounds.size.width, 0, self.sheetWidth, self.bounds.size.height);
    self.effectView.frame = self.contentView.bounds;
}

@end
