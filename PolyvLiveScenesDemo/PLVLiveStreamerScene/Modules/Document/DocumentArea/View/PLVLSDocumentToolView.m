//
//  PLVLSDocumentToolView.m
//  PLVLiveScenesDemo
//
//  Created by Hank on 2021/3/1.
//  Copyright © 2021 PLV. All rights reserved.
//  控制条

#import "PLVLSDocumentToolView.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

#import "PLVLSUtils.h"

@interface PLVLSDocumentToolView ()

@property (nonatomic, strong) UIButton *btnBrush;       // 开关
@property (nonatomic, strong) UIButton *btnAddPage;     // 添加PPT
@property (nonatomic, strong) UIButton *btnFullScreen;  // 全屏
@property (nonatomic, strong) UIButton *btnNext;        // 下一页
@property (nonatomic, strong) UIButton *btnPrevious;    // 上一页

@end

@implementation PLVLSDocumentToolView

#pragma mark - [ Life Period ]

- (instancetype)init {
    if (self = [super init]) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat btnWidth = 36;
    CGFloat maginTop = 12;
    
    CGFloat relativeY = UIViewGetHeight(self);
    self.btnBrush.frame = CGRectMake(0, relativeY - btnWidth, btnWidth, btnWidth);
    
    relativeY = self.btnBrush.hidden ? relativeY : (UIViewGetTop(self.btnBrush) - maginTop);
    self.btnAddPage.frame = CGRectMake(0, relativeY - btnWidth, btnWidth, btnWidth);
    
    relativeY = (!self.btnAddPage.hidden && self.btnAddPage.alpha == 1) ? (UIViewGetTop(self.btnAddPage) - maginTop) : relativeY;
    self.btnFullScreen.frame = CGRectMake(0, relativeY - btnWidth, btnWidth, btnWidth);
    
    relativeY = self.btnFullScreen.hidden ? relativeY : (UIViewGetTop(self.btnFullScreen) - maginTop);
    self.btnNext.frame = CGRectMake(0, relativeY - btnWidth, btnWidth, btnWidth);
    self.btnPrevious.frame = CGRectMake(0, UIViewGetTop(self.btnNext) - btnWidth - maginTop, btnWidth, btnWidth);
}

#pragma mark - [ Public Methods ]

- (void)setPageNum:(NSInteger)currNum totalNum:(NSInteger)totalNum {
    self.btnPrevious.alpha = (totalNum <= 1) ? 0 : 1;
    self.btnNext.alpha = (totalNum <= 1) ? 0 : 1;
    
    self.btnPrevious.enabled = currNum > 1;
    self.btnNext.enabled = currNum < totalNum;
}

- (void)setBrushStyle:(BOOL)isWhiteboard {
    NSString *imgName = @"plvls_ppt_btn_doc_open_brush";
    if (isWhiteboard) {
        imgName = @"plvls_ppt_btn_whiteboard_open_brush";
    }
    [self.btnBrush setImage:[self getImageWithName:imgName] forState:UIControlStateNormal];
    
    self.btnAddPage.alpha = (!isWhiteboard) ? 0 : 1;
    
    [self layoutSubviews];
}

- (void)setBrushSelected:(BOOL)isSelected {
    self.btnBrush.selected = isSelected;
}

- (void)setFullScreenButtonSelected:(BOOL)isSelected {
    self.btnFullScreen.selected = isSelected;
}

- (void)showBtnBrush:(BOOL)show{
    self.btnBrush.hidden = !show;
    [self layoutIfNeeded];
}

- (void)showBtnAddPage:(BOOL)show{
    self.btnAddPage.hidden = !show;
    [self layoutIfNeeded];
}

- (void)showBtnFullScreen:(BOOL)show{
    self.btnFullScreen.hidden = !show;
    [self layoutIfNeeded];
}

- (void)showBtnNexth:(BOOL)show{
    self.btnNext.hidden = !show;
    [self layoutIfNeeded];
}

