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

/// 设置页码UI
///
/// @param currNum 当前页数
/// @param totalNum 总页数
- (void)setPageNum:(NSInteger)currNum totalNum:(NSInteger)totalNum;

@end

NS_ASSUME_NONNULL_END
