//
//  PLVLCDocumentPaintModeView.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2022/12/12.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCDocumentPaintModeView.h"
#import "PLVLCUtils.h"
#import "PLVLCBrushToolBarView.h"
#import "PLVLCDocumentInputView.h"
#import "PLVLCBrushToolSelectSheet.h"
#import "PLVLCBrushColorSelectSheet.h"
#import "PLVDocumentView.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCDocumentPaintModeView()
<PLVLCBrushToolBarViewDelegate,
PLVLCBrushToolSelectSheetDelegate,
PLVLCBrushColorSelectSheetDelegate>

#pragma mark UI
@property (nonatomic, strong) UIButton *exitPaintModeButton;
@property (nonatomic, strong) UIView *contentBackgroudView; // 内容背景视图 (负责承载 PPT画面)
@property (nonatomic, strong) PLVLCBrushToolBarView *brushToolBarView; // 画笔工具视图
@property (nonatomic, strong) PLVLCDocumentInputView *inputView; // 文字输入视图
@property (nonatomic, strong) PLVLCBrushToolSelectSheet *brushToolSelectSheet; // 画笔工具选择弹层
@property (nonatomic, strong) PLVLCBrushColorSelectSheet *brushColorSelectSheet; // 画笔颜色选择弹层
@property (nonatomic, weak) PLVDocumentView *pptView;                 // PPT 功能模块

#pragma mark 数据
@property (nonatomic, assign) BOOL hadSetupDefaultConfig; //是否已设置默认配置

@end

@implementation PLVLCDocumentPaintModeView

#pragma mark - [ Life Period ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hadSetupDefaultConfig = NO;
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat rightPadding = 30;
    CGSize selfSize = self.bounds.size; // self的frame已经考虑了安全距离，所以子类不需要理会安全距离问题
    CGFloat sheetMaxWidth = selfSize.width - rightPadding; // 各个弹层最大宽度
    self.contentBackgroudView.frame = CGRectMake(0, 0, selfSize.width, selfSize.height);
    self.exitPaintModeButton.frame = CGRectMake(30, 16, 128, 40);
    
    // 画笔工具视图，内部自适应，(宽度：动态按钮宽度+ 右边间距，高度固定36)
    _brushToolBarView.screenSafeWidth = selfSize.width;
    
    // 画笔工具选择弹层，总共7(讲师、组长)、6(学生)种工具，每个工具固定大小为36*44,间距8*数量 + 左右间距4
    CGFloat brushToolCount = 6;
    CGSize brushToolSelectViewSize = CGSizeMake( 4 * 2 + 36 * brushToolCount + 8 * (brushToolCount - 1), 44);
    CGFloat brushToolSelectViewX = sheetMaxWidth - brushToolSelectViewSize.width;
    CGFloat brushToolSelectViewY = CGRectGetMinY(_brushToolBarView.frame) - brushToolSelectViewSize.height - 14; // 与画笔工具视图间距14，显示在其上面
    _brushToolSelectSheet.frame = CGRectMake(brushToolSelectViewX, brushToolSelectViewY, brushToolSelectViewSize.width, brushToolSelectViewSize.height);
    
    // 画笔颜色选择弹层，总共6种颜色，左间距4 + 每个颜色固定大小为36*44 + 间距8*5 + 右间距4
    CGSize brushColorSelectViewSize = CGSizeMake(4 + 36 * 6 + 8 * 5 + 4, 44);
    CGFloat brushColorSelectViewX = sheetMaxWidth - brushColorSelectViewSize.width;
    CGFloat brushColorSelectViewY = CGRectGetMinY(_brushToolBarView.frame) - brushColorSelectViewSize.height - 14; // 与画笔工具视图间距14，显示在其上面
    _brushColorSelectSheet.frame = CGRectMake(brushColorSelectViewX, brushColorSelectViewY, brushColorSelectViewSize.width, brushColorSelectViewSize.height);
}

#pragma mark - [ Public Methods ]