- (void)showBtnPrevious:(BOOL)show{
    self.btnPrevious.hidden = !show;
    [self layoutIfNeeded];
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    [self addSubview:self.btnBrush];
    [self addSubview:self.btnAddPage];
    [self addSubview:self.btnFullScreen];
    [self addSubview:self.btnNext];
    [self addSubview:self.btnPrevious];
}

// 加载图片
- (UIImage *)getImageWithName:(NSString *)name {
    if (! [PLVFdUtil checkStringUseable:name]) {
        return nil;
    }
    return [PLVLSUtils imageForDocumentResource:name];
}

#pragma mark - [ Getter ]

- (UIButton *)btnBrush {
    if (! _btnBrush) {
        _btnBrush = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnBrush setImage:[self getImageWithName:@"plvls_ppt_btn_whiteboard_open_brush"]
                   forState:UIControlStateNormal];
        [_btnBrush setImage:[self getImageWithName:@"plvls_ppt_btn_close_brush"]
                   forState:UIControlStateSelected];
        [_btnBrush addTarget:self action:@selector(brushButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _btnBrush;
}

- (UIButton *)btnAddPage {
    if (! _btnAddPage) {
        _btnAddPage = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnAddPage setImage:[self getImageWithName:@"plvls_ppt_btn_add_whiteboard"]
                     forState:UIControlStateNormal];
        [_btnAddPage addTarget:self action:@selector(addPageButtonAction:)
              forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _btnAddPage;
}

- (UIButton *)btnFullScreen {
    if (! _btnFullScreen) {
        _btnFullScreen = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnFullScreen setImage:[self getImageWithName:@"plvls_ppt_btn_fullscreen"]
                        forState:UIControlStateNormal];
        [_btnFullScreen setImage:[self getImageWithName:@"plvls_ppt_btn_exit_fullscreen"]
                        forState:UIControlStateSelected];
        [_btnFullScreen addTarget:self action:@selector(fullScreenButtonAction:)
                 forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _btnFullScreen;
}

- (UIButton *)btnNext {
    if (! _btnNext) {
        _btnNext = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnNext setImage:[self getImageWithName:@"plvls_ppt_btn_next_normal"]
                  forState:UIControlStateNormal];
        [_btnNext setImage:[self getImageWithName:@"plvls_ppt_btn_next_disabled"]
                  forState:UIControlStateDisabled];
        _btnNext.alpha = 0;
        [_btnNext addTarget:self action:@selector(pageTurnAction:)
           forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _btnNext;
}

- (UIButton *)btnPrevious {
    if (! _btnPrevious) {
        _btnPrevious = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnPrevious setImage:[self getImageWithName:@"plvls_ppt_btn_previous_normal"] forState:UIControlStateNormal];
        [_btnPrevious setImage:[self getImageWithName:@"plvls_ppt_btn_previous_disabled"] forState:UIControlStateDisabled];
        _btnPrevious.alpha = 0;
        [_btnPrevious addTarget:self action:@selector(pageTurnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _btnPrevious;
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)brushButtonAction:(UIButton *)button {
    BOOL result = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(controlToolsView:openBrush:)]) {
        result = [self.delegate controlToolsView:self openBrush:!button.isSelected];
        if (result) {
            button.selected = !button.isSelected;
        }
    }
    if (self.btnBrush.selected) {
        self.hidden = NO;
    }
}

- (void)addPageButtonAction:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(controlToolsViewDidAddPage:)]) {
        [self.delegate controlToolsViewDidAddPage:self];
    }
}

- (void)fullScreenButtonAction:(UIButton *)button{
    button.selected = !button.isSelected;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(controlToolsView:changeFullScreen:)]) {
        [self.delegate controlToolsView:self changeFullScreen:button.isSelected];
    }
}

- (void)pageTurnAction:(UIButton *)button{
    BOOL isNext = button == self.btnNext;
    if (self.delegate && [self.delegate respondsToSelector:@selector(controlToolsView:turnNextPage:)]) {
        [self.delegate controlToolsView:self turnNextPage:isNext];
    }
}

@end
