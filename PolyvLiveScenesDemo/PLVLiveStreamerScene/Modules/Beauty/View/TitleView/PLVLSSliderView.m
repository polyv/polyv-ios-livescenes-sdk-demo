//
//  PLVLSSliderView.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/5/6.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSSliderView.h"

@interface PLVLSSliderView() {
    // 基本布局数据
    CGFloat _width;
    CGFloat _height;
    CGFloat _realPaddingLeft;
    CGFloat _realPaddingRight;
    
    // 实时绘制相关数据
    CGFloat _currentX;
    CGFloat _currentY;
    CGFloat _currentDefaultCircleX;
    CGFloat _currentDefaultCircleY;
    CGFloat _currentCircleY;
}

@end

@implementation PLVLSSliderView
@synthesize progress = _progress;

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initDefaultSize];
        [self initSize:frame];
    }
    return self;
}

#pragma mark - [ Override ]
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self checkSize:rect];
    
    // 初始化环境
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetShouldAntialias(context, true);
    CGContextClearRect(context, rect);
    CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 1, [UIColor colorWithWhite:0 alpha:0.4].CGColor); // 四周阴影
    
    // 依次画出每一个部分
    [self computeSize]; // 计算数值
    [self drawLine:context]; // 画滑动条
    [self drawDefaultValueCircle:context]; // 画默认进度
    [self drawCircle:context]; // 画触摸快
}

#pragma mark 监听手势操作
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject]; // 获取手的位置
    [self dispatchX:[touch locationInView:self].x];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject]; // 获取手的位置
    [self dispatchX:[touch locationInView:self].x];
}

#pragma mark - [ Public Method ]
#pragma mark Setter
- (void)setCircleRadius:(CGFloat)circleRadius {
    _circleRadius = circleRadius;
    [self initSize:self.frame];
}

- (void)setDefaultCircleRadius:(CGFloat)defaultCircleRadius {
    _defaultCircleRadius = defaultCircleRadius;
    [self initSize:self.frame];
}

- (void)setPaddingLeft:(CGFloat)paddingLeft {
    _paddingLeft = paddingLeft;
    [self initSize:self.frame];
}

- (void)setPaddingRight:(CGFloat)paddingRight {
    _paddingRight = paddingRight;
    [self initSize:self.frame];
}

- (void)setPaddingBottom:(CGFloat)paddingBottom {
    _paddingBottom = paddingBottom;
    [self initSize:self.frame];
}

- (void)setProgress:(CGFloat)progress {
    if (progress > 1) {
        progress = 1;
    } else if (progress < 0) {
        progress = 0;
    }
    _progress = progress;
    [self setNeedsDisplay];
}

- (void)setDefaultProgress:(CGFloat)defaultProgress {
    if (defaultProgress > 1) {
        defaultProgress = 1;
    } else if (defaultProgress < 0) {
        defaultProgress = 0;
    }
    _defaultProgress = defaultProgress;
    [self setNeedsDisplay];
}

#pragma mark 初始化
// 设置默认各数据的默认值
- (void)initDefaultSize {
    _activeLineColor = [UIColor colorWithRed:51/255.0 green:153/255.0 blue:255/255.0 alpha:1/1.0];;
    _inactiveLineColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:0.4/1.0];
    _circleColor = [UIColor colorWithWhite:1 alpha:1];
    _lineHeight = DEFAULT_LINE_HEIGHT;
    _circleRadius = DEFAULT_CIRCLE_RADIUS;
    _defaultCircleRadius = DEFAULT_DEFAULT_CIRCLE_RADIUS;
    _paddingLeft = DEFAULT_PADDING_LEFT;
    _paddingRight = DEFAULT_PADDING_RIGHT;
    _paddingBottom = DEFAULT_PADDING_BOTTOM;
    _progress = 0;
}

- (void)initSize:(CGRect)frame {
    _width = frame.size.width;
    _height = frame.size.height;
    
    _realPaddingLeft = _circleRadius/2 + _paddingLeft;
    _realPaddingRight = _circleRadius/2 + _paddingRight;
}

