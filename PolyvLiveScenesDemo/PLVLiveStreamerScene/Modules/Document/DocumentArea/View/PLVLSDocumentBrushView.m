//
//  PLVLSDocumentBrushView.m
//  PLVLiveScenesDemo
//
//  Created by Hank on 2021/3/1.
//  Copyright © 2021 PLV. All rights reserved.
//  画笔工具条

#import "PLVLSDocumentBrushView.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVLSDocumentBrushColorView.h"


#import "PLVLSUtils.h"

@interface PLVLSDocumentBrushView ()

@property (nonatomic, strong) UIView *viewBg;             // 背景颜色
@property (nonatomic, strong) UIButton *btnClearAll;      // 清除画面
@property (nonatomic, strong) UIButton *btnClear;         // 橡皮擦
@property (nonatomic, strong) UIButton *btnText;          // 文字
@property (nonatomic, strong) UIButton *btnArrow;         // 箭头
@property (nonatomic, strong) UIButton *btnFreePen;       // 自由线条

@property (nonatomic, strong) UIView *viewLine;            // 分割线
@property (nonatomic, strong) UIView *viewColor;           // 颜色视图

@property (nonatomic, strong) NSArray *colors;            // 颜色

@end

@implementation PLVLSDocumentBrushView

#pragma mark - [ Life Period ]

