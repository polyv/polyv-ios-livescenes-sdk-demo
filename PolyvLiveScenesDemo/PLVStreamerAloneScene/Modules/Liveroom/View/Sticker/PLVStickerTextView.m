//
//  PLVStickerTextView.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2023/9/15.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVStickerTextView.h"
#import "PLVStickerGestureRecognizer.h"
#import "PLVStickerEffectLable.h"
#import "PLVStickerEffectText.h"
#import "PLVSAUtils.h"

@interface PLVStickerTextView ()

@property (nonatomic, strong) PLVStickerEffectText *effectText;
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *editButton;

@property (nonatomic, assign) BOOL enablePinchGesture;
@property (nonatomic, assign) BOOL enablePanGesture;

@property (nonatomic, assign) UIEdgeInsets moveEdgeInserts; // 安全边距
@property (nonatomic, assign) CGRect moveableRect;         // 可移动范围

@end

@implementation PLVStickerTextView

#pragma mark - Initialization

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateMoveableRect];
    
    CGFloat buttonSize = 30.0;
    self.deleteButton.frame = CGRectMake(-buttonSize/2, -buttonSize/2, buttonSize, buttonSize);
    self.editButton.frame = CGRectMake(self.bounds.size.width - buttonSize/2, -buttonSize/2, buttonSize, buttonSize);
    
    self.effectText.frame = self.bounds;
}

- (instancetype)initWithFrame:(CGRect)frame textModel:(PLVStickerTextModel *)textModel {
    self = [super initWithFrame:frame];
    if (self) {
        _enablePinchGesture = YES;
        _enablePanGesture = YES;
        _editState = PLVStickerTextEditStateNormal; // 初始化为普通状态
        _isNewlyAdded = NO; // 默认不是新增贴纸，只有通过addTextStickerWithModel添加的才是新增
        
        // 设置默认的安全边距
        _moveEdgeInserts = UIEdgeInsetsMake(30, 20, 30, 20);
        
        [self setupContentViewWithFrame:frame];
        [self initShapeLayer];
        [self setupConfig];
        [self setupButtons];
        [self attachGestures];
        
        self.textModel = textModel;
    }
    return self;
}

#pragma mark - Setup Methods

- (void)setupContentViewWithFrame:(CGRect)frame {
    self.effectText = [[PLVStickerEffectText alloc] initWithText:self.textModel.text templateType:self.textModel.templateType];
    [self addSubview:self.effectText];
}

- (void)initShapeLayer {
    self.shapeLayer = [CAShapeLayer layer];
    self.shapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    self.shapeLayer.fillColor = [UIColor clearColor].CGColor;
    self.shapeLayer.lineWidth = 1.0;
    self.shapeLayer.lineDashPattern = @[@4, @2];
    [self.layer addSublayer:self.shapeLayer];
    
    self.enabledBorder = NO;
}

- (void)setupConfig {
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = NO;
    self.layer.masksToBounds = NO;
}

- (void)setupButtons {
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.deleteButton.backgroundColor = [UIColor clearColor];
    [self.deleteButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_livemroom_stickertext_del"] forState:UIControlStateNormal];
    [self.deleteButton addTarget:self action:@selector(handleDeleteButtonTap) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.deleteButton];
    
    self.editButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.editButton.backgroundColor = [UIColor clearColor];
    [self.editButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_livemroom_stickertext_edit"] forState:UIControlStateNormal];
    [self.editButton addTarget:self action:@selector(handleEditButtonTap) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.editButton];
    
    self.deleteButton.hidden = YES;
    self.editButton.hidden = YES;
}

- (void)attachGestures {
    // 添加点击手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGesture.delegate = self;
    tapGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapGesture];
    
    // 添加双击手势
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    doubleTapGesture.delegate = self;
    doubleTapGesture.numberOfTapsRequired = 2;
    [self addGestureRecognizer:doubleTapGesture];
    
    // 单击手势应该在双击手势失败后才生效
    [tapGesture requireGestureRecognizerToFail:doubleTapGesture];
    
    // 添加拖动手势
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMove:)];
    panGesture.delegate = self;
    [self addGestureRecognizer:panGesture];

}

