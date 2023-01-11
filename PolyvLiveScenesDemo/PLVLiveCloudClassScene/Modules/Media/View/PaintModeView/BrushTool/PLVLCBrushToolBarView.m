//
//  PLVLCBrushToolBarView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/20.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLCBrushToolBarView.h"

// UI
#import "PLVLCBrushToolButton.h"
#import "PLVLCBrushColorButton.h"

// 工具
#import "PLVLCUtils.h"

// 模块
#import "PLVRoomDataManager.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCBrushToolBarView()

#pragma mark UI
/// view hierarchy
///
/// (PLVLCBrushToolBarView) self
///    ├─ (UIButton) revokeButton
///    ├─ (PLVLCBrushToolButton) toolButton
///    └─(PLVLCBrushToolButton) colorButton(动态显示)
///

@property (nonatomic, strong) UIButton *revokeButton; // 撤回按钮，常驻
@property (nonatomic, strong) PLVLCBrushToolButton *toolButton; // 工具按钮，常驻
@property (nonatomic, strong) PLVLCBrushColorButton *colorButton; // 颜色按钮，动态显示

#pragma mark 数据
 
@property (nonatomic, assign) PLVLCBrushToolType currentBrushToolType; // 当前画笔工具类型(默认为 FreeLine)
@property (nonatomic, copy) NSString *currentColor; // 当前颜色值
@property (nonatomic, assign) BOOL showColorButton; // 是否显示颜色按钮

@end

@implementation PLVLCBrushToolBarView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.revokeButton];
        [self addSubview:self.toolButton];
        [self addSubview:self.colorButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat superViewHeight = self.superview.bounds.size.height;
    CGFloat buttonWidth = 36;
    CGFloat middleWidth = 0;
    CGFloat padding = 14;
    CGFloat colorButtonWidth = self.showColorButton ? buttonWidth : 0;
    CGFloat width;
    
    // 计算画笔工具宽度
    middleWidth = colorButtonWidth  + (self.showColorButton * padding);
    width = buttonWidth * 2 + middleWidth + padding;
    
    CGSize selfSize = CGSizeMake(width, 36);
    CGFloat brushToolX = self.screenSafeWidth - selfSize.width - 30;
    CGFloat brushToolY = superViewHeight - selfSize.height - 35;
    self.frame = CGRectMake(brushToolX, brushToolY, selfSize.width, selfSize.height);
    
    self.revokeButton.frame = CGRectMake(0, 0, buttonWidth, buttonWidth);
    middleWidth = CGRectGetMaxX(self.revokeButton.frame);
    
    self.colorButton.frame = CGRectMake(CGRectGetMaxX(self.revokeButton.frame) + padding * self.showColorButton, 0, colorButtonWidth, colorButtonWidth);
    middleWidth = CGRectGetMaxX(self.colorButton.frame);
    
    self.toolButton.frame = CGRectMake(middleWidth + padding, 0, buttonWidth, buttonWidth);
}

#pragma mark - [ Public Method ]

- (void)showInView:(UIView *)view {
    if (view) {
        [view addSubview:self];
    }
}

- (void)dismiss {
    [self removeFromSuperview];
}

- (void)updateSelectToolType:(PLVLCBrushToolType)toolType selectImage:(nonnull UIImage *)selectImage{
    if (toolType == PLVLCBrushToolTypeClear) {
        return;
    }
    self.currentBrushToolType = toolType;
    [self.toolButton setImage:selectImage];
}

- (void)updateSelectColor:(NSString *)color {
    if ([PLVFdUtil checkStringUseable:color]) {
        self.currentColor = color;
        self.colorButton.color = [PLVColorUtil colorFromHexString:color];
    }
}

- (void)setScreenSafeWidth:(CGFloat)screenSafeWidth {
    _screenSafeWidth = screenSafeWidth;
    plv_dispatch_main_async_safe(^{
        [self setNeedsLayout];
        [self layoutIfNeeded];
    })
}

#pragma mark - [ Private Methods ]
#pragma mark Getter

- (UIButton *)revokeButton {
    if (!_revokeButton) {
        _revokeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_revokeButton setImage:[PLVLCUtils imageForMediaResource:@"plvlc_media_brush_btn_revoke"] forState:UIControlStateNormal];
        [_revokeButton addTarget:self action:@selector(revokeButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _revokeButton;
}

- (PLVLCBrushToolButton *)toolButton {
    if (!_toolButton) {
        _toolButton = [[PLVLCBrushToolButton alloc] init];
        [_toolButton setImage:[PLVLCUtils imageForMediaResource:@"plvlc_media_brush_btn_freeline_normal"]];
        __weak typeof(self) weakSelf = self;
        _toolButton.didTapButton = ^{
            [weakSelf toolButtonAction];
        };
    }
    return _toolButton;
}

- (PLVLCBrushColorButton *)colorButton {
    if (!_colorButton) {
        _colorButton = [[PLVLCBrushColorButton alloc] init];
        _colorButton.color = [PLVColorUtil colorFromHexString:@"#FF6363"];
        _colorButton.bgColor = [PLVColorUtil colorFromHexString:@"#242940"];
        [_colorButton addTarget:self action:@selector(colorButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _colorButton;
}

#pragma mark Setter

- (void)setCurrentBrushToolType:(PLVLCBrushToolType)currentBrushToolType {
    _currentBrushToolType = currentBrushToolType;
    BOOL showColorButton = NO;
    
    switch (currentBrushToolType) {
        case PLVLCBrushToolTypeFreeLine:
            showColorButton = YES;
            break;
        case PLVLCBrushToolTypeArrow:
            showColorButton = YES;
            break;
        case PLVLCBrushToolTypeText:
            showColorButton = YES;
            break;
        case PLVLCBrushToolTypeRect:
            showColorButton = YES;
            break;
        default:
            break;
    }
    
    self.showColorButton = showColorButton;
    plv_dispatch_main_async_safe(^{
        [self setNeedsLayout];
    })
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)revokeButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(brushToolBarViewDidTapRevokeButton:)]) {
        [self.delegate brushToolBarViewDidTapRevokeButton:self];
    }
}

- (void)toolButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(brushToolBarViewDidTapToolButton:)]) {
        [self.delegate brushToolBarViewDidTapToolButton:self];
    }
}

- (void)colorButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(brushToolBarViewDidTapColorButton:)]) {
        [self.delegate brushToolBarViewDidTapColorButton:self];
    }
}

@end