- (instancetype)init {
    if (self = [super init]) {
        _colors = @[@"#FF6363", @"#4399FF", @"#5AE59C", @"#FFE45B", @"#4A5060", @"#F0F1F5"];
        [self setupUI];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize selfSize = self.bounds.size;
    
    CGFloat toolWidth = 36;
    CGFloat colorWidth = 28;
    CGFloat toolItemY = 0;
    CGFloat margin = 8;
    
    if (self.bounds.size.width < 504) {  // iphone小屏适配
        NSInteger subViewCount = self.subviews.count + self.viewColor.subviews.count + 1;
        CGFloat subViewWidth = toolWidth * 5 + 1 + colorWidth * self.colors.count + 36 + 4;
        if (self.bounds.size.width < subViewWidth) { // iphone 5s适配
            toolWidth = 32;
            colorWidth = 26;
            toolItemY = (selfSize.height - toolWidth) / 2.0f;
            subViewWidth = toolWidth * 5 + 1 + colorWidth * self.colors.count + 36 + 4;
        }
        margin = (self.bounds.size.width - subViewWidth) / subViewCount;
    }
    
    self.btnClearAll.frame = CGRectMake(selfSize.width - toolWidth - 36 - 2 * margin, toolItemY, toolWidth, toolWidth);
    self.btnClear.frame = CGRectMake(UIViewGetLeft(self.btnClearAll) - toolWidth - margin, toolItemY, toolWidth, toolWidth);
    self.btnText.frame = CGRectMake(UIViewGetLeft(self.btnClear) - toolWidth - margin, toolItemY, toolWidth, toolWidth);
    self.btnArrow.frame = CGRectMake(UIViewGetLeft(self.btnText) - toolWidth - margin, toolItemY, toolWidth, toolWidth);
    self.btnFreePen.frame = CGRectMake(UIViewGetLeft(self.btnArrow) - toolWidth - margin, toolItemY, toolWidth, toolWidth);
    
    self.viewLine.frame = CGRectMake(UIViewGetLeft(self.btnFreePen) - 1 - margin, 8, 1, selfSize.height - 16);
    
    // 颜色
    CGFloat colorItemY = (selfSize.height - colorWidth) / 2.0f;
    self.viewColor.frame = CGRectMake(4, colorItemY, UIViewGetLeft(self.viewLine) - margin - 4, colorWidth);
    
    UIButton *btnColorItem;
    for (NSInteger i = 0; i < self.viewColor.subviews.count; i++) {
        btnColorItem = self.viewColor.subviews[i];
        btnColorItem.frame = CGRectMake(margin + i * (colorWidth + margin), 0, colorWidth, colorWidth);
    }
    
    // 背景
    CGRect bgFrame = self.bounds;
    if (self.viewColor.hidden) {
        CGFloat colorRight = UIViewGetRight(self.viewColor);
        bgFrame.origin.x = colorRight;
        bgFrame.size.width = self.bounds.size.width - colorRight;
    }
    self.viewBg.frame = bgFrame;
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    self.btnClearAll = [self createToolButton:@"plvls_ppt_btn_clear_all_normal"
                              imgNameDisabled:nil];
    [self.btnClearAll setImage:[self getImageWithName:@"plvls_ppt_btn_clear_all_highlighted"]
                 forState:UIControlStateHighlighted];
    
    self.btnClear = [self createToolButton:@"plvls_ppt_btn_clear_normal"
                           imgNameDisabled:@"plvls_ppt_btn_clear_selected"];
    self.btnText = [self createToolButton:@"plvls_ppt_btn_text_normal"
                          imgNameDisabled:@"plvls_ppt_btn_text_selected"];
    self.btnArrow = [self createToolButton:@"plvls_ppt_btn_arrow_normal"
                           imgNameDisabled:@"plvls_ppt_btn_arrow_selected"];
    self.btnFreePen = [self createToolButton:@"plvls_ppt_btn_pen_normal"
                         imgNameDisabled:@"plvls_ppt_btn_pen_selected"];
    self.btnFreePen.enabled = NO;
    
    [self addSubview:self.viewBg];
    [self addSubview:self.btnClearAll];
    [self addSubview:self.btnClear];
    [self addSubview:self.btnText];
    [self addSubview:self.btnArrow];
    [self addSubview:self.btnFreePen];
    
    [self addSubview:self.viewLine];
    [self addSubview:self.viewColor];
    
    [self addColorButton];
}

- (UIButton *)createToolButton:(NSString *)imgNameNormal imgNameDisabled:(NSString *)imgNameDisabled {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[self getImageWithName:imgNameNormal] forState:UIControlStateNormal];
    [button setImage:[self getImageWithName:imgNameDisabled] forState:UIControlStateHighlighted];
    
    if ([PLVFdUtil checkStringUseable:imgNameDisabled]) {
        [button setImage:[self getImageWithName:imgNameDisabled] forState:UIControlStateDisabled];
    }
    
    [button addTarget:self action:@selector(buttonToolAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

// 更加颜色数组，添加色板按钮
- (void)addColorButton {
    PLVLSDocumentBrushColorView *button;
    NSString *colorName;
    for (NSInteger i = 0; i < self.colors.count; i++) {
        colorName = self.colors[i];
        
        button = [[PLVLSDocumentBrushColorView alloc] init];
        button.tag = i + 1;
        button.color = PLV_UIColorFromRGB(colorName);
        [button addTarget:self action:@selector(buttonColorAction:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.viewColor addSubview:button];
        if (i == 0) {
            button.enabled = NO;
        }
    }
}

// 改变工具按钮状态
- (void)changeStatusWithClickButton:(UIButton *)button {
    if (button == self.btnClearAll) {
        return;
    }
    
    self.btnClear.enabled = YES;
    self.btnText.enabled = YES;
    self.btnArrow.enabled = YES;
    self.btnFreePen.enabled = YES;
    
    UIImage *img = [button imageForState:UIControlStateDisabled];
    if (button.enabled) {
        img = [button imageForState:UIControlStateNormal];
    }
    [button setImage:img forState:UIControlStateHighlighted];
    button.enabled = NO;
    [self openColorView:button != self.btnClear];
}

// 打开、关闭色板
- (void)openColorView:(BOOL)isOpen {
    self.viewLine.hidden = !isOpen;
    self.viewColor.hidden = !isOpen;
    
    [self setNeedsLayout];
}

// 加载图片
- (UIImage *)getImageWithName:(NSString *)name {
    if (! [PLVFdUtil checkStringUseable:name]) {
        return nil;
    }
    return [PLVLSUtils imageForDocumentResource:name];
}

#pragma mark - [ Getter ]

- (UIView *)viewBg {
    if (! _viewBg) {
        _viewBg = [[UIView alloc] init];
        _viewBg.backgroundColor = PLV_UIColorFromRGBA(@"#1B202D", 0.2f);
        _viewBg.layer.cornerRadius = 18;
        _viewBg.clipsToBounds = YES;
    }
    return _viewBg;
}

- (UIView *)viewLine {
    if (! _viewLine) {
        _viewLine = [[UIView alloc] init];
//        _viewLine.backgroundColor = PLV_UIColorFromRGBA(@"#F0F1F5", 0.1f);
        _viewLine.backgroundColor = PLV_UIColorFromRGBA(@"#313540", 0.1f);
    }
    
    return _viewLine;
}

- (UIView *)viewColor {
    if (! _viewColor) {
        _viewColor = [[UIView alloc] init];
    }
    
    return _viewColor;
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)buttonToolAction:(UIButton *)button {
    PLVLSDocumentBrushViewType type = 0;
    if (button == self.btnClearAll) {
        type = PLVLSDocumentBrushViewTypeClearAll;
    } else if (button == self.btnClear) {
        type = PLVLSDocumentBrushViewTypeClear;
    } else if (button == self.btnText) {
        type = PLVLSDocumentBrushViewTypeText;
    } else if (button == self.btnArrow) {
        type = PLVLSDocumentBrushViewTypeArrow;
    } else if (button == self.btnFreePen) {
        type = PLVLSDocumentBrushViewTypeFreePen;
    }
    
    [self changeStatusWithClickButton:button];
    
    if (self.delegate
        && [self.delegate respondsToSelector:@selector(brushView:changeType:)]) {
        [self.delegate brushView:self changeType:type];
    }
}

- (void)buttonColorAction:(UIButton *)button {
    for (UIButton *btnItem in self.viewColor.subviews) {
        btnItem.enabled = YES;
    }
    
    button.enabled = NO;
    
    NSInteger index = button.tag - 1;
    NSString *colorName = self.colors[index];
    if (self.delegate && [self.delegate respondsToSelector:@selector(brushView:changeColor:)]) {
        [self.delegate brushView:self changeColor:colorName];
    }
}

@end
