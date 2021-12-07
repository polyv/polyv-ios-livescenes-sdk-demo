//
//  PLVDocumentContainerView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/13.
//  Copyright © 2021 PLV. All rights reserved.
// 容器版webviewSDk WKWebView视图
// 用于展示容器(ppt、word各类文档统称)视图

#import <UIKit/UIKit.h>

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVDocumentContainerView;

@protocol PLVDocumentContainerViewDelegate <NSObject>

///  webView加载完成回调
/// @note 回调在主线程执行
- (void)documentContainerViewDidFinishLoading:(PLVDocumentContainerView *)documentContainerView;

///  webView加载失败回调
/// @note 回调在主线程执行
- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didLoadFailWithError:(NSError *)error;

/// 刷新画笔工具显示状态 时调用
/// @note 回调在主线程执行
- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didRefreshBrushToolStatusWithJsonObject:(id)jsonObject;

/// 准备开始编辑文字 时调用
/// @note 回调在主线程执行
- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView willStartEditTextWithJsonObject:(id)jsonObject;

/// 刷新画笔工具权限 时调用
/// @note 回调在主线程执行
- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didRefreshBrushPermission:(BOOL)permission userId:(NSString *)userId;

/// 更新画笔工具类型 时调用
/// @note 回调在主线程执行，学生专属
- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didChangeApplianceType:(PLVContainerApplianceType)applianceType;

/// 更新画笔颜色 时调用
/// @note 回调在主线程执行，学生专属
- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didChangeStrokeHexColor:(NSString *)strokeHexColor;

/// 刷新最小化的容器(ppt、word各类文档统称)数据 时调用
/// @note 回调在主线程执行，讲师、组长专属
- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView  didRefreshMinimizeContainerDataWithJsonObject:(id)jsonObject;

/// 刷新打开的PPT容器数量 时调用
/// @note 回调在主线程执行，讲师、组长专属
- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView  didRefreshPptContainerTotalWithJsonObject:(id)jsonObject;

/// 更新画板缩放百分比 时调用
/// @note 回调在主线程执行，讲师、组长专属
- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didChangeZoomPercent:(CGFloat)percent;

/// 刷新组长权限 时调用
/// @note 回调在主线程执行
- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didRefreshGroupLeader:(BOOL)isLeader userId:(NSString *)userId;

@end

@interface PLVDocumentContainerView : UIView

@property (nonatomic, weak) id<PLVDocumentContainerViewDelegate> delegate;

/// 加载 PPT 链接
/// @param paramString h5链接后面的参数字符串（key=value&key=value&...）
- (void)loadRequestWitParamString:(NSString * _Nullable)paramString;

#pragma mark native -> js

/// 切换教具
/// @param type 教具类型
- (void)changeApplianceType:(PLVContainerApplianceType)type;

/// 修改文本宽度
/// @param fontSize 文本宽度
- (void)changeFontSize:(NSUInteger)fontSize;

/// 修改线条宽度
/// @param width 线条宽度
- (void)changeLineWidth:(NSUInteger)width;

/// 修改笔触颜色
/// @param hexColor 16进制颜色字符串
- (void)changeStrokeWithHexColor:(NSString *)hexColor;

/// 关闭 PPT
/// @param autoId 文档autoId
- (void)closePptWithAutoId:(NSUInteger)autoId;

/// 执行清空画板操作
- (void)doClear;

/// 执行重做画板操作
- (void)doRedo;

/// 执行撤回画板操作
- (void)doUndo;

/// 执行删除画笔操作
- (void)doDelete;

/// 打开文档
/// @param autoId 文档autoId
- (void)openPptWithAutoId:(NSUInteger)autoId;

/// 操作容器(ppt、word各类文档统称)
/// @param containerId 容器内容Id
/// @param close 关闭、打开
- (void)operateContainerWithContainerId:(NSString *)containerId close:(BOOL)close;

/// 完成编辑文字
/// @note 用于native完成文字输入后返回给webView
/// @param text 文字
- (void)finishEditText:(NSString *)text;

/// 取消编辑文字
- (void)cancelEditText;

/// 关闭自己的画笔权限
- (void)removePaintBrushAuth;

/// 设为组长或移除组长
/// @note 根据socket消息得知是否需要设置为，触发后如果是组长，内部会自动授予画笔权限，无需另外发送 givePaintBrushAuth 到 webview 中
/// @param isLeader 是否设为组长，YES:设为组长，NO：移除组长，默认为 false
- (void)setOrRemoveGroupLeader:(BOOL)isLeader;

/// 切换房间，用于开始或结束分组讨论时切换房间
/// @param ackData leaveDiscuss、joinDiscuss 这两个Socket事件的Ack回调数据
/// @param callback js回调
- (void)switchRoomWithAckData:(NSDictionary *)ackData datacallback:(_Nullable PLVContainerResponseCallback)callback;

#pragma mark 讲师、组长专用方法 native -> js

/// 授予画笔权限
/// @note 只有讲师、组长方可操作
/// @param userId 用户Id
- (void)setPaintBrushAuthWithUserId:(NSString *)userId;

/// 移除画笔权限
/// @note 只有讲师、组长方可操作
/// @param userId 用户Id
- (void)removePaintBrushAuthWithUserId:(NSString *)userId;

/// 重置画板缩放
/// @note 只有讲师、组长方可操作
- (void)resetZoom;

@end

NS_ASSUME_NONNULL_END