#pragma mark - Property Setters

- (void)setTextModel:(PLVStickerTextModel *)textModel {
    _textModel = textModel;
    
    [self.effectText updateText:textModel.text templateType:textModel.templateType];

    // 更新边框路径
    [self updateBorderPath];
}

- (void)setEnabledBorder:(BOOL)enabledBorder {
    _enabledBorder = enabledBorder;
    self.shapeLayer.hidden = !enabledBorder;
    
    if (enabledBorder) {
        [self updateBorderPath];
    }
}

- (void)setEnableEdit:(BOOL)enableEdit {
    _enableEdit = enableEdit;
    self.enablePanGesture = enableEdit;
    self.enablePinchGesture = enableEdit;
    
    if (!enableEdit){
        // 关闭编辑模式
        _editState = PLVStickerTextEditStateNormal;
        
        [self updateUIForEditState];
    }
}

- (void)setEditState:(PLVStickerTextEditState)editState {
    if (_editState == editState) {
        return; // 状态未改变，直接返回
    }
    
    _editState = editState;
    
    [self updateUIForEditState];
    
    // 通知代理状态改变
    if (self.delegate && [self.delegate respondsToSelector:@selector(plv_StickerTextView:didChangeEditState:)]) {
        [self.delegate plv_StickerTextView:self didChangeEditState:editState];
    }
}

#pragma mark - State Management

- (void)updateUIForEditState {
    switch (self.editState) {
        case PLVStickerTextEditStateNormal:
            self.enabledBorder = NO;
            self.enablePanGesture = NO;
            self.deleteButton.hidden = YES;
            self.editButton.hidden = YES;
            break;
            
        case PLVStickerTextEditStateSelected:
            self.enabledBorder = YES;
            self.enablePanGesture = YES;
            self.deleteButton.hidden = YES;
            self.editButton.hidden = YES;
            break;
            
        case PLVStickerTextEditStateActionVisible:
            self.enabledBorder = YES;
            self.enablePanGesture = YES;
            self.deleteButton.hidden = NO;
            self.editButton.hidden = NO;
            break;
            
        case PLVStickerTextEditStateTextEditing:
            // 保持状态2的UI，等待编辑框弹出
            self.enabledBorder = YES;
            self.enablePanGesture = YES;
            self.deleteButton.hidden = NO;
            self.editButton.hidden = NO;
            break;
    }
}

#pragma mark - Public Methods

- (void)performTapOperation {
    [self handleTapContentView];
}

- (void)updateText:(NSString *)text {
    self.textModel.editText = text;
    [self.effectText updateText:text];
    
    self.textUpdated = YES;
    [self updateBoundWidth];
}

- (void)updateTextMode:(PLVStickerTextModel *)textModel{
    // 切换模板时始终更新样式和文本，使用新模板的默认文案
    self.textModel.editTemplateType = textModel.editTemplateType;
    self.textModel.editText = textModel.editText;
        
    [self.effectText updateText:self.textModel.editText templateType:self.textModel.editTemplateType];
    [self updateBoundWidth];
}

- (void)updateBoundWidth{
    CGFloat width = [self.effectText getBoundWidthForText];
    CGRect bounds = CGRectMake(0, 0, width, self.bounds.size.height);
    self.bounds = bounds;
    
    [self updateBorderPath];
}

- (void)executeDone{
    self.isNewlyAdded = NO;
    
    self.textModel.text = self.textModel.editText;
    self.textModel.templateType = self.textModel.editTemplateType;
    
    [self.effectText updateText:self.textModel.text templateType:self.textModel.templateType];
}

- (void)executeCancel{
    self.textModel.editText = self.textModel.text;
    self.textModel.editTemplateType = self.textModel.templateType;
    
    [self.effectText updateText:self.textModel.text templateType:self.textModel.templateType];
}

- (void)resetToNormalState {
    self.editState = PLVStickerTextEditStateNormal;
}

