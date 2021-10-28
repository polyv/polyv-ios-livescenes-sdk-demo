//
//  PLVHCBrushToolBarView.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/7/20.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCBrushToolBarView.h"

// UI
#import "PLVHCBrushToolButton.h"
#import "PLVHCBrushColorButton.h"

// 工具
#import "PLVHCUtils.h"

// 模块
#import "PLVRoomDataManager.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCBrushToolBarView()

#pragma mark UI
/// view hierarchy
///
/// (PLVHCBrushToolBarView) self
///    ├─ (UIButton) revokeButton
///    ├─ (PLVHCBrushToolButton) toolButton
///    ├─ (PLVHCBrushToolButton) colorButton(动态显示)
///    └─ (UIButton) deleteButton(动态显示)
///

@property (nonatomic, strong) UIButton *revokeButton; // 撤回按钮，常驻
@property (nonatomic, strong) PLVHCBrushToolButton *toolButton; // 工具按钮，常驻
@property (nonatomic, strong) PLVHCBrushColorButton *colorButton; // 颜色按钮，动态显示
@property (nonatomic, strong) UIButton *deleteButton; // 删除按钮，动态显示

#pragma mark 数据
 
@property (nonatomic, assign) PLVHCBrushToolType currentBrushToolType; // 当前画笔工具类型
@property (nonatomic, copy) NSString *currentColor; // 当前颜色值
@property (nonatomic, assign) BOOL showColorButton; // 是否显示颜色按钮
@property (nonatomic, assign) BOOL showDeleteButton; // 是否显示删除按钮

@end

