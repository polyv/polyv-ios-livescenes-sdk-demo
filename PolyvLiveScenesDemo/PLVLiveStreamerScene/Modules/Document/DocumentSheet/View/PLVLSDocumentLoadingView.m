//
//  PLVLSDocumentLoadingView.m
//  PLVLiveStreamerDemo
//
//  Created by Hank on 2021/3/11.
//  Copyright © 2021 PLV. All rights reserved.
//  加载文档页面进度条

#import "PLVLSDocumentLoadingView.h"

#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLSDocumentLoadingView ()

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) NSInteger count;
@property (nonatomic, assign) CGFloat maxR;
@property (nonatomic, assign) CGFloat minR;

@property (nonatomic, assign) CGFloat animatingAngle;

@end

@implementation PLVLSDocumentLoadingView

- (instancetype)init {
    if (self = [super init]) {
        [self initConfig];
    }
    
    return self;
}

- (void)initConfig {
    _color = [UIColor whiteColor];
    _count = 8;
    _maxR = 2.5;
    _minR = 1.25f;
}

- (void)startAnimating {
    if (self.timer) {
        return;
    }
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:[PLVFWeakProxy proxyWithTarget:self]
                                                selector:@selector(animatingAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stopAnimating {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)animatingAction {
    self.animatingAngle -= 2 * M_PI / self.count;
    if (self.animatingAngle <= 0) {
        self.animatingAngle = 2 * M_PI;
    }
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGFloat radius = self.maxR;
    CGFloat rMinus = (self.maxR - self.minR) / self.count;
    
    // 同心圆半径
    CGFloat r = 10;
    // 两圆心夹角度
    CGFloat angle = 2 * M_PI / self.count;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat currAngle = M_PI / 2.0f + self.animatingAngle;
    CGFloat x = 0, y = 0;
    for (NSInteger i = 0; i < self.count; i++) {
        x = self.center.x + r * cosf(currAngle);
        y = self.center.y - r * sinf(currAngle);
        
        CGContextSetFillColorWithColor(context, self.color.CGColor);
        CGContextAddArc(context, x, y, radius, 0, 2 * M_PI, 0);
        CGContextDrawPath(context, kCGPathFill);
        
        radius -= rMinus;
        currAngle += angle;
    }
    
    CGContextFillPath(context);
}

- (void)dealloc {
    [self stopAnimating];
}

@end
