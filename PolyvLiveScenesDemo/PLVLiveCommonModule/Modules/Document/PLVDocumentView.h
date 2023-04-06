//
//  PLVDocumentView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/4/29.
//  Copyright © 2021 PLV. All rights reserved.
//  

#import <UIKit/UIKit.h>

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, PLVDocumentViewScene) {
    PLVDocumentViewSceneCloudClass,
    PLVDocumentViewSceneEcommerce,
    PLVDocumentViewSceneStreamer
};

@class PLVDocumentView;

@protocol PLVDocumentViewDelegate <NSObject>

@optional
#pragma mark 多场景通用回调

///  webView加载完成回调
- (void)documentView_webViewDidFinishLoading;

///  webView加载失败回调
- (void)documentView_webViewLoadFailWithError:(NSError *)error;

/// PPT视图 PPT位置需切换
/// @note 直播时，收到此回调，表示讲师开播的默认PPT位置，或表示讲师发出切换PPT位置的指令；
///       回放时，将复现讲师对PPT的位置操作，收到此回调时，外部应根据 pptToMain 值相应切换PPT视图位置。
///       推流开播时，收到此回调时，外部应根据 pptToMain 值相应切换PPT视图位置。
/// @param pptToMain PPT是否需要切换至主窗口 (YES:PPT需要切至主窗口 NO:PPT需要切至小窗，视频需要切至主窗口)
- (void)documentView_changePPTPositionToMain:(BOOL)pptToMain;

#pragma mark 观看场景回调

/// 获取刷新PPT的延迟时间
/// @note 不同情况下，PPT的刷新延迟时间不一，需向外部获知当前合适的延迟时间
/// @return unsigned int 返回刷新延迟时间 (单位:毫秒)
- (unsigned int)documentView_getRefreshDelayTime;

/// [回放时] PPT视图需要获取视频播放器的当前播放时间点
/// @return NSTimeInterval 当前播放时间点 (单位:毫秒)
- (NSTimeInterval)documentView_getPlayerCurrentTime;

#pragma mark 推流场景回调

/// webView 上准备输入文字时回调
/// @param inputText 输入文本
/// @param textColor 文本颜色字符串 格式：#FFFFFF
- (void)documentView_inputWithText:(NSString *)inputText textColor:(NSString *)textColor;

/// 切换到新文档时的回调
/// 用于切换文档时更新文档缩略图
/// @param autoId 文档autoId
/// @param imageUrls 文档页面缩略图
/// @param fileName 文档名称（存在fileName时，表示续播）
- (void)documentView_changeWithAutoId:(NSUInteger)autoId imageUrls:(NSArray *)imageUrls fileName:(NSString *)fileName;

/// 文档、白板页码变化的回调
/// @param autoId 文档autoId
/// @param pageNumber 文档当前页码
/// @param totalPage 文档总页码
/// @param step 文档动画步数
- (void)documentView_pageStatusChangeWithAutoId:(NSUInteger)autoId
                                pageNumber:(NSUInteger)pageNumber
                                 totalPage:(NSUInteger)totalPage
                                   pptStep:(NSUInteger)step;

/// 文档、白板页码变化的回调
/// @param autoId 文档autoId
/// @param pageNumber 文档当前页码
/// @param totalPage 文档总页码
/// @param step 文档动画步数（无动画的文档为0）
/// @param maxNextNumber 最大的下一页页码
- (void)documentView_pageStatusChangeWithAutoId:(NSUInteger)autoId
                                pageNumber:(NSUInteger)pageNumber
                                 totalPage:(NSUInteger)totalPage
                                   pptStep:(NSUInteger)step
                                  maxNextNumber:(NSUInteger)maxNextNumber;

/// 白板或PPT尺寸缩放比例改变时的回调
/// @param zoomRatio 缩放比例
- (void)documentView_whiteboardPPTZoomChangeRatio:(NSInteger)zoomRatio;

/// app在直播过程中如果异常退出，可继续上次的直播，但需要获取上次直播文档
/// @param autoId 文档autoId
/// @param pageNumber 文档当前页码
- (void)documentView_continueClassWithAutoId:(NSUInteger)autoId
                                  pageNumber:(NSUInteger)pageNumber;

/// 讲师设置用户画笔权限
/// @param permission 是否拥有画笔权限（YES:授权，NO:取消授权）
/// @param userId 授权用户Id
- (void)documentView_teacherSetPaintPermission:(BOOL)permission userId:(NSString *)userId;

@end

@interface PLVDocumentView : UIView

@property (nonatomic, weak) id<PLVDocumentViewDelegate> delegate;

/// 数据
/// scene 为 PLVDocumentViewSceneCloudClass 或 PLVDocumentViewSceneEcommerce 的数据
@property (nonatomic, assign, readonly) NSInteger autoId;                     // ppt id, 0是白板
@property (nonatomic, assign, readonly) NSInteger currPageNum;                // 当前页码
@property (nonatomic, assign, readonly) NSInteger totalPageNum;               // 总页码
@property (nonatomic, assign, readonly) NSUInteger pptStep;                   // 当前文档所处于动画步数

/// scene 为PLVDocumentViewSceneCloudClass、 PLVDocumentViewSceneStreamer 的数据
@property (nonatomic, assign, readonly) BOOL mainSpeakerPPTOnMain;            // 当前场景中 主讲的PPT当前是否在主屏

