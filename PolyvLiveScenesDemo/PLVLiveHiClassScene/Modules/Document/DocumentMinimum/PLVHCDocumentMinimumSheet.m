//
//  PLVHCDocumentMinimumSheet.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCDocumentMinimumSheet.h"

// 工具
#import "PLVHCUtils.h"

// UI
#import "PLVHCDocumentMinimumBar.h"
#import "PLVHCDocumentMinimumListView.h"
#import "PLVHCDocumentMinimumGuiedView.h"
#import "PLVHCDocumentMinimumCell.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

typedef NS_ENUM(NSInteger, PLVHCDocumentMinimumSheetStatus) {
    PLVHCDocumentMinimumSheetStatusOnlyBar,
    PLVHCDocumentMinimumSheetStatusShowGuiedView,
    PLVHCDocumentMinimumSheetStatusShowListView
};

@interface PLVHCDocumentMinimumSheet()<
PLVHCDocumentMinimumBarDelegate, // 文档最小化按钮回调
PLVHCDocumentMinimumListViewDelegate // 文档最小化列表视图回调
>

#pragma mark UI
/// view hierarchy
///
/// (PLVHCDocumentMinimumSheet) self
///    ├─ (UIView) tapGestureView
///    ├─ (PLVHCDocumentMinimumBar) documentMinimumBar
///    ├─ (PLVHCDocumentMinimumListView) documentMinimumListView(动态显示)
///    ├─ (PLVHCDocumentMinimumGuiedView) guiedView(动态显示)
///

@property (nonatomic, strong) UIView *tapGestureView; // 手势视图
@property (nonatomic, strong) PLVHCDocumentMinimumBar *documentMinimumBar; // 文档最小化悬浮按钮
@property (nonatomic, strong) PLVHCDocumentMinimumListView *documentMinimumListView; // 文档最小化列表
@property (nonatomic, strong) PLVHCDocumentMinimumGuiedView *guiedView;

#pragma mark 数据

@property (nonatomic, assign) PLVHCDocumentMinimumSheetStatus sheetStatus; // 当前显示状态
@property (nonatomic, assign) BOOL showGuied; // 是否已显示新手引导
@property (nonatomic, assign) NSInteger minimumNum; // 最小化数量
@property (nonatomic, assign) NSInteger containerTotal; // 容器文档总数（最小化的文档 + 已显示在画板的文档）

@end

@implementation PLVHCDocumentMinimumSheet

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.tapGestureView];
        [self addSubview:self.documentMinimumBar];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIEdgeInsets edgeInsets = [PLVHCUtils sharedUtils].areaInsets;
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    CGFloat marginX = 8;
    CGFloat marginY = 3;
    CGFloat marginBootom = 20;
    CGFloat marginLeft = MAX(edgeInsets.left, 36);
    
    CGFloat barWidth = 36;
    CGSize guiedViewSize = CGSizeMake(185, 42);
    CGFloat listViewWidth = 330;
    
    CGRect selfRect = CGRectZero;
    CGRect barRect = CGRectZero;
    CGRect listViewRect = CGRectZero;
    CGRect guiedViewRect = CGRectZero;
    
    switch (self.sheetStatus) {
        case PLVHCDocumentMinimumSheetStatusOnlyBar: {
            selfRect = CGRectMake(marginLeft, screenSize.height - edgeInsets.bottom - marginBootom - barWidth, barWidth, barWidth);
            barRect = CGRectMake(0, 0, barWidth, barWidth);
        } break;
            
        case PLVHCDocumentMinimumSheetStatusShowGuiedView: {
            selfRect = CGRectMake(marginLeft, screenSize.height - edgeInsets.bottom - marginBootom - barWidth, barWidth + guiedViewSize.width,  MAX(guiedViewSize.height, barWidth));
            barRect = CGRectMake(0, 0, barWidth, barWidth);
            guiedViewRect = CGRectMake(barWidth + marginX, -marginY, guiedViewSize.width, guiedViewSize.height);
        } break;
            
        case PLVHCDocumentMinimumSheetStatusShowListView: {
            CGFloat tableViewHeight = MIN(self.minimumNum, 5) * [PLVHCDocumentMinimumCell cellHeight] + 14;
            selfRect = self.superview.bounds;
            barRect = CGRectMake(marginLeft, screenSize.height - edgeInsets.bottom - marginBootom - barWidth, barWidth, barWidth);
            listViewRect =  CGRectMake(CGRectGetMaxX(barRect) + marginX, selfRect.size.height - edgeInsets.bottom - marginBootom - tableViewHeight, listViewWidth, tableViewHeight);
        } break;
    }
    
    self.frame = selfRect;
    self.tapGestureView.frame = self.bounds;
    self.documentMinimumBar.frame = barRect;
    _documentMinimumListView.frame = listViewRect;
    _guiedView.frame = guiedViewRect;
    
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