# pragma mark 绘制操作
- (void)drawCGLine:(CGContextRef)context rect:(CGRect)rect color:(UIColor*)color {
    CGContextClipToRect(context, rect);
    CGContextSetStrokeColorWithColor(context, [color CGColor]);
    CGContextMoveToPoint(context, _realPaddingLeft, _currentY);
    CGContextAddLineToPoint(context, _width - _realPaddingRight, _currentY); // _currentY:画笔的中心点
    CGContextDrawPath(context, kCGPathFillStroke);
    CGContextResetClip(context);
}

- (void)drawLine:(CGContextRef)context {
    CGContextSetLineWidth(context, _lineHeight);
    CGContextSetLineCap(context, kCGLineCapRound);
    
    CGFloat radius = _circleRadius;
    CGFloat offset = -_lineHeight / 2 + _lineHeight * _progress;
    CGFloat padding = 2; // 两个像素间距
    // 画左边滑动条
    [self drawCGLine:context rect:CGRectMake(0, _paddingBottom, _currentX + offset - radius / 2 - padding, _height) color:_activeLineColor];
    
    // 画右边滑动条
    [self drawCGLine:context rect:CGRectMake(_currentX + offset  + padding + radius / 2, _paddingBottom, _width, _height) color:_inactiveLineColor];
}

- (void)drawCircle:(CGContextRef)context rect:(CGRect)rect color:(UIColor*)color {
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextAddEllipseInRect(context, rect);
    CGContextDrawPath(context, kCGPathFill);
}

- (void)drawCircle:(CGContextRef)context {
    CGFloat radius = _circleRadius;
    // x 在原来的基础上向左偏移半个半径
    CGFloat x = _currentX - radius / 2;
    CGFloat y = _currentCircleY;
    CGRect rect = CGRectMake(x, y, radius, radius);
    [self drawCircle:context rect:rect color:_circleColor];
    [self notifyListenerDidChangedCircleRect:rect];
}

- (void)drawDefaultValueCircle:(CGContextRef)context {
    [self drawCircle:context rect:CGRectMake(_currentDefaultCircleX, _currentDefaultCircleY, _defaultCircleRadius, _defaultCircleRadius) color:_circleColor];
}

#pragma mark 工具方法
// 剪裁 x ，使 x 的值处于绘制区域
- (CGFloat)clip:(CGFloat)x {
    if (x < _realPaddingLeft) {
        x = _realPaddingLeft;
    }
    if (x > _width - _realPaddingRight) {
        x = _width - _realPaddingRight;
    }
    return x;
}

// 根据 x 的位置，计算出当前的进度，将其分发出去，并请求重绘
- (void)dispatchX:(CGFloat)x {
    x = [self clip:x];
    CGFloat progress = (x - _realPaddingLeft) / (_width - _realPaddingLeft - _realPaddingRight);
    
    if (_progress != progress) {
        _progress = progress;
        // 震动反馈
        if (progress == 0 || progress == 1) {
            if (@available(iOS 10.0, *)) {
                UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle: UIImpactFeedbackStyleLight];
                [generator prepare];
                [generator impactOccurred];
            } else {
                // Fallback on earlier versions
            }
        }
        // 分发结果
        [self notifyListenerDidChangedValue:_progress];
        // 请求重绘
       [self setNeedsDisplay];
    }
}

// 根据当前的进度，计算当前 x y 的值
- (void)computeSize {
    CGFloat width = _width - _realPaddingLeft - _realPaddingRight;
    _currentX = width * _progress + _realPaddingLeft;
    _currentY = _height / 2; // 画笔的中心点在视图保持一致
    _currentDefaultCircleX = width * _defaultProgress + _realPaddingLeft;
    _currentDefaultCircleY = _height / 2 - _defaultCircleRadius / 2;
    _currentCircleY = _paddingBottom;
}

- (void)checkSize:(CGRect)rect {
    if (_width != CGRectGetWidth(rect) || _height != CGRectGetHeight(rect)) {
        [self initSize:rect];
    }
}

#pragma mark NotifyListener
- (void)notifyListenerDidChangedValue:(CGFloat)value {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(sliderView:didChangedValue:)]) {
        [self.delegate sliderView:self didChangedValue:value];
    }
}

- (void)notifyListenerDidChangedCircleRect:(CGRect)rect {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(sliderView:didChangedCircleRect:)]) {
        [self.delegate sliderView:self didChangedCircleRect:rect];
    }
}

@end
