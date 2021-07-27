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

@end

@interface PLVLSDocumentAreaView : UIView

@property (nonatomic, weak) id<PLVLSDocumentAreaViewDelegate> delegate;

/// 显示白板
- (void)showWhiteboard;

/// 显示文档
- (void)showDocument;

/// 开始上课
- (void)startClass:(NSDictionary *)onSliceStartDict;

/// 下课（直播结束）
- (void)finishClass;

/// 获取当前文档信息
- (NSDictionary *)getCurrentDocumentInfoDict;

@end

NS_ASSUME_NONNULL_END