/// 进入画笔模式
/// @param pptView  白板视图
- (void)enterPaintModeWithPPTView:(UIView *)pptView {
    self.hidden = NO;
    self.pptView = [self isPptView:pptView] ? (PLVDocumentView *)pptView : nil;
    [PLVLCUtils showHUDWithTitle:@"已进入画笔模式" detail:@"" view:self];
    [self displayExternalView:self.pptView];
    // 延迟设置画笔绘制状态 避免 ppt 视图尺寸异常
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        [self.pptView setDocumentUserInteractionEnabled:YES];
        [self.pptView setPaintStatus:YES];
        if(!self.hadSetupDefaultConfig) {
            self.hadSetupDefaultConfig = YES;
            [self.brushToolSelectSheet updateBrushToolApplianceType:PLVLCBrushToolTypeFreeLine];
            [self.brushColorSelectSheet updateSelectColor:@"#5B9EFF" localTrigger:YES];
        }
    });
}

/// 退出画笔模式
- (void)exitPaintMode {
    [self exitPaintModeButtonAction];
}

#pragma mark - [ Private Methods ]

- (void)setupUI{
    self.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.contentBackgroudView];
    [self addSubview:self.exitPaintModeButton];
    [self addSubview:self.brushToolBarView];
}

- (void)removeSubviewOfView:(UIView *)superview{
    for (UIView * subview in superview.subviews) { [subview removeFromSuperview]; }
}

- (BOOL)isPptView:(UIView *)view {
    if (view &&
        [view isKindOfClass:[PLVDocumentView class]]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)displayExternalView:(UIView *)externalView{
    if (externalView && [externalView isKindOfClass:UIView.class]) {
        [self removeSubviewOfView:self.contentBackgroudView];
        [self.contentBackgroudView addSubview:externalView];
        externalView.frame = self.contentBackgroudView.bounds;
        externalView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }else{
        NSLog(@"PLVLCDocumentPaintModeView - displayExternalView failed, externalView:%@", externalView);
    }
}

#pragma mark native -> js（内部使用）
- (void)dealClearEvent {
    __weak typeof(self) weakSelf = self;
    [PLVFdUtil showAlertWithTitle:@"提示" message:@"清屏后画笔痕迹将无法恢复，确认清屏吗？" viewController:[PLVFdUtil getCurrentViewController] cancelActionTitle:@"取消" cancelActionStyle:UIAlertActionStyleDefault cancelActionBlock:nil confirmActionTitle:@"确认" confirmActionStyle:UIAlertActionStyleDestructive confirmActionBlock:^(UIAlertAction * _Nonnull action) {
        [weakSelf.pptView deleteAllPaint];
    }];
}

- (void)updateSelectToolType:(PLVLCBrushToolType)toolType {
    switch (toolType) {
        case PLVLCBrushToolTypeFreeLine:
            [self.pptView setDrawType:PLVWebViewBrushPenTypeFreePen];
            break;
        case PLVLCBrushToolTypeArrow:
            [self.pptView setDrawType:PLVWebViewBrushPenTypeArrow];
            break;
        case PLVLCBrushToolTypeText:
            [self.pptView setDrawType:PLVWebViewBrushPenTypeText];
            break;
        case PLVLCBrushToolTypeRect:
            [self.pptView setDrawType:PLVWebViewBrushPenTypeRect];
            break;
        case PLVLCBrushToolTypeEraser:
            [self.pptView toDelete]; // 设置为橡皮擦
            break;
        case PLVLCBrushToolTypeClear:
            [self dealClearEvent];
            break;
        default:
            PLV_LOG_ERROR(PLVConsoleLogModuleTypePPT, @"%s 使用未定义画笔类型【toolType:%zd】", __FUNCTION__ , toolType);
            break;
    }
}

- (void)updateSelectColor:(NSString *)color {
    if ([PLVFdUtil checkStringUseable:color]) {
        [self.pptView changeColor:color];
    }
}

- (void)doUndo {
    [self.pptView doUndo];
}

#pragma mark Getter
- (UIView *)contentBackgroudView{
    if (!_contentBackgroudView) {
        _contentBackgroudView = [[UIView alloc]init];
    }
    return _contentBackgroudView;
}

- (UIButton *)exitPaintModeButton {
    if (!_exitPaintModeButton) {
        _exitPaintModeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _exitPaintModeButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#000000" alpha:0.6];
        _exitPaintModeButton.layer.cornerRadius = 4.0f;
        _exitPaintModeButton.titleLabel.font =  [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        [_exitPaintModeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_exitPaintModeButton setTitle:@"退出画笔模式" forState:UIControlStateNormal];
        [_exitPaintModeButton setImage:[PLVLCUtils imageForMediaResource:@"plvlc_media_paint_exit"] forState:UIControlStateNormal];
        [_exitPaintModeButton addTarget:self action:@selector(exitPaintModeButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [_exitPaintModeButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 3)];
        [_exitPaintModeButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 3, 0, 0)];
    }
    return _exitPaintModeButton;
}

- (PLVLCDocumentInputView *)inputView {
    if (_inputView == nil) {
        _inputView = [[PLVLCDocumentInputView alloc] init];
        __weak typeof(self) weakSelf = self;
        _inputView.documentInputCompleteHandler = ^(NSString * _Nullable inputText) {
            [weakSelf.pptView changeTextContent:inputText];
        };
    }
    return _inputView;
}

- (PLVLCBrushToolBarView *)brushToolBarView {
    if (!_brushToolBarView) {
        _brushToolBarView = [[PLVLCBrushToolBarView alloc] init];
        _brushToolBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _brushToolBarView.delegate = self;
    }
    return _brushToolBarView;
}

- (PLVLCBrushToolSelectSheet *)brushToolSelectSheet {
    if (!_brushToolSelectSheet) {
        _brushToolSelectSheet = [[PLVLCBrushToolSelectSheet alloc] init];
        _brushToolSelectSheet.delegate = self;
    }
    return _brushToolSelectSheet;
}

- (PLVLCBrushColorSelectSheet *)brushColorSelectSheet {
    if (!_brushColorSelectSheet) {
        _brushColorSelectSheet = [[PLVLCBrushColorSelectSheet alloc] init];
        _brushColorSelectSheet.delegate = self;
    }
    return _brushColorSelectSheet;
}

#pragma mark - [ Event ]

#pragma mark Action
- (void)exitPaintModeButtonAction {
    self.hidden = YES;
    [self.pptView setPaintStatus:NO];
    [self.pptView setDocumentUserInteractionEnabled:NO];
    [PLVLCUtils showHUDWithTitle:@"已退出画笔模式" detail:@"" view:self.superview];

    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCDocumentPaintModeViewExitPaintMode:)]) {
        [self.delegate plvLCDocumentPaintModeViewExitPaintMode:self];
    }
}

