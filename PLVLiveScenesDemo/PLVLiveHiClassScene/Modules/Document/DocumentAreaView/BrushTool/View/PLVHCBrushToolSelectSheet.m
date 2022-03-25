//
//  PLVHCBrushToolSelectSheet.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/20.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCBrushToolSelectSheet.h"

// 工具
#import "PLVHCUtils.h"

// 模块
#import "PLVRoomDataManager.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCBrushToolSelectSheet()

@property (nonatomic, strong) UIButton *moveButton; // 移动工具，讲师才有此工具
@property (nonatomic, strong) UIButton *choiceButton;  // 选择工具
@property (nonatomic, strong) UIButton *freeLineButton; // 自由线条
@property (nonatomic, strong) UIButton *arrowButton; // 箭头
@property (nonatomic, strong) UIButton *textButton; // 文字
@property (nonatomic, strong) UIButton *eraserButton; // 橡皮擦
@property (nonatomic, strong) UIButton *clearButton; // 清除画面

#pragma mark 数据
/// 是否显示移动工具 (讲师或组长比学生多了一个移动工具，在layoutSubviews中控制显示、隐藏)
@property (nonatomic, assign) BOOL showMoveTool;

@end

@implementation PLVHCBrushToolSelectSheet

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
    CGFloat toolWidth = 36;
    CGFloat toolItemY = 4;
    CGFloat toolItemX = toolItemY;
    CGFloat margin = 8;
    CGFloat subViewsCount = self.showMoveTool ? 7 : 6;;
    CGFloat subViwesWidth = (toolWidth * subViewsCount + (margin * (subViewsCount - 1)));
    
    // 小屏适配
    if (selfSize.width < subViwesWidth) {
        margin = 4;
        toolWidth = (selfSize.width - margin * (subViewsCount - 1) ) / subViewsCount;
        toolItemY = (selfSize.height - toolWidth) / 2;
    }
    
    if (self.showMoveTool) { // 讲师、组长才有移动工具
        self.moveButton.frame = CGRectMake(toolItemX, toolItemY, toolWidth, toolWidth);
        self.choiceButton.frame = CGRectMake(CGRectGetMaxX(self.moveButton.frame) + margin, toolItemY, toolWidth, toolWidth);
    } else {
        self.moveButton.frame = CGRectZero;
        self.choiceButton.frame = CGRectMake(toolItemX, toolItemY, toolWidth, toolWidth);
    }
    
    self.freeLineButton.frame = CGRectMake(CGRectGetMaxX(self.choiceButton.frame) + margin, toolItemY, toolWidth, toolWidth);
    self.arrowButton.frame = CGRectMake(CGRectGetMaxX(self.freeLineButton.frame) + margin, toolItemY, toolWidth, toolWidth);
    self.textButton.frame = CGRectMake(CGRectGetMaxX(self.arrowButton.frame) + margin, toolItemY, toolWidth, toolWidth);
    self.eraserButton.frame = CGRectMake(CGRectGetMaxX(self.textButton.frame) + margin, toolItemY, toolWidth, toolWidth);
    self.clearButton.frame = CGRectMake(CGRectGetMaxX(self.eraserButton.frame) + margin, toolItemY, toolWidth, toolWidth);
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

- (void)updateBrushToolApplianceType:(PLVContainerApplianceType)applianceType {
    UIButton *button;
    switch (applianceType) {
        case PLVContainerApplianceTypeFreeLine:
            button = self.freeLineButton;
            break;
        case PLVContainerApplianceTypeArrow:
            button = self.arrowButton;
            break;
        case PLVContainerApplianceTypeChoice:
            button = self.choiceButton;
            break;
        case PLVContainerApplianceTypeEraser:
            button =  self.eraserButton;
            break;
        case PLVContainerApplianceTypeText:
            button = self.textButton;
            break;
        case PLVContainerApplianceTypeMove:
            button = self.moveButton;
            break;
        default:
            break;
    }
    [self buttonAction:button localTouch:NO];
}

