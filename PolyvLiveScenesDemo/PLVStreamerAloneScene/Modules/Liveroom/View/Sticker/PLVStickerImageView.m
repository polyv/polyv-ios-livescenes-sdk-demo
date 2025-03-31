//
//  PLVStickerImageView.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/3/17.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVStickerImageView.h"
#import "PLVStickerGestureRecognizer.h"

@interface PLVStickerImageView ()<
PLVStickerImageViewDelegate
>

@property (nonatomic, strong) UIImageView *contentView;

@property (nonatomic, strong) CAShapeLayer *shapeLayer;

@property (nonatomic, assign) BOOL enablePinchGesture;
@property (nonatomic, assign) BOOL enablePanGesture;

@property (nonatomic, assign) UIEdgeInsets moveEdgeInserts; // 安全边距
@property (nonatomic, assign) CGRect moveableRect;         // 可移动范围

@end

@implementation PLVStickerImageView

#pragma mark - Initialization
// 布局变化时更新可移动范围
- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateMoveableRect];
}

- (instancetype)initWithFrame:(CGRect)frame contentImage:(UIImage *)contentImage {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blueColor];
        _stickerMinScale = 0.1;
        _stickerMaxScale = 10;
        _enablePinchGesture = YES;
        _enablePanGesture = YES;
        
        // 设置默认的安全边距
        _moveEdgeInserts = UIEdgeInsetsMake(30, 20, 30, 20);
        
        [self setupContentViewWithFrame:frame];
        [self initShapeLayer];
        [self setupConfig];
        [self attachGestures];
        
        self.contentImage = contentImage;
    }
    return self;
}

#pragma mark - Setup Methods

- (void)setupContentViewWithFrame:(CGRect)frame {
    self.contentView = [[UIImageView alloc] initWithFrame:CGRectMake(0,
                                                                    0,
                                                                    frame.size.width,
                                                                    frame.size.height)];
    [self addSubview:self.contentView];
}

- (void)initShapeLayer {
    self.shapeLayer = [CAShapeLayer layer];
    CGRect shapeRect = self.contentView.frame;
    self.shapeLayer.bounds = shapeRect;
    self.shapeLayer.position = CGPointMake(self.contentView.frame.size.width / 2, self.contentView.frame.size.height / 2);
    self.shapeLayer.fillColor = [UIColor clearColor].CGColor;
    self.shapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    self.shapeLayer.lineWidth = 2.0;
    self.shapeLayer.lineJoin = kCALineJoinRound;
    self.shapeLayer.allowsEdgeAntialiasing = YES;
//    self.shapeLayer.lineDashPattern = @[@5, @3];
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, shapeRect);
    self.shapeLayer.path = path;
    CGPathRelease(path);
}

- (void)setupConfig {
    self.exclusiveTouch = YES;
    
    self.userInteractionEnabled = YES;
    self.contentView.userInteractionEnabled = YES;
    self.enabledControl = YES;
    
    self.enabledShakeAnimation = YES;
    self.enabledBorder = YES;
}

- (void)attachGestures {
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleScale:)];
    pinchGesture.delegate = self;
    [self.contentView addGestureRecognizer:pinchGesture];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMove:)];
    panGesture.minimumNumberOfTouches = 1;
    panGesture.maximumNumberOfTouches = 2;
    panGesture.delegate = self;
    [self.contentView addGestureRecognizer:panGesture];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.delegate = self;
    [self.contentView addGestureRecognizer:tapGesture];
    
}

#pragma mark - Gesture Handlers

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if (!self.delegate) {
        return;
    }
    
    [self handleTapContentView];
   
}

- (void)handleTapContentView {
    [self.superview bringSubviewToFront:self];
   
    [self.delegate plv_StickerViewDidTapContentView:self];
}

- (void)handleMove:(UIPanGestureRecognizer *)gesture {
    if (!self.enablePanGesture) return;
    
    CGPoint translation = [gesture translationInView:self.superview];
    
    // 计算新位置
    CGPoint newCenter = CGPointMake(self.center.x + translation.x,
                                  self.center.y + translation.y);
    
    // 限制在安全范围内
    CGPoint limitedPoint = [self limitPointInBounds:CGPointMake(newCenter.x - self.frame.size.width/2,
                                                              newCenter.y - self.frame.size.height/2)];
    self.center = CGPointMake(limitedPoint.x + self.frame.size.width/2,
                             limitedPoint.y + self.frame.size.height/2);
    
    // 重置手势的位移
    [gesture setTranslation:CGPointZero inView:self.superview];

    CGPoint touchPoint = [gesture locationInView:self.superview.superview];
    BOOL isEnded = gesture.state == UIGestureRecognizerStateEnded ||
        gesture.state == UIGestureRecognizerStateCancelled;
   
    if (self.delegate && [self.delegate respondsToSelector:@selector(plv_StickerViewHandleMove:point:gestureEnded:)]) {
        [self.delegate plv_StickerViewHandleMove:self point:touchPoint gestureEnded:isEnded];
    }
}

