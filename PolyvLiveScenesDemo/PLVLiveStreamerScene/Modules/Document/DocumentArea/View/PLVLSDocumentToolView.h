//
//  PLVLSDocumentToolView.h
//  PLVLiveScenesDemo
//
//  Created by Hank on 2021/3/1.
//  Copyright © 2021 PLV. All rights reserved.
//  控制条

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLSDocumentToolView;

@protocol PLVLSDocumentToolViewDelegate <NSObject>

///  画笔开关面板回调
///
/// @param controlToolsView 控制条对象
/// @param isOpen YES： 打开画笔，NO： 关闭画笔
/// @result YES 改变样式, NO 不改变样式
- (BOOL)controlToolsView:(PLVLSDocumentToolView *)controlToolsView openBrush:(BOOL)isOpen;

///  添加PPT&白板页
///
/// @param controlToolsView 控制条对象
- (void)controlToolsViewDidAddPage:(PLVLSDocumentToolView *)controlToolsView;

///  全屏按钮回调
///
/// @param controlToolsView 控制条对象
/// @param isFullScreen  YES：全屏，NO：非全屏
- (void)controlToolsView:(PLVLSDocumentToolView *)controlToolsView changeFullScreen:(BOOL)isFullScreen;

///  切换PPT&白板回调
///
/// @param controlToolsView 控制条对象
/// @param isNextPage  YES：下一页，NO：上一页
- (void)controlToolsView:(PLVLSDocumentToolView *)controlToolsView turnNextPage:(BOOL)isNextPage;

/// 交换文档PPT位置到主画面
///
/// @param controlToolsView 控制条对象
/// @param pptToMain 是否改变文档PPT位置到主画面(YES: 文档位于主画面 NO 文档不在主画面)默认为YES
- (void)controlToolsView:(PLVLSDocumentToolView *)controlToolsView changePPTPositionToMain:(BOOL)pptToMain;

///  重置白板缩放比例回调
///
/// @param controlToolsView 控制条对象
- (void)controlToolsViewDidResetZoom:(PLVLSDocumentToolView *)controlToolsView;

@end

@interface PLVLSDocumentToolView : UIView

@property (nonatomic, weak) id<PLVLSDocumentToolViewDelegate> delegate;

/// 设置画笔图片样式
///
/// @param isWhiteboard  YES：白板，NO：文档
- (void)setBrushStyle:(BOOL)isWhiteboard;

/// 设置画笔选中
///
/// @param isSelected  YES：选中，NO：不选中
- (void)setBrushSelected:(BOOL)isSelected;

/// 设置全屏按钮选中
/// @param isSelected YES: 选中，NO：不选中
- (void)setFullScreenButtonSelected:(BOOL)isSelected;

/// 设置交换按钮选中
/// @param isSelected YES: 选中，NO：不选中
- (void)setChangeButtonSelected:(BOOL)isSelected;

/// 更新页码
///
/// @note 该方法主要目的是对 ‘上一页按钮’、‘下一页按钮’ 进行状态刷新；
///       当使用 [showBtnNexth:] 或 [showBtnPrevious:] 方法隐藏对应按钮后，更新页码也无法让对应按钮显示；
///
/// @param currNum 当前页数
/// @param totalNum 总页数
- (void)setPageNum:(NSInteger)currNum totalNum:(NSInteger)totalNum;

/// 显示/隐藏 开关按钮
///
/// @note 默认显示；隐藏后，其他业务逻辑也无法触发显示
///
/// @param show YES:显示，NO:隐藏
- (void)showBtnBrush:(BOOL)show;

/// 显示/隐藏 添加PPT按钮
///
/// @note 默认显示；隐藏后，其他业务逻辑也无法触发显示
///
/// @param show YES:显示，NO:隐藏
- (void)showBtnAddPage:(BOOL)show;

/// 显示/隐藏 全屏按钮
///
/// @note 默认显示；隐藏后，其他业务逻辑也无法触发显示
///
/// @param show YES:显示，NO:隐藏
- (void)showBtnFullScreen:(BOOL)show;

/// 显示/隐藏 下一页按钮
///
/// @note 默认显示；隐藏后，其他业务逻辑也无法触发显示
///
/// @param show YES:显示，NO:隐藏
- (void)showBtnNexth:(BOOL)show;

/// 显示/隐藏 上一页按钮
///
/// @note 默认显示；隐藏后，其他业务逻辑也无法触发显示
///
/// @param show YES:显示，NO:隐藏
- (void)showBtnPrevious:(BOOL)show;

/// 显示/隐藏 重置缩放按钮
///
/// @note 默认隐藏；隐藏后，其他业务逻辑也无法触发显示
///
/// @param show YES:显示，NO:隐藏
- (void)showBtnResetZoom:(BOOL)show;

@end

NS_ASSUME_NONNULL_END