- (void)triggerEditStateChange {
    
    switch (self.editState) {
        case PLVStickerTextEditStateNormal:
            // 第一次点击：进入选中状态（显示边框）
            self.editState = PLVStickerTextEditStateSelected;
            break;

        case PLVStickerTextEditStateSelected:
            // 选中状态下点击：进入actionshow状态
            self.editState = PLVStickerTextEditStateActionVisible;
            break;

        case PLVStickerTextEditStateActionVisible:
            // ActionVisible 状态下点击文字区域：进入文本编辑
            self.editState = PLVStickerTextEditStateTextEditing;
            [self startTextEditing];
            break;

        case PLVStickerTextEditStateTextEditing:
            // 编辑状态下不处理点击
            break;
    }
}

- (void)startTextEditing {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plv_StickerTextViewDidBeginEditing:)]) {
        [self.delegate plv_StickerTextViewDidBeginEditing:self];
    }
}

- (void)endTextEditing {
    self.editState = PLVStickerTextEditStateActionVisible; // 编辑完成后回到状态2
    if (self.delegate && [self.delegate respondsToSelector:@selector(plv_StickerTextViewDidEndEditing:)]) {
        [self.delegate plv_StickerTextViewDidEndEditing:self];
    }
}

#pragma mark - Button Handlers

- (void)handleDeleteButtonTap {
    // 隐藏贴纸元素而不是直接删除
    self.hidden = YES;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(plv_StickerTextViewDidTapDeleteButton:)]) {
        [self.delegate plv_StickerTextViewDidTapDeleteButton:self];
    }
}

- (void)handleEditButtonTap {
    // 点击编辑按钮直接进入文本编辑状态
    self.editState = PLVStickerTextEditStateTextEditing;
    [self startTextEditing];
}

#pragma mark - Private Methods

- (void)updateBorderPath {
    if (self.enabledBorder){
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.bounds];
        self.shapeLayer.path = path.CGPath;
    }
}

- (void)updateMoveableRect {
    if (!self.superview) {
        return;
    }
    
    CGRect superviewBounds = self.superview.bounds;
    _moveableRect = UIEdgeInsetsInsetRect(superviewBounds, _moveEdgeInserts);
}

- (CGPoint)limitPointInBounds:(CGPoint)point {
    CGFloat x = point.x;
    CGFloat y = point.y;
    
    // 限制X坐标
    if (x < _moveableRect.origin.x) {
        x = _moveableRect.origin.x;
    } else if (x + self.frame.size.width > _moveableRect.origin.x + _moveableRect.size.width) {
        x = _moveableRect.origin.x + _moveableRect.size.width - self.frame.size.width;
    }
    
    // 限制Y坐标
    if (y < _moveableRect.origin.y) {
        y = _moveableRect.origin.y;
    } else if (y + self.frame.size.height > _moveableRect.origin.y + _moveableRect.size.height) {
        y = _moveableRect.origin.y + _moveableRect.size.height - self.frame.size.height;
    }
    
    return CGPointMake(x, y);
}

#pragma mark - Gesture Handlers

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if (!self.delegate) {
        return;
    }
    
    // 单击处理
    if (gesture.numberOfTapsRequired == 1) {
        [self handleTapContentView];
    } 
    // 双击处理
    else if (gesture.numberOfTapsRequired == 2) {
        [self handleDoubleTap];
    }
}

- (void)handleTapContentView {
    [self.superview bringSubviewToFront:self];
    
    // 使用新的状态管理系统
    [self triggerEditStateChange];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(plv_StickerTextViewDidTapContentView:)]) {
        [self.delegate plv_StickerTextViewDidTapContentView:self];
    }
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
   
    if (self.delegate && [self.delegate respondsToSelector:@selector(plv_StickerTextViewHandleMove:point:gestureEnded:)]) {
        [self.delegate plv_StickerTextViewHandleMove:self point:touchPoint gestureEnded:isEnded];
    }
}


- (void)handleDoubleTap {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plv_StickerTextViewDidBeginEditing:)]) {
        [self.delegate plv_StickerTextViewDidBeginEditing:self];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // 允许同时识别多个手势
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        return NO;
    }
    return YES;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if ([super pointInside:point withEvent:event]) {
        return YES;
    }
    
    return (!self.deleteButton.hidden && CGRectContainsPoint(self.deleteButton.frame, point))
    || (!self.editButton.hidden && CGRectContainsPoint(self.editButton.frame, point));
}

@end 
