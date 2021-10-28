//
//  PLVHCBrushColorButton.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/30.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCBrushColorButton.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCBrushColorButton()

@end

@implementation PLVHCBrushColorButton

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    if (self = [super init]) {
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setNeedsDisplay];
}

#pragma mark - [ Override ]

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIColor *bgColor;
    if (self.bgColor) {
        bgColor = self.bgColor;
    } else {
        bgColor = self.enabled ? [UIColor clearColor] : PLV_UIColorFromRGB(@"#2D3452");
    }
    
    CGContextSetFillColorWithColor(context, bgColor.CGColor);
    CGContextAddArc(context, rect.size.width / 2, rect.size.height / 2, rect.size.height / 2, 0, 2 * M_PI, 0);
    CGContextDrawPath(context, kCGPathFill);
    
    CGContextSetFillColorWithColor(context, self.color.CGColor);
    CGContextAddArc(context, rect.size.width / 2, rect.size.height / 2, 6, 0, 2 * M_PI, 0);
    CGContextDrawPath(context, kCGPathFill);
    CGContextFillPath(context);
}

#pragma mark - [ Public Method ]

- (void)setColor:(UIColor *)color {
    _color = color;
    [self setNeedsDisplay];
}

@end