- (void)updateLayout {
    plv_dispatch_main_async_safe(^{
        [self setNeedsLayout];
        [self layoutIfNeeded];
    })
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (BOOL)showMoveTool {
    return [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher ||
    [PLVHiClassManager sharedManager].currentUserIsGroupLeader; // 讲师、组长才有移动工具
}

#pragma mark setupUI

- (void)setupUI {
    self.moveButton = [self createToolButton:@"plvhc_brush_btn_move_normal" imgNameSelected:@"plvhc_brush_btn_move_selected"];
    self.moveButton.tag = PLVHCBrushToolTypeMove;
    self.moveButton.selected = YES;
    
    self.choiceButton = [self createToolButton:@"plvhc_brush_btn_choice_normal" imgNameSelected:@"plvhc_brush_btn_choice_selected"];
    self.choiceButton.tag = PLVHCBrushToolTypeChoice;
    
    self.freeLineButton = [self createToolButton:@"plvhc_brush_btn_freeline_normal" imgNameSelected:@"plvhc_brush_btn_freeline_selected"];
    self.freeLineButton.tag = PLVHCBrushToolTypeFreeLine;
    
    self.arrowButton = [self createToolButton:@"plvhc_brush_btn_arrow_normal" imgNameSelected:@"plvhc_brush_btn_arrow_selected"];
    self.arrowButton.tag = PLVHCBrushToolTypeArrow;
    
    self.textButton = [self createToolButton:@"plvhc_brush_btn_text_normal" imgNameSelected:@"plvhc_brush_btn_text_selected"];
    self.textButton.tag = PLVHCBrushToolTypeText;
    
    self.eraserButton = [self createToolButton:@"plvhc_brush_btn_eraser_normal" imgNameSelected:@"plvhc_brush_btn_eraser_selected"];
    self.eraserButton.tag = PLVHCBrushToolTypeEraser;
    
    self.clearButton = [self createToolButton:@"plvhc_brush_btn_clear"
                              imgNameSelected:@"plvhc_brush_btn_clear"];
    self.clearButton.tag = PLVHCBrushToolTypeClear;
    
    [self addSubview:self.moveButton];
    [self addSubview:self.choiceButton];
    [self addSubview:self.freeLineButton];
    [self addSubview:self.arrowButton];
    [self addSubview:self.textButton];
    [self addSubview:self.eraserButton];
    [self addSubview:self.clearButton];
}

#pragma mark 创建按钮

- (UIButton *)createToolButton:(NSString *)imgNameNormal imgNameSelected:(NSString *)imgNameSelected {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[self getImageWithName:imgNameNormal] forState:UIControlStateNormal];
    [button setImage:[self getImageWithName:imgNameSelected] forState:UIControlStateSelected];
    
    if ([PLVFdUtil checkStringUseable:imgNameSelected]) {
        [button setImage:[self getImageWithName:imgNameSelected] forState:UIControlStateDisabled];
    }
    
    [button addTarget:self action:@selector(toolButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

// 加载图片
- (UIImage *)getImageWithName:(NSString *)name {
    if (![PLVFdUtil checkStringUseable:name]) {
        return nil;
    }
    return [PLVHCUtils imageForDocumentResource:name];
}


- (void)changeStatusWithClickButton:(UIButton *)button {
    if (button.tag == PLVHCBrushToolTypeClear) {
        return;
    }
    
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton *)view;
            btn.selected = NO;
        }
    }
    
    UIImage *img = [button imageForState:UIControlStateSelected];
    if (button.selected) {
        img = [button imageForState:UIControlStateSelected];
    }
    [button setImage:img forState:UIControlStateSelected];
    button.selected = YES;
}

- (void)buttonAction:(UIButton *)button localTouch:(BOOL)localTouch {
    PLVHCBrushToolType type = (PLVHCBrushToolType)button.tag;
    if (type == PLVHCBrushToolTypeUnknown) {
        return;
    }
    
    if (!self.showMoveTool &&
        type == PLVHCBrushToolTypeMove) {
        return;
    }
    
    [self changeStatusWithClickButton:button];
    
    UIImage *image = [button imageForState:UIControlStateNormal];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(brushToolSelectSheet:didSelectToolType:selectImage:localTouch:)]) {
        [self.delegate brushToolSelectSheet:self didSelectToolType:type selectImage:image localTouch:localTouch];
    }
    [self dismiss];
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)toolButtonAction:(UIButton *)button {
    [self buttonAction:button localTouch:YES];
}

@end
