//
//  PLVSDocumentAreaView.h
//  PLVLiveScenesDemo
//
//  Created by Hank on 2021/3/1.
//  Copyright © 2021 PLV. All rights reserved.
//  主页白板&PPT区域

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLSDocumentAreaView;

@protocol PLVLSDocumentAreaViewDelegate <NSObject>

///  画笔开关面板回调
///
/// @param documentAreaView 白板&PPT区域对象
/// @param isOpen YES： 打开画笔，NO： 关闭画笔
- (void)documentAreaView:(PLVLSDocumentAreaView *)documentAreaView openBrush:(BOOL)isOpen;

///  全屏回调
///
/// @param documentAreaView 白板&PPT区域对象
/// @param isFullScreen YES： 全屏，NO： 非全屏
- (void)documentAreaView:(PLVLSDocumentAreaView *)documentAreaView changeFullScreen:(BOOL)isFullScreen;

/// 讲师切换显示白板或文档
/// @param documentAreaView 白板&PPT区域对象
/// @param whiteboard YES：显示白板，NO：显示文档
- (void)documentAreaView:(PLVLSDocumentAreaView *)documentAreaView didShowWhiteboardOrDocument:(BOOL)whiteboard;

/// 讲师切换摄像头和文档的位置
/// @param documentAreaView 白板&PPT区域对象
/// @param pptView 需要同外部交换的 白板&PPT 视图
/// @param currentDocument 当前是否交换文档
- (void)documentAreaView:(PLVLSDocumentAreaView *)documentAreaView pptView:(UIView *)pptView exchangeDocument:(BOOL)currentDocument;

/// 切换文档区域显示的位置，在主视图或者外部显示
/// @param documentAreaView 白板&PPT区域对象
/// @param pptView 需要同外部交换的 白板&PPT 视图
/// @param pptToMain 白板&PPT是否需要显示在主视图
/// @param needSync 是否需要同步到远端(在本地用户点击切换按钮时则为YES)
- (void)documentAreaView:(PLVLSDocumentAreaView *)documentAreaView pptView:(UIView *)pptView changePPTPositionToMain:(BOOL)pptToMain syncRemoteUser:(BOOL)needSync;

@end

@interface PLVLSDocumentAreaView : UIView

@property (nonatomic, weak) id<PLVLSDocumentAreaViewDelegate> delegate;

/// 显示白板
- (void)showWhiteboard;

/// 显示文档
- (void)showDocument;

/// 关闭文档
- (void)dismissDocument;

/// 开始上课
- (void)startClass:(NSDictionary *)onSliceStartDict;

/// 下课（直播结束）
- (void)finishClass;

/// 本地用户授权为主讲(当为主讲权限时，可以进行PPT翻页)
/// @param auth 是否授权(YES授权，NO取消授权)
- (void)updateDocumentSpeakerAuth:(BOOL)auth;

/// 获取当前文档信息
- (NSDictionary *)getCurrentDocumentInfoDict;

/// 恢复上一场未结束直播的文档数据
- (void)synchronizeDocumentData;

/// 显示、隐藏 控制条视图
/// @param show YES: 显示 NO：隐藏
- (void)documentToolViewShow:(BOOL)show;

/// 承载展示外部视图
///
/// @param externalView 外部视图
- (void)displayExternalView:(UIView *)externalView;

@end

NS_ASSUME_NONNULL_END