- (void)handleScale:(UIPinchGestureRecognizer *)gesture {
    if (!self.enablePinchGesture) return;
    
    CGFloat scale = gesture.scale;
    CGFloat currentScale = [[self.contentView.layer valueForKeyPath:@"transform.scale"] floatValue];
    
//    // 检查最小最大缩放限制
//    if (!(self.stickerMinScale == 0 && self.stickerMaxScale == 0)) {
//        if (scale * currentScale <= self.stickerMinScale) {
//            scale = self.stickerMinScale / currentScale;
//        }
//        if (scale * currentScale >= self.stickerMaxScale) {
//            scale = self.stickerMaxScale / currentScale;
//        }
//    }
    
    // 计算缩放后的frame
    CGRect newFrame = self.frame;
    newFrame.size.width *= scale;
    newFrame.size.height *= scale;
    
    // 检查是否超出父视图边界
    if (newFrame.origin.x < 0 ||
        newFrame.origin.y < 0 ||
        newFrame.origin.x + newFrame.size.width > self.superview.bounds.size.width ||
        newFrame.origin.y + newFrame.size.height > self.superview.bounds.size.height) {
        // 如果会超出边界，就不执行缩放
        
        return;
    }
    
    // 检查最小最大缩放限制
    if (!(self.stickerMinScale == 0 && self.stickerMaxScale == 0)) {
        if (scale * currentScale <= self.stickerMinScale) {
            scale = self.stickerMinScale / currentScale;
        }
        if (scale * currentScale >= self.stickerMaxScale) {
            scale = self.stickerMaxScale / currentScale;
        }
    }
    
    // 应用缩放变换
    self.transform = CGAffineTransformScale(self.transform, scale, scale);
    gesture.scale = 1.0;
}

#pragma mark - Animation

- (void)performShakeAnimation:(UIView *)targetView {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation"];
    animation.values = @[@(-0.1), @(0.1), @(-0.1)];
    animation.duration = 0.25;
    animation.repeatCount = 1;
    [targetView.layer addAnimation:animation forKey:@"shakeAnimation"];
}

#pragma mark - Public Methods

- (void)performTapOperation {
    [self handleTapContentView];
}

#pragma mark - Property Setters

- (void)setEnabledControl:(BOOL)enabledControl {
    _enabledControl = enabledControl;
}

- (void)setEnabledBorder:(BOOL)enabledBorder {
    _enabledBorder = enabledBorder;
    if (enabledBorder) {
        [self.contentView.layer addSublayer:self.shapeLayer];
    } else {
        [self.shapeLayer removeFromSuperlayer];
    }
}

- (void)setContentImage:(UIImage *)contentImage {
    _contentImage = contentImage;
    self.contentView.image = contentImage;
}

- (void)setEnableEdit:(BOOL)enableEdit{
    _enablePanGesture = enableEdit;
    _enablePinchGesture = enableEdit;
    
    [self setEnabledControl:enableEdit];
}

#pragma mark - Helper Methods

// 更新可移动范围
- (void)updateMoveableRect {
    CGRect parentBounds = self.superview.bounds;
    BOOL fullscreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (fullscreen){
        self.moveEdgeInserts = UIEdgeInsetsMake(20, 20, 20, 20);
    }
    else{
        self.moveEdgeInserts = UIEdgeInsetsMake(30, 20, 30, 20);
    }
    self.moveableRect = CGRectMake(self.moveEdgeInserts.left,
                                  self.moveEdgeInserts.top,
                                  parentBounds.size.width - self.moveEdgeInserts.left - self.moveEdgeInserts.right,
                                  parentBounds.size.height - self.moveEdgeInserts.top - self.moveEdgeInserts.bottom);
}

// 在处理移动时检查范围
- (CGPoint)limitPointInBounds:(CGPoint)point {
    // 获取控件的大小
    CGSize size = self.frame.size;
    size = self.frame.size;
    
    // 计算允许移动的最大最小值
    CGFloat minX = self.moveableRect.origin.x;
    CGFloat maxX = CGRectGetMaxX(self.moveableRect) - size.width;
    CGFloat minY = self.moveableRect.origin.y;
    CGFloat maxY = CGRectGetMaxY(self.moveableRect) - size.height;
    
    // 限制在安全范围内
    point.x = MAX(minX, MIN(maxX, point.x));
    point.y = MAX(minY, MIN(maxY, point.y));
    
    return point;
}

@end
