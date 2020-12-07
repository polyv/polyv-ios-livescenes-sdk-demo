//
//  PLVLCMediaFloatView.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/9/15.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCMediaFloatView.h"

#import "PLVLCUtils.h"
#import <PolyvFoundationSDK/PolyvFoundationSDK.h>

@interface PLVLCMediaFloatView ()

#pragma mark 状态
@property (nonatomic, assign) BOOL floatViewShow;
@property (nonatomic, assign) BOOL userOperatForLastFloatViewShow;

#pragma mark 数据
@property (nonatomic, assign) CGPoint lastPoint;
@property (nonatomic, assign) CGRect rangeRect;

#pragma mark UI
/// view hierarchy
///
/// (PLVLCMediaFloatView) self
/// ├── (UIView) contentBackgroudView (lowest)
/// ├── (UILabel) nicknameLabel
/// └── (UIButton) closeButton (top)
@property (nonatomic, strong) UIView * contentBackgroudView; // 内容背景视图 (负责承载 不同类型的内容画面[播放器画面、PPT画面]；直接决定了’内容画面‘在 PLVLCMediaFloatView 中的布局、图层)
@property (nonatomic, strong) CAGradientLayer * shadowLayer; // 阴影背景 (负责展示 阴影背景)
@property (nonatomic, strong) UILabel * nicknameLabel;       // 昵称文本框 (负责展示 用户昵称)
@property (nonatomic, strong) UIButton * closeButton;        // 关闭按钮 (负责关闭 悬浮小窗)

@end

@implementation PLVLCMediaFloatView

#pragma mark - [ Life Period ]
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews{
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;

    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    
    self.contentBackgroudView.frame = self.bounds;
    
    CGFloat shadowLayerHeight = 24.0;
    self.shadowLayer.frame = CGRectMake(0, viewHeight - shadowLayerHeight, viewWidth, shadowLayerHeight);
        
    CGFloat nicknameLabelHeight = 17.0;
    CGFloat nicknameLabelLeftPadding = 12;
    self.nicknameLabel.frame = CGRectMake(nicknameLabelLeftPadding,
                                          viewHeight - 2 - nicknameLabelHeight,
                                          viewWidth - nicknameLabelLeftPadding,
                                          nicknameLabelHeight);
    
    CGFloat closeButtonHeight = 12.0;
    self.closeButton.frame = CGRectMake(viewWidth - closeButtonHeight - 6, 6, closeButtonHeight, closeButtonHeight);

    if (fullScreen) {
        self.closeButton.hidden = YES;
    }else{
        self.closeButton.hidden = NO;
    }
}


#pragma mark - [ Public Methods ]
- (void)displayExternalView:(UIView *)externalView{
    if (externalView && [externalView isKindOfClass:UIView.class]) {
        [self removeSubviewOfView:self.contentBackgroudView];
        [self.contentBackgroudView addSubview:externalView];
        externalView.frame = self.contentBackgroudView.bounds;
        externalView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }else{
        NSLog(@"PLVLCMediaFloatView - displayExternalView failed, externalView:%@",externalView);
    }
}

- (void)setNicknameLabalWithText:(NSString *)nicknameText{
    if ([PLVFdUtil checkStringUseable:nicknameText]) {
        self.nicknameLabel.text = nicknameText;
    }else{
        NSLog(@"PLVLCMediaFloatView - setNicknameLabalWithText failed, nicknameText:%@",nicknameText);
    }
}

- (void)showFloatView:(BOOL)show userOperat:(BOOL)userOperat{
    /// 以 用户希望的显示/隐藏 为准
    /// 若上次操作由用户发起，而这次操作由系统发起，则不处理
    if (_userOperatForLastFloatViewShow && !userOperat) { return; }

    _userOperatForLastFloatViewShow = userOperat;
    
    [self showFloatViewAnimation:show];
}

- (void)forceShowFloatView:(BOOL)show{
    _userOperatForLastFloatViewShow = NO;
    [self showFloatViewAnimation:show];
}

- (void)triggerViewExchangeEvent{
    [self tapGestureAction:nil];
}


#pragma mark - [ Private Methods ]
- (void)setupUI{
    //self.backgroundColor = [UIColor orangeColor];
    self.userInteractionEnabled = YES;
    self.canMove = YES;
    self.lastPoint = self.bounds.origin;

    // 添加 手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
    [self addGestureRecognizer:tap];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
    [self addGestureRecognizer:pan];
    
    // 添加 视图
    [self addSubview:self.contentBackgroudView];
    [self.layer addSublayer:self.shadowLayer];
    [self addSubview:self.nicknameLabel];
    [self addSubview:self.closeButton];
    
    // 添加 细节
    self.clipsToBounds = YES;
    self.layer.cornerRadius = 8.0;
    self.hidden = YES;
    self.alpha = 0;
}

