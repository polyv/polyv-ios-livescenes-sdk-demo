//
//  PLVStickerEffectLable.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/7/7.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVStickerEffectLable.h"

@implementation PLVStickerEffectLable

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupDefaultValues];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupDefaultValues];
    }
    return self;
}

- (void)setupDefaultValues {
    self.strokeWidth = 2.0;
    self.strokeColor = [UIColor whiteColor];
    self.textInsets = UIEdgeInsetsMake(0, 16, 0, 16);
    
    // 自定义阴影默认值
    self.customShadowOffset = CGSizeMake(0, 0);
    self.customShadowBlurRadius = 0.0;
    self.customShadowColor = [UIColor clearColor];
}

- (void)drawTextInRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        [super drawTextInRect:rect];
        return;
    }
    
    // 应用内边距
    CGRect insetRect = UIEdgeInsetsInsetRect(rect, self.textInsets);
    
    // 如果有描边和阴影效果
    if (self.strokeWidth > 0 && self.strokeColor && self.customShadowColor && !CGSizeEqualToSize(self.customShadowOffset, CGSizeZero)) {
        
        // 保存原始文字颜色
        UIColor *originalTextColor = self.textColor;
        
        // 第一步：在偏移位置绘制阴影（阴影色的描边+填充）
        CGRect shadowRect = CGRectOffset(insetRect, self.customShadowOffset.width, self.customShadowOffset.height);
        
        // 绘制阴影的描边
        CGContextSetLineWidth(context, self.strokeWidth);
        CGContextSetLineJoin(context, kCGLineJoinRound);
        CGContextSetTextDrawingMode(context, kCGTextStroke);
        self.textColor = self.customShadowColor;
        [super drawTextInRect:shadowRect];
        
        // 绘制阴影的填充
        CGContextSetTextDrawingMode(context, kCGTextFill);
        self.textColor = self.customShadowColor;
        [super drawTextInRect:shadowRect];
        
        // 第二步：在正常位置绘制描边
        CGContextSetLineWidth(context, self.strokeWidth);
        CGContextSetLineJoin(context, kCGLineJoinRound);
        CGContextSetTextDrawingMode(context, kCGTextStroke);
        self.textColor = self.strokeColor;
        [super drawTextInRect:insetRect];
        
        // 第三步：在正常位置绘制填充文字
        CGContextSetTextDrawingMode(context, kCGTextFill);
        self.textColor = originalTextColor;
        [super drawTextInRect:insetRect];
        
    } else if (self.strokeWidth > 0 && self.strokeColor) {
        // 只有描边，无阴影
        CGContextSetLineWidth(context, self.strokeWidth);
        CGContextSetLineJoin(context, kCGLineJoinRound);
        CGContextSetTextDrawingMode(context, kCGTextStroke);
        
        // 保存原始文字颜色
        UIColor *originalTextColor = self.textColor;
        
        // 设置描边颜色
        self.textColor = self.strokeColor;
        [super drawTextInRect:insetRect];
        
        // 绘制填充文字
        CGContextSetTextDrawingMode(context, kCGTextFill);
        self.textColor = originalTextColor;
        [super drawTextInRect:insetRect];
        
    } else if (self.customShadowColor && !CGSizeEqualToSize(self.customShadowOffset, CGSizeZero)) {
        // 只有阴影，无描边
        CGRect shadowRect = CGRectOffset(insetRect, self.customShadowOffset.width, self.customShadowOffset.height);
        
        // 先绘制阴影
        self.textColor = self.customShadowColor;
        [super drawTextInRect:shadowRect];
        
        // 再绘制正常文字
        self.textColor = self.textColor; // 恢复原始颜色
        [super drawTextInRect:insetRect];
        
    } else {
        // 普通文字绘制
        [super drawTextInRect:insetRect];
    }
}

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines {
    UIEdgeInsets insets = self.textInsets;
    CGRect insetBounds = UIEdgeInsetsInsetRect(bounds, insets);
    CGRect textRect = [super textRectForBounds:insetBounds limitedToNumberOfLines:numberOfLines];
    
    textRect.origin.x -= insets.left;
    textRect.origin.y -= insets.top;
    textRect.size.width += (insets.left + insets.right);
    textRect.size.height += (insets.top + insets.bottom);
    
    return textRect;
}


@end
