//
//  PLVLCBrushToolSelectSheet.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/20.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLCBrushToolSelectSheet.h"

// 工具
#import "PLVLCUtils.h"

// 模块
#import "PLVRoomDataManager.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCBrushToolSelectSheet()

@property (nonatomic, strong) UIButton *freeLineButton; // 自由线条
@property (nonatomic, strong) UIButton *arrowButton; // 箭头
@property (nonatomic, strong) UIButton *textButton; // 文字
@property (nonatomic, strong) UIButton *rectButton; // 矩形框
@property (nonatomic, strong) UIButton *eraserButton; // 橡皮擦
@property (nonatomic, strong) UIButton *clearButton; // 清除画面

@end

@implementation PLVLCBrushToolSelectSheet

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#1B202D"];
        self.layer.cornerRadius = 22;
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize selfSize = self.bounds.size;
    CGFloat toolWidth = 36;
    CGFloat toolItemY = 4;
    CGFloat toolItemX = toolItemY;
    CGFloat margin = 8;
    CGFloat subViewsCount = 6;
    CGFloat subViwesWidth = (toolWidth * subViewsCount + (margin * (subViewsCount - 1)));
    
    // 小屏适配
    if (selfSize.width < subViwesWidth) {
        margin = 4;
        toolWidth = (selfSize.width - margin * (subViewsCount - 1) ) / subViewsCount;
        toolItemY = (selfSize.height - toolWidth) / 2;
    }
    
    self.freeLineButton.frame = CGRectMake(toolItemX, toolItemY, toolWidth, toolWidth);
    self.rectButton.frame = CGRectMake(CGRectGetMaxX(self.freeLineButton.frame) + margin, toolItemY, toolWidth, toolWidth);
    self.arrowButton.frame = CGRectMake(CGRectGetMaxX(self.rectButton.frame) + margin, toolItemY, toolWidth, toolWidth);
    self.textButton.frame = CGRectMake(CGRectGetMaxX(self.arrowButton.frame) + margin, toolItemY, toolWidth, toolWidth);
    self.eraserButton.frame = CGRectMake(CGRectGetMaxX(self.textButton.frame) + margin, toolItemY, toolWidth, toolWidth);
    self.clearButton.frame = CGRectMake(CGRectGetMaxX(self.eraserButton.frame) + margin, toolItemY, toolWidth, toolWidth);
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

- (void)updateBrushToolApplianceType:(PLVLCBrushToolType)applianceType {
    UIButton *button;
    switch (applianceType) {
        case PLVLCBrushToolTypeFreeLine:
            button = self.freeLineButton;
            break;
        case PLVLCBrushToolTypeArrow:
            button = self.arrowButton;
            break;
        case PLVLCBrushToolTypeEraser:
            button =  self.eraserButton;
            break;
        case PLVLCBrushToolTypeText:
            button = self.textButton;
            break;
        case PLVLCBrushToolTypeRect:
            button = self.rectButton;
            break;
        default:
            break;
    }
    [self buttonAction:button localTouch:NO];
}

- (void)updateLayout {
    plv_dispatch_main_async_safe(^{
        [self setNeedsLayout];
        [self layoutIfNeeded];
    })
}

#pragma mark - [ Private Method ]
#pragma mark Getter


#pragma mark setupUI

- (void)setupUI {
 
    self.freeLineButton = [self createToolButton:@"plvlc_media_brush_btn_freeline_normal"];
    self.freeLineButton.tag = PLVLCBrushToolTypeFreeLine;
    
    self.arrowButton = [self createToolButton:@"plvlc_media_brush_btn_arrow_normal"];
    self.arrowButton.tag = PLVLCBrushToolTypeArrow;
    
    self.textButton = [self createToolButton:@"plvlc_media_brush_btn_text_normal"];
    self.textButton.tag = PLVLCBrushToolTypeText;
    
    self.rectButton = [self createToolButton:@"plvlc_media_brush_btn_rect_normal"];
    self.rectButton.tag = PLVLCBrushToolTypeRect;
    
    self.eraserButton = [self createToolButton:@"plvlc_media_brush_btn_eraser_normal"];
    self.eraserButton.tag = PLVLCBrushToolTypeEraser;
    
    self.clearButton = [self createToolButton:@"plvlc_media_brush_btn_clear"];
    self.clearButton.tag = PLVLCBrushToolTypeClear;
    
    [self addSubview:self.freeLineButton];
    [self addSubview:self.rectButton];
    [self addSubview:self.arrowButton];
    [self addSubview:self.textButton];
    [self addSubview:self.eraserButton];
    [self addSubview:self.clearButton];
}

#pragma mark 创建按钮

- (UIButton *)createToolButton:(NSString *)imgNameNormal {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *selectedBackgroundImage = [PLVColorUtil createImageWithColor:[PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0.2]];
    button.layer.cornerRadius = 18.0f;
    button.layer.masksToBounds = YES;
    [button setImage:[self getImageWithName:imgNameNormal] forState:UIControlStateNormal];
    [button setBackgroundImage:selectedBackgroundImage forState:UIControlStateSelected];
    [button setImage:selectedBackgroundImage forState:UIControlStateDisabled];
    [button addTarget:self action:@selector(toolButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

// 加载图片
- (UIImage *)getImageWithName:(NSString *)name {
    if (![PLVFdUtil checkStringUseable:name]) {
        return nil;
    }
    return [PLVLCUtils imageForMediaResource:name];
}


- (void)changeStatusWithClickButton:(UIButton *)button {
    if (button.tag == PLVLCBrushToolTypeClear) {
        return;
    }
    
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton *)view;
            btn.selected = NO;
        }
    }
    
    UIImage *img = [button imageForState:UIControlStateSelected];
    if (button.selected) {
        img = [button imageForState:UIControlStateSelected];
    }
    [button setImage:img forState:UIControlStateSelected];
    button.selected = YES;
}

- (void)buttonAction:(UIButton *)button localTouch:(BOOL)localTouch {
    PLVLCBrushToolType type = (PLVLCBrushToolType)button.tag;
    if (type == PLVLCBrushToolTypeUnknown) {
        return;
    }
    
    [self changeStatusWithClickButton:button];
    
    UIImage *image = [button imageForState:UIControlStateNormal];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(brushToolSelectSheet:didSelectToolType:selectImage:localTouch:)]) {
        [self.delegate brushToolSelectSheet:self didSelectToolType:type selectImage:image localTouch:localTouch];
    }
    [self dismiss];
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)toolButtonAction:(UIButton *)button {
    [self buttonAction:button localTouch:YES];
}

@end