- (void)showFloatViewAnimation:(BOOL)show{
    if (_floatViewShow != show) {
        _floatViewShow = show;
        if (_floatViewShow) { self.hidden = NO; }
        CGFloat alpha = _floatViewShow ? 1.0 : 0.0;
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            weakSelf.alpha = alpha;
        } completion:^(BOOL finished) {
            weakSelf.hidden = !weakSelf.floatViewShow;
        }];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCFloatView:floatViewSwitchToShow:)]) {
            [self.delegate plvLCFloatView:self floatViewSwitchToShow:_floatViewShow];
        }
    }
}

- (void)removeSubviewOfView:(UIView *)superview{
    for (UIView * subview in superview.subviews) { [subview removeFromSuperview]; }
}

#pragma mark Getter
- (UIView *)contentBackgroudView{
    if (!_contentBackgroudView) {
        _contentBackgroudView = [[UIView alloc]init];
    }
    return _contentBackgroudView;
}

- (CAGradientLayer *)shadowLayer{
    if (!_shadowLayer) {
        _shadowLayer = [CAGradientLayer layer];
        _shadowLayer.startPoint = CGPointMake(0.5, 0);
        _shadowLayer.endPoint = CGPointMake(0.5, 1);
        _shadowLayer.colors = @[(__bridge id)[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.0].CGColor, (__bridge id)[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.7].CGColor];
        _shadowLayer.locations = @[@(0), @(1.0f)];
    }
    return _shadowLayer;
}

- (UILabel *)nicknameLabel{
    if (!_nicknameLabel) {
        _nicknameLabel = [[UILabel alloc]init];
        _nicknameLabel.text = @"";
        _nicknameLabel.textColor = [UIColor whiteColor];
        _nicknameLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    }
    return _nicknameLabel;
}

- (UIButton *)closeButton{
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:[self getImageWithName:@"plvlc_media_floatview_close"] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UIImage *)getImageWithName:(NSString *)imageName{
    return [PLVLCUtils imageForMediaResource:imageName];
}


#pragma mark - [ Event ]
#pragma mark Action
- (void)closeButtonAction:(UIButton *)button{
    [self showFloatView:NO userOperat:YES];
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCFloatViewCloseButtonClicked:)]) {
        [self.delegate plvLCFloatViewCloseButtonClicked:self];
    }
}

- (void)tapGestureAction:(UITapGestureRecognizer *)gestureRecognizer {
    UIView * externalView = self.contentBackgroudView.subviews.firstObject;
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCFloatViewDidTap:externalView:)]) {
        UIView * willShowExternalView = [self.delegate plvLCFloatViewDidTap:self externalView:externalView];
        [self displayExternalView:willShowExternalView];
    }
}

- (void)panGestureAction:(UIPanGestureRecognizer *)gestureRecognizer {
    if (!self.fullscreen && !self.canMove) {
        return;
    }
    CGPoint p = [gestureRecognizer locationInView:self.superview];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (@available(iOS 11.0, *)) {
            CGRect safeRect = self.superview.safeAreaLayoutGuide.layoutFrame;
            if (self.fullscreen && safeRect.origin.y == 20.0) {
                safeRect.size.height += safeRect.origin.y;
                safeRect.origin.y = 0.0;
            }
            self.rangeRect = safeRect;
        } else {
            self.rangeRect = self.superview.bounds;
        }
    } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGRect rect = self.frame;
        rect.origin.x += (p.x - self.lastPoint.x);
        rect.origin.y += (p.y - self.lastPoint.y);
        if (rect.origin.x < self.rangeRect.origin.x) {
            rect.origin.x = self.rangeRect.origin.x;
        } else if (rect.origin.x > self.rangeRect.origin.x + self.rangeRect.size.width - rect.size.width) {
            rect.origin.x = self.rangeRect.origin.x + self.rangeRect.size.width - rect.size.width;
        }
        if (rect.origin.y < self.rangeRect.origin.y) {
            rect.origin.y = self.rangeRect.origin.y;
        } else if (rect.origin.y > self.rangeRect.origin.y + self.rangeRect.size.height - rect.size.height) {
            rect.origin.y = self.rangeRect.origin.y + self.rangeRect.size.height - rect.size.height;
        }
        self.frame = rect;
    }
    self.lastPoint = p;
}

@end