#pragma mark PLVLCBrushToolbarViewDelegate

- (void)brushToolBarViewDidTapRevokeButton:(PLVLCBrushToolBarView *)brushToolBarView {
    [self doUndo];
}

- (void)brushToolBarViewDidTapColorButton:(PLVLCBrushToolBarView *)brushToolBarView {
    if (self.brushColorSelectSheet.superview) {
        [self.brushColorSelectSheet dismiss];
    } else {
        [self.brushToolSelectSheet dismiss];
        [self.brushColorSelectSheet showInView:self];
    }
}

- (void)brushToolBarViewDidTapToolButton:(PLVLCBrushToolBarView *)brushToolBarView {
    if (self.brushToolSelectSheet.superview) {
        [self.brushToolSelectSheet dismiss];
    } else {
        [self.brushColorSelectSheet dismiss];
        [self.brushToolSelectSheet showInView:self];
    }
}

#pragma mark  PLVLCBrushToolSelectSheetDelegate

- (void)brushToolSelectSheet:(PLVLCBrushToolSelectSheet *)brushToolSelectSheet didSelectToolType:(PLVLCBrushToolType)toolType selectImage:(UIImage *)selectImage localTouch:(BOOL)localTouch{
    [self.brushToolBarView updateSelectToolType:toolType selectImage:selectImage];
    if (localTouch) { // 本地点击才需要发送JS事件
        [self updateSelectToolType:toolType];
    }
}

#pragma mark  PLVLCBrushColorSelectSheetDelegate

- (void)brushColorSelectSheet:(PLVLCBrushColorSelectSheet *)brushColorSelectSheet didSelectColor:(NSString *)color localTouch:(BOOL)localTouch{
    [self.brushToolBarView updateSelectColor:color];
    if (localTouch) { // 本地点击才需要发送JS事件
        [self updateSelectColor:color];
    }
}

@end
