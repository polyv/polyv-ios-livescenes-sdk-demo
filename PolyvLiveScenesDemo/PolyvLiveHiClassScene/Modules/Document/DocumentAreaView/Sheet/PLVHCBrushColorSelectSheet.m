//
//  PLVHCBrushColorSelectSheet.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/7/20.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCBrushColorSelectSheet.h"

// 工具
#import "PLVHCUtils.h"

// UI
#import "PLVHCBrushColorButton.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>


@interface PLVHCBrushColorSelectSheet()

@property (nonatomic, strong) NSArray *colorsArray; // 颜色值数组
@property (nonatomic, strong) NSArray <PLVHCBrushColorButton *> *buttonArray; // 颜色按钮数组

@end

@implementation PLVHCBrushColorSelectSheet

#pragma mark - [ Life Cycle ]

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
    CGFloat colorWidth = 36;
    CGFloat itemY = 4;
    CGFloat margin = itemY;
    CGFloat padding = 8;
    CGFloat subViewsCount = self.subviews.count;
    CGFloat subViwesWidth = (margin + colorWidth * subViewsCount + (padding * (subViewsCount - 1)));
    
    // 小屏适配
    if (selfSize.width < subViwesWidth) {
        padding = 4;
        colorWidth = (selfSize.width - padding * 5 ) / 6;
        itemY = (selfSize.height - colorWidth) / 2;
    }
    
    UIButton *btnColorItem;
    CGFloat btnX = 4;
    for (NSInteger i = 0; i < self.subviews.count; i++) {
        if (i != 0) {
            btnX += colorWidth + padding;
        }
        btnColorItem = self.subviews[i];
        btnColorItem.frame = CGRectMake(btnX , itemY, colorWidth, colorWidth);
    }
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

- (void)updateSelectColor:(NSString *)color {
    if (![PLVFdUtil checkStringUseable:color]) {
        return;
    }
    
    UIColor *changeColor = [PLVColorUtil colorFromHexString:color];
    [self.buttonArray enumerateObjectsUsingBlock:^(PLVHCBrushColorButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self isTheSameColor:changeColor otherColor:button.color]) {
            [self colorButtonAction:button localTouch:NO];
            *stop = YES;
        }
    }];
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (NSArray *)colorsArray {
    if (!_colorsArray) {
        _colorsArray = [NSArray arrayWithObjects:@"#FF5A5B", @"#5B9EFF", @"#5BFF75", @"#FFF85B", @"#3D3D3D", @"#FFFFFF", nil];
    }
    return _colorsArray;
}

- (NSArray<PLVHCBrushColorButton *> *)buttonArray {
    if (!_buttonArray) {
        _buttonArray = [NSArray array];
    }
    return _buttonArray;
}

#pragma mark 设置UI

- (void)setupUI {
    [self addColorButton];
}

// 添加颜色按钮
- (void)addColorButton {
    PLVHCBrushColorButton *button;
    NSString *colorName;
    NSMutableArray *btnArryM = [NSMutableArray array];
    for (NSInteger i = 0; i < self.colorsArray.count; i++) {
        colorName = self.colorsArray[i];
        
        button = [[PLVHCBrushColorButton alloc] init];
        button.tag = i + 1;
        button.color = PLV_UIColorFromRGB(colorName);
        [button addTarget:self action:@selector(colorButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:button];
        if (i == 0) {
            button.enabled = NO;
        }
        
        [btnArryM addObject:button];
    }
    self.buttonArray = [btnArryM copy];
}

#pragma mark Util

- (BOOL)isTheSameColor:(UIColor *)color otherColor:(UIColor *)otherColor {
    return CGColorEqualToColor(color.CGColor, otherColor.CGColor);
}

- (void)colorButtonAction:(UIButton *)button localTouch:(BOOL)localTouch {
    for (UIButton *btnItem in self.subviews) {
        btnItem.enabled = YES;
    }
    
    button.enabled = NO;
    
    NSInteger index = button.tag - 1;
    NSString *colorName = self.colorsArray[index];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(brushColorSelectSheet:didSelectColor:localTouch:)]) {
        [self.delegate brushColorSelectSheet:self didSelectColor:colorName localTouch:localTouch];
    }
    
    [self dismiss];
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)colorButtonAction:(UIButton *)button {
    [self colorButtonAction:button localTouch:YES];
}

@end