- (void)refreshMinimizeContainerDataArray:(NSArray<PLVHCDocumentMinimumModel *> *)dataArray {
    if (dataArray &&
        dataArray.count >0) {
        self.minimumNum = dataArray.count;
        [self.documentMinimumListView refreshMinimizeContainerDataArray:dataArray];
        [self.documentMinimumBar refreshPptContainerTotal:dataArray.count];
        
        // 显示新手引导
        if (!self.showGuied) {
            self.sheetStatus = PLVHCDocumentMinimumSheetStatusShowGuiedView;
            self.showGuied = YES;
            [self showGuiedView];
            [self showMinimumListView:NO];
        } else if (_documentMinimumListView.superview) {
            [self setNeedsLayout];
        }
        
    } else {
        self.sheetStatus = PLVHCDocumentMinimumSheetStatusOnlyBar;
        [self dismissGuiedView];
        [self showMinimumListView:NO];
    }
}

- (void)refreshPptContainerTotal:(NSInteger)total {
    self.containerTotal = total;
    if (total <= 0) {
        [self dismiss];
    }
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (UIView *)tapGestureView {
    if (!_tapGestureView) {
        _tapGestureView = [[UIView alloc] init];
        _tapGestureView.backgroundColor = [UIColor clearColor];
        
        _tapGestureView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureViewGesture)];
        [_tapGestureView addGestureRecognizer:tap];
    }
    return _tapGestureView;
}

- (PLVHCDocumentMinimumBar *)documentMinimumBar {
    if(!_documentMinimumBar) {
        _documentMinimumBar = [[PLVHCDocumentMinimumBar alloc] init];
        _documentMinimumBar.delegate = self;
    }
    return _documentMinimumBar;
}

- (PLVHCDocumentMinimumListView *)documentMinimumListView {
    if (!_documentMinimumListView) {
        _documentMinimumListView = [[PLVHCDocumentMinimumListView alloc] init];
        _documentMinimumListView.delegate = self;
    }
    return _documentMinimumListView;
}

- (PLVHCDocumentMinimumGuiedView *)guiedView {
    if (!_guiedView) {
        _guiedView = [[PLVHCDocumentMinimumGuiedView alloc] init];
    }
    return _guiedView;
}

- (BOOL)isMaxMinimumNum {
    return self.containerTotal >= 5;
}

#pragma mark show & dismiss View
- (void)showGuiedView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissGuiedView) object:nil];
    [self performSelector:@selector(dismissGuiedView) withObject:nil afterDelay:3];
    
    [self.guiedView showInView:self];
}

- (void)dismissGuiedView{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissGuiedView) object:nil];
    
    if (!_guiedView) {
        return;
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.sheetStatus = PLVHCDocumentMinimumSheetStatusOnlyBar;
        [self.guiedView dismiss];
    }];
}

/// 显示、隐藏最小化文档列表
/// @param show YES: 显示、NO: 隐藏
- (void)showMinimumListView:(BOOL)show {
    if (show) {
        [self.documentMinimumListView showInView:self];
    } else {
        if (_documentMinimumListView) {
            [self.documentMinimumListView dismiss];
        }
    }
}

/// 刷新最小化数量已经更新documentMinimumBar layout
/// @param minimumNum 最小化数量
- (void)refreshMinimumNumAndUpdateLayout:(NSInteger) minimumNum{
    if (minimumNum <= 0) {
        [self dismiss];
        return;
    }
    self.minimumNum = minimumNum;
    [self.documentMinimumBar refreshPptContainerTotal:minimumNum];
    [self setNeedsLayout];
}

#pragma mark - [ Event ]
#pragma mark Gesture

- (void)tapGestureViewGesture {
    self.sheetStatus = PLVHCDocumentMinimumSheetStatusOnlyBar;
    [self showMinimumListView:NO];
}


#pragma mark - [ Delegate ]

#pragma mark PLVHCDocumentMinimumBarDelegate

- (void)documentMinimumBarDidTap:(PLVHCDocumentMinimumBar *)documentMinimumBar {
    if (_documentMinimumListView.superview) {
        self.sheetStatus = PLVHCDocumentMinimumSheetStatusOnlyBar;
        [self showMinimumListView:NO];
    } else {
        [self dismissGuiedView];
        self.sheetStatus = PLVHCDocumentMinimumSheetStatusShowListView;
        [self showMinimumListView:YES];
    }
}

#pragma mark PLVHCDocumentMinimumListViewDelegate

- (void)documentMinimumListView:(PLVHCDocumentMinimumListView *)documentMinimumListView didSelectItemModel:(PLVHCDocumentMinimumModel *)model {
    [self refreshMinimumNumAndUpdateLayout:documentMinimumListView.minimumNum];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentMinimumSheet:didSelectItemModel:)]) {
        [self.delegate documentMinimumSheet:self didSelectItemModel:model];
    }
}

- (void)documentMinimumListView:(PLVHCDocumentMinimumListView *)documentMinimumListView didCloseItemModel:(PLVHCDocumentMinimumModel *)model {
    [self refreshMinimumNumAndUpdateLayout:documentMinimumListView.minimumNum];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentMinimumSheet:didCloseItemModel:)]) {
        [self.delegate documentMinimumSheet:self didCloseItemModel:model];
    }
}

@end

