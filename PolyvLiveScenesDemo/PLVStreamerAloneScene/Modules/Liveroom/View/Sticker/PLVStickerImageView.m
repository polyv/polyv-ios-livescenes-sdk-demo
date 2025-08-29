//
//  PLVStickerImageView.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/3/17.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVStickerImageView.h"
#import "PLVStickerGestureRecognizer.h"
#import <PLVFoundationSDK/PLVColorUtil.h>

@interface PLVStickerImageView ()<
PLVStickerImageViewDelegate
>

@property (nonatomic, strong) UIImageView *contentView;

@property (nonatomic, strong) CAShapeLayer *shapeLayer;

@property (nonatomic, assign) BOOL enablePinchGesture;
@property (nonatomic, assign) BOOL enablePanGesture;

@property (nonatomic, assign) UIEdgeInsets moveEdgeInserts; // 安全边距
@property (nonatomic, assign) CGRect moveableRect;         // 可移动范围

@property (nonatomic, strong) UIButton *doneButton;

@end

@implementation PLVStickerImageView

#pragma mark - Initialization
// 布局变化时更新可移动范围
- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateMoveableRect];
    [self updateDoneButtonPosition];
}

- (instancetype)initWithFrame:(CGRect)frame contentImage:(UIImage *)contentImage {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _stickerMinScale = 0.1;
        _stickerMaxScale = 10;
        _enablePinchGesture = YES;
        _enablePanGesture = YES;
        self.clipsToBounds = YES;
        
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
    self.contentView.contentMode = UIViewContentModeScaleAspectFill;
    self.contentView.clipsToBounds = YES;
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

#pragma mark - Lazy Loading

- (UIButton *)doneButton {
    if (!_doneButton) {
        _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _doneButton.frame = CGRectMake(0, 0, 24, 24);
        [_doneButton setTitle:@"✓" forState:UIControlStateNormal];
        [_doneButton setTitleColor:[PLVColorUtil colorFromHexString:@"#1D2129" alpha:1.0] forState:UIControlStateNormal];
        _doneButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        _doneButton.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        _doneButton.layer.cornerRadius = 12;
        _doneButton.layer.masksToBounds = YES;
        _doneButton.layer.borderWidth = 1;
        _doneButton.layer.borderColor = [UIColor whiteColor].CGColor;
        [_doneButton addTarget:self action:@selector(handleDoneButtonTap:) forControlEvents:UIControlEventTouchUpInside];
        
        // 初始状态隐藏
        _doneButton.hidden = YES;
        _doneButton.userInteractionEnabled = YES;
        
        // 添加到父视图而不是当前视图，避免受到 transform 影响
        if (self.superview) {
            [self.superview addSubview:_doneButton];
            // 立即确保在最上层
            [self.superview bringSubviewToFront:_doneButton];
        }
    }
    return _doneButton;
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
    
    // 确保 doneButton 仍然在最上层
    if (self.doneButton && !self.doneButton.hidden) {
        [self.superview bringSubviewToFront:self.doneButton];
    }
   
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

    // 实时更新 done 按钮位置
    [self updateDoneButtonPosition];

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
    
    // 缩放过程中完全自由，不做任何限制
    if (gesture.state == UIGestureRecognizerStateChanged) {
        // 直接应用缩放变换
        self.transform = CGAffineTransformScale(self.transform, scale, scale);
        gesture.scale = 1.0;
        
        // 实时更新 done 按钮位置
        [self updateDoneButtonPosition];
    }
    // 手势结束时进行调整
    else if (gesture.state == UIGestureRecognizerStateEnded || 
             gesture.state == UIGestureRecognizerStateCancelled) {
        
        // 先应用最后的缩放
        self.transform = CGAffineTransformScale(self.transform, scale, scale);
        gesture.scale = 1.0;
        
        // 手势结束后调整位置和缩放比例
        [self adjustAfterScaleGestureEnded];
    }
}

// 手势结束后调整位置和缩放比例
- (void)adjustAfterScaleGestureEnded {
    CGRect parentBounds = self.superview.bounds;
    CGRect currentFrame = self.frame;
    
    // 检查是否超过父视图的宽度或高度
    BOOL exceedsWidth = currentFrame.size.width > parentBounds.size.width;
    BOOL exceedsHeight = currentFrame.size.height > parentBounds.size.height;
    
    if (exceedsWidth || exceedsHeight) {
        // 超过父视图尺寸 显示done 按钮
        
        // 超过父视图尺寸，需要调整缩放比例
        CGFloat scaleToFitWidth = parentBounds.size.width / currentFrame.size.width;
        CGFloat scaleToFitHeight = parentBounds.size.height / currentFrame.size.height;
        
        // 选择更严格的缩放比例，确保完全适合父视图
        CGFloat targetScale = MIN(scaleToFitWidth, scaleToFitHeight);
        targetScale += 0.01 ;// 像素微调 解决边缘对齐问题
        
        [UIView animateWithDuration:0.3 animations:^{
            self.transform = CGAffineTransformScale(self.transform, targetScale, targetScale);
        } completion:^(BOOL finished) {
            // 缩放完成后调整位置
            [self adjustPositionToFitBounds];
            // 更新 done 按钮位置
            [self updateDoneButtonPosition];
        }];
    } else {
        // 没有超过父视图尺寸，只需要调整位置
        [self adjustPositionToFitBounds];
    }
}

// 调整位置到边界内
- (void)adjustPositionToFitBounds {
    CGRect parentBounds = self.superview.bounds;
    CGRect currentFrame = self.frame;
    
    CGPoint newCenter = self.center;
    BOOL needsAdjustment = NO;
    
    // 调整水平位置
    if (currentFrame.origin.x < 0) {
        newCenter.x = currentFrame.size.width / 2;
        needsAdjustment = YES;
    } else if (currentFrame.origin.x + currentFrame.size.width > parentBounds.size.width) {
        newCenter.x = parentBounds.size.width - currentFrame.size.width / 2;
        needsAdjustment = YES;
    }
    
    // 调整垂直位置
    if (currentFrame.origin.y < 0) {
        newCenter.y = currentFrame.size.height / 2;
        needsAdjustment = YES;
    } else if (currentFrame.origin.y + currentFrame.size.height > parentBounds.size.height) {
        newCenter.y = parentBounds.size.height - currentFrame.size.height / 2;
        needsAdjustment = YES;
    }
    
    // 如果需要调整位置，使用动画
    if (needsAdjustment) {
        [UIView animateWithDuration:0.3 
                              delay:0 
                            options:UIViewAnimationOptionCurveEaseOut 
                         animations:^{
            self.center = newCenter;
        } completion:^(BOOL finished) {
            // 位置调整完成后更新 done 按钮位置
            [self updateDoneButtonPosition];
        }];
    }
}

#pragma mark - Done Button Methods

// 更新Done按钮位置
- (void)updateDoneButtonPosition {
    if (self.doneButton && !self.doneButton.hidden && self.superview) {
        // 计算经过 transform 后的实际边界在父视图中的位置
        CGRect transformedBounds = CGRectApplyAffineTransform(self.bounds, self.transform);
        
        // 获取右上角在父视图坐标系中的位置
        CGPoint rightTopCorner = CGPointMake(self.center.x + transformedBounds.size.width / 2,
                                           self.center.y - transformedBounds.size.height / 2);
        
        // done 按钮的大小
        CGFloat buttonSize = 24;
        CGFloat margin = 5; // 距离右上角的边距
        
        // 设置 done 按钮位置（在右上角内侧）
        self.doneButton.frame = CGRectMake(rightTopCorner.x - buttonSize - margin,
                                          rightTopCorner.y + margin,
                                          buttonSize,
                                          buttonSize);
        
        // 确保 doneButton 在最上层
        [self.superview bringSubviewToFront:self.doneButton];
    }
    NSLog(@"-- updateDoneButtonPosition: stickerBounds:%@, center:%@, transform:%@ --", 
          NSStringFromCGRect(self.bounds), 
          NSStringFromCGPoint(self.center),
          NSStringFromCGAffineTransform(self.transform));
}

// Done按钮点击处理
- (void)handleDoneButtonTap:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plv_StickerViewDidTapDoneButton:)]) {
        [self.delegate plv_StickerViewDidTapDoneButton:self];
    }
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
        // 显示Done按钮
        if (self.doneButton.superview != self.superview && self.superview) {
            // 如果 done 按钮不在正确的父视图中，重新添加
            [self.doneButton removeFromSuperview];
            [self.superview addSubview:self.doneButton];
        }
        self.doneButton.hidden = NO;
        [self updateDoneButtonPosition];
        
        // 确保 doneButton 在所有 stickerImageView 的上层
        [self.superview bringSubviewToFront:self.doneButton];
    } else {
        [self.shapeLayer removeFromSuperlayer];
        // 隐藏Done按钮
        self.doneButton.hidden = YES;
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
//    [self setEnabledBorder:enableEdit];
}

#pragma mark - Helper Methods

// 更新可移动范围
- (void)updateMoveableRect {
    CGRect parentBounds = self.superview.bounds;
    BOOL fullscreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (fullscreen){
//        self.moveEdgeInserts = UIEdgeInsetsMake(20, 20, 20, 20);
        self.moveEdgeInserts = UIEdgeInsetsMake(0, 0, 0, 0);

    }
    else{
//        self.moveEdgeInserts = UIEdgeInsetsMake(30, 20, 30, 20);
        self.moveEdgeInserts = UIEdgeInsetsMake(0, 0, 0, 0);

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

#pragma mark - Cleanup

- (void)dealloc {
    // 确保清理 done 按钮
    if (self.doneButton) {
        [self.doneButton removeFromSuperview];
        self.doneButton = nil;
    }
}

@end
