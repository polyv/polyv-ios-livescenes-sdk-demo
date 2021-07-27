//
//  PLVLSDocumentBrushColorView.m
//  PLVLiveScenesDemo
//
//  Created by Hank on 2021/3/2.
//  Copyright © 2021 PLV. All rights reserved.
//  颜色按钮

#import "PLVLSDocumentBrushColorView.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLSDocumentBrushColorView ()

@end

@implementation PLVLSDocumentBrushColorView

- (instancetype)init {
    if (self = [super init]) {
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (! self.enabled) {
        CGContextSetStrokeColorWithColor(context, PLV_UIColorFromRGB(@"#F0F1F5").CGColor);
        CGContextSetLineWidth(context, 3.0);
        CGContextAddArc(context, rect.size.width / 2, rect.size.height / 2, rect.size.width / 2 - 1, 0, 2 * M_PI, 0);
        CGContextDrawPath(context, kCGPathStroke);
        
        CGContextSetStrokeColorWithColor(context, PLV_UIColorFromRGB(@"#313542").CGColor);
        CGContextSetLineWidth(context, 1.0);
        CGContextAddArc(context, rect.size.width / 2, rect.size.height / 2, rect.size.width / 2 - 3, 0, 2 * M_PI, 0);
        CGContextDrawPath(context, kCGPathStroke);
    }
    
    CGContextSetFillColorWithColor(context, self.color.CGColor);
    CGContextAddArc(context, rect.size.width / 2, rect.size.height / 2, rect.size.width / 2 - 4, 0, 2 * M_PI, 0);
    CGContextDrawPath(context, kCGPathFill);
    CGContextFillPath(context);
}

@end
