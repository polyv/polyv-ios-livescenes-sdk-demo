//
//  PLVHCDocumentAreaView.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 polyv. All rights reserved.
//
// PPT/白板区域视图

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import "PLVHCBrushToolBarView.h"
#import "PLVRoomUser.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVHCDocumentAreaView;
@class PLVDocumentModel;
@class PLVHCDocumentMinimumModel;

@protocol PLVHCDocumentAreaViewDelegate <NSObject>

///  webView加载完成回调
- (void)documentAreaViewDidFinishLoading:(PLVHCDocumentAreaView *)documentAreaView;

/// 刷新最小化的容器(ppt、word各类文档统称)数据 时回调
- (void)documentAreaView:(PLVHCDocumentAreaView *)documentAreaView  didRefreshMinimizeContainerDataArray:(NSArray <PLVHCDocumentMinimumModel *> *)dataArray;

/// 刷新打开的PPT容器数量 时回调
- (void)documentAreaView:(PLVHCDocumentAreaView *)documentAreaView  didRefreshPptContainerTotal:(NSInteger)total;

/// 刷新画笔工具显示状态 时调用
- (void)documentAreaView:(PLVHCDocumentAreaView *)documentAreaView didRefreshBrushToolStatusWithJsonDict:(NSDictionary *)jsonDict;

/// 刷新画笔工具权限 时调用
/// @param permission YES: 已被授予画笔权限；NO: 画笔权限已被移除
/// @param userId 用户Id
- (void)documentAreaView:(PLVHCDocumentAreaView *)documentAreaView didRefreshBrushPermission:(BOOL)permission userId:(NSString *)userId;

/// 更新画笔工具类型 时调用
- (void)documentAreaView:(PLVHCDocumentAreaView *)documentAreaView didChangeApplianceType:(PLVContainerApplianceType)applianceType;

/// 更新画笔颜色 时调用
- (void)documentAreaView:(PLVHCDocumentAreaView *)documentAreaView didChangeStrokeHexColor:(NSString *)strokeHexColor;

/// 更新'重置画板缩放按钮'显示/隐藏 时调用
- (void)documentAreaView:(PLVHCDocumentAreaView *)documentAreaView didChangeResetZoomButtonShow:(BOOL)show;

@end

@interface PLVHCDocumentAreaView : UIView

@property (nonatomic, weak) id<PLVHCDocumentAreaViewDelegate> delegate;

#pragma mark  更新工具状态

/// 更新工具状态
/// @param dict 工具状态
- (void)updateBrushToolStatusWithDict:(NSDictionary *)dict;

#pragma mark JS交互(native -> js）

/// 打开文档
/// @note 只有讲师方可操作
/// @param autoId 文档autoId
- (void)openPptWithAutoId:(NSUInteger)autoId;

/// 操作容器(ppt、word各类文档统称)
/// @note 只有讲师方可操作
/// @param containerId 容器内容Id
/// @param close 关闭、打开
- (void)operateContainerWithContainerId:(NSString *)containerId close:(BOOL)close;

/// 授予画笔权限
/// @note 只有讲师方可操作
/// @param userId 用户Id
- (void)setPaintBrushAuthWithUserId:(NSString *)userId;

/// 移除画笔权限
/// @note 只有讲师方可操作
/// @param userId 用户Id
- (void)removePaintBrushAuthWithUserId:(NSString *)userId;

/// 移除自己的画笔权限,可用于学生端在讲师下课后重置移除自己的画笔权限（对齐服务端数据）
- (void)removeSelfPaintBrushAuth;

/// 重置画板缩放
/// @note 只有讲师方可操作
- (void)resetZoom;

/// 更新选择的画笔工具类型，发送js事件
/// @param toolType 画笔工具类型
- (void)updateSelectToolType:(PLVHCBrushToolType)toolType;

/// 更新选择的画笔颜色，发送js事件
/// @param color 画笔颜色
- (void)updateSelectColor:(NSString *)color;

/// 执行删除画笔操作
- (void)doDelete;

/// 执行撤回画板操作
- (void)doUndo;

@end

NS_ASSUME_NONNULL_END