// TODO: 下面值待推流功能集成合并代码后，再处理
// 距离上课时间点的已过时长（单位秒；包含退后台时间）
@property (nonatomic, assign) NSTimeInterval liveDurationAfterStart;

/// 是否开始上课
/// NO: 在接受到'sendSocketEvent' js事件时，不发送画笔'onSliceDraw'事件
/// YES: 正常发送
@property (nonatomic, assign) BOOL startClass;

#pragma mark - 多场景通用方法

/// 初始化方法
/// @param scene 场景类型，不同场景会有不同的行为模式
- (instancetype)initWithScene:(PLVDocumentViewScene)scene;

/// 设置背景图图片内容、图片占父视图比例
/// @param image 背景图图片
/// @param widthScale 背景图宽度占父视图宽度的比例
- (void)setBackgroudImage:(UIImage *)image widthScale:(CGFloat)widthScale;

/// 加载 PPT 链接
/// @param paramString h5链接后面的参数字符串（key=value&key=value&...）
- (void)loadRequestWitParamString:(NSString * _Nullable)paramString;

/// 加载本地 ppt 链接
/// @param filePath 本地ppt路径
/// @param accessPath 允许的本地资源路径
- (void)loadRequestWithLocalHtml:(NSString *)filePath allowingReadAccessToURL:(NSString *)accessPath;

/// 白板、PPT内部翻页
/// @note 区别 'changePPTWithAutoId:pageNumber:'，不可用于白板与PPT之间的切换，或打开另一份PPT文档
/// @param type 翻页类型
- (void)changePPTPageWithType:(PLVChangePPTPageType)type;

#pragma mark - 观看专用方法(scene == PLVDocumentViewSceneCloudClass/PLVDocumentViewSceneEcommerce 时方生效）

/// 【观看回放时】设置本地ppt路径
/// @param path ppt路径
- (void)pptSetOfflinePath:(NSString *)path;

/// 【观看回放时】加载本地ppt
/// @param videoId 暂存视频为fileId，回放视频为videoId
/// @param vid 暂存视频为fileId，回放视频为videopoolId
- (void)pptLocalStartWithVideoId:(NSString *)videoId vid:(NSString *)vid;

/// 【观看直播时】设置视频SEI信息
/// @param newTimeStamp SEI信息
- (void)setSEIDataWithNewTimestamp:(long)newTimeStamp;

/// 【观看回放时】加载回放PPT
/// @param vid 回放视频的vid
- (void)pptStart:(NSString *)vid DEPRECATED_MSG_ATTRIBUTE("已废弃，请使用pptStartWithVideoId:roomId:");

/// 【观看回放时】加载回放PPT
/// @param videoId 回放视频的videoId(请求'直播回放视频的信息'接口返回的视频Id，与后台回放列表看到的vid不是同一个数据；可在PLVPlayerPresenter类访问videoId属性得到)
/// @param channelId 频道Id
- (void)pptStartWithVideoId:(NSString *)videoId channelId:(NSString *)channelId;

/// 【观看暂存时】加载暂存PPT
/// @param fileId 暂存视频的fileId
/// @param channelId 频道Id
- (void)pptStartWithFileId:(NSString *)fileId channelId:(NSString *)channelId;

#pragma mark - 操作白板的方法

/// 设置文档的用户交互启用，即开启画笔权限
/// @note 讲师默认启用。嘉宾、观众默认禁用，授权后可开启用户交互手势和画笔权限
///
/// @param enabled  是否启用 YES 启用，NO禁用
- (void)setDocumentUserInteractionEnabled:(BOOL)enabled;

/// 在非授权白板权限的情况下，允许切换文档或白板，用于双师模式
- (void)openChangePPTPermission;

/// 设置画板是否处于可绘制状态
/// @param open  打开或关闭画板
- (void)setPaintStatus:(BOOL)open;

/// 设置画笔类型
/// @param type  line - 自由笔；text - 文字；arrowLine - 箭头
- (void)setDrawType:(PLVWebViewBrushPenType)type;

/// 完成文本输入
- (void)changeTextContent:(NSString *)content;

/// 修改画笔颜色
/// @param hexString  RGB色值，如红色为“#FF0000”
- (void)changeColor:(NSString *)hexString;

/// 执行撤回画板操作
- (void)doUndo;

/// 进入画笔删除状态
- (void)toDelete;

/// 删除所有画笔
- (void)deleteAllPaint;

/// 告诉 h5 现在开始上课，h5 会清空画板
/// @param jsonDict 开始推流时发送的 socket 消息
- (void)setSliceStart:(NSDictionary *)jsonDict;

/// 白板、文档间的切换方法
/// 如果切换的是文档，切换成功后触发回调 '-jsbridge_documentChangeWithAutoId:imageUrls:'
/// @param autoId  切换的文档的 autoId，如果是白板 autoId 为 0
/// @param pageNumber  切换到文档的第几页
- (void)changePPTWithAutoId:(NSUInteger)autoId pageNumber:(NSInteger)pageNumber;

/// 当前白板/文档下的翻页方法
- (void)turnPage:(BOOL)isNextPage;

/// 新增白板方法
- (void)addWhiteboard;

/// 重置 白板或PPT 缩放比例为 100%
- (void)resetWhiteboardPPTZoomRatio;

@end

NS_ASSUME_NONNULL_END