@implementation PLVHCBrushToolBarView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        // 设置画笔初始权限
        self.haveBrushPermission = ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher);
      
        [self addSubview:self.revokeButton];
        [self addSubview:self.toolButton];
        [self addSubview:self.colorButton];
        [self addSubview:self.deleteButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIEdgeInsets areaInsets = [PLVHCUtils sharedUtils].areaInsets;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    CGFloat buttonWidth = 36;
    CGFloat middleWidth = 0;
    CGFloat padding = 14;
    CGFloat colorButtonWidth = self.showColorButton ? buttonWidth : 0;
    CGFloat deleteButtonWidth = self.showDeleteButton ? buttonWidth : 0;
    CGFloat width;
    
    // 计算画笔工具宽度
    middleWidth = (self.showDeleteButton * padding + colorButtonWidth)  + (self.showColorButton * padding) + deleteButtonWidth;
    width = buttonWidth * 2 + middleWidth + padding;
    
    CGSize selfSize = CGSizeMake(width, 36);
    CGFloat brushToolX = self.screenSafeWidth - selfSize.width + areaInsets.left;
    CGFloat brushToolY = screenHeight - selfSize.height - areaInsets.bottom - 20;
    self.frame = CGRectMake(brushToolX, brushToolY, selfSize.width, selfSize.height);
    
    self.revokeButton.frame = CGRectMake(0, 0, buttonWidth, buttonWidth);
    middleWidth = CGRectGetMaxX(self.revokeButton.frame);
    
    self.colorButton.frame = CGRectMake(CGRectGetMaxX(self.revokeButton.frame) + padding * self.showColorButton, 0, colorButtonWidth, colorButtonWidth);
    middleWidth = CGRectGetMaxX(self.colorButton.frame);
    
    self.deleteButton.frame = CGRectMake(CGRectGetMaxX(self.colorButton.frame) + padding * self.showDeleteButton, 0, deleteButtonWidth, deleteButtonWidth);
    middleWidth = CGRectGetMaxX(self.deleteButton.frame);
    
    self.toolButton.frame = CGRectMake(middleWidth + padding, 0, buttonWidth, buttonWidth);
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

- (void)updateSelectToolType:(PLVHCBrushToolType)toolType selectImage:(nonnull UIImage *)selectImage{
    if (toolType == PLVHCBrushToolTypeClear) {
        return;
    }
    self.currentBrushToolType = toolType;
    [self.toolButton setImage:selectImage];
}

- (void)updateSelectColor:(NSString *)color {
    if ([PLVFdUtil checkStringUseable:color]) {
        self.currentColor = color;
        self.colorButton.color = [PLVColorUtil colorFromHexString:color];
    }
}

- (void)updateBrushToolStatusWithDict:(NSDictionary *)dict {
    if (!dict ||
        ![dict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    BOOL undoStatus = PLV_SafeBoolForDictKey(dict, @"undoStatus");
    BOOL deleteStatus = PLV_SafeBoolForDictKey(dict, @"deleteStatus");
    self.revokeButton.enabled = undoStatus;
    self.showDeleteButton = deleteStatus;
    
    [self setNeedsLayout];
}

#pragma mark - [ Private Methods ]
#pragma mark Getter

- (UIButton *)revokeButton {
    if (!_revokeButton) {
        _revokeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_revokeButton setImage:[PLVHCUtils imageForDocumentResource:@"plvhc_brush_btn_revoke"] forState:UIControlStateNormal];
        _revokeButton.enabled = NO;
        [_revokeButton addTarget:self action:@selector(revokeButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _revokeButton;
}

- (PLVHCBrushToolButton *)toolButton {
    if (!_toolButton) {
        _toolButton = [[PLVHCBrushToolButton alloc] init];
        [_toolButton setImage:[PLVHCUtils imageForDocumentResource:@"plvhc_brush_btn_move_normal"]];
        __weak typeof(self) weakSelf = self;
        _toolButton.didTapButton = ^{
            [weakSelf toolButtonAction];
        };
    }
    return _toolButton;
}

- (PLVHCBrushColorButton *)colorButton {
    if (!_colorButton) {
        _colorButton = [[PLVHCBrushColorButton alloc] init];
        _colorButton.color = [PLVColorUtil colorFromHexString:@"#FF6363"];
        _colorButton.bgColor = [PLVColorUtil colorFromHexString:@"#242940"];
        [_colorButton addTarget:self action:@selector(colorButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _colorButton;
}

- (UIButton *)deleteButton {
    if (!_deleteButton) {
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deleteButton setImage:[PLVHCUtils imageForDocumentResource:@"plvhc_brush_btn_delete_selected"] forState:UIControlStateNormal];
        [_deleteButton addTarget:self action:@selector(deleteButtonAcion) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteButton;
}

#pragma mark Setter

- (void)setCurrentBrushToolType:(PLVHCBrushToolType)currentBrushToolType {
    _currentBrushToolType = currentBrushToolType;
    BOOL showColorButton = NO;
    BOOL showDeleteButton = NO;
    
    switch (currentBrushToolType) {
        case PLVHCBrushToolTypeFreeLine:
            showColorButton = YES;
            break;
        case PLVHCBrushToolTypeArrow:
            showColorButton = YES;
            break;
        case PLVHCBrushToolTypeText:
            showColorButton = YES;
            break;
        default:
            break;
    }
    
    self.showColorButton = showColorButton;
    self.showDeleteButton = showDeleteButton;
    [self setNeedsLayout];
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)revokeButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(brushToolBarViewDidTapRevokeButton:)]) {
        [self.delegate brushToolBarViewDidTapRevokeButton:self];
    }
}

- (void)toolButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(brushToolBarViewDidTapToolButton:)]) {
        [self.delegate brushToolBarViewDidTapToolButton:self];
    }
}

- (void)colorButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(brushToolBarViewDidTapColorButton:)]) {
        [self.delegate brushToolBarViewDidTapColorButton:self];
    }
}

- (void)deleteButtonAcion {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(brushToolBarViewDidTapDeleteButton:)]) {
        [self.delegate brushToolBarViewDidTapDeleteButton:self];
    }
}

@end
