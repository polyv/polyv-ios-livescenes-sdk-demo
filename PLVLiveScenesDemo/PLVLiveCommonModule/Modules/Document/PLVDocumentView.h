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

#pragma mark 多场景通用回调

///  webView加载完成回调
- (void)documentView_webViewDidFinishLoading;

///  webView加载失败回调
- (void)documentView_webViewLoadFailWithError:(NSError *)error;

#pragma mark 观看场景回调

/// 获取刷新PPT的延迟时间
/// @note 不同情况下，PPT的刷新延迟时间不一，需向外部获知当前合适的延迟时间
/// @return unsigned int 返回刷新延迟时间 (单位:毫秒)
- (unsigned int)documentView_getRefreshDelayTime;

/// PPT视图 PPT位置需切换
/// @note 直播时，收到此回调，表示讲师开播的默认PPT位置，或表示讲师发出切换PPT位置的指令；
///       回放时，将复现讲师对PPT的位置操作，收到此回调时，外部应根据 pptToMain 值相应切换PPT视图位置。
/// @param pptToMain PPT是否需要切换至主窗口 (YES:PPT需要切至主窗口 NO:PPT需要切至小窗，视频需要切至主窗口)
- (void)documentView_changePPTPositionToMain:(BOOL)pptToMain;

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
- (void)documentView_changeWithAutoId:(NSUInteger)autoId imageUrls:(NSArray *)imageUrls;

/// 文档、白板页码变化的回调
/// @param autoId 文档autoId
/// @param pageNumber 文档当前页码
/// @param totalPage 文档总页码
/// @param step 文档动画步数
- (void)documentView_pageStatusChangeWithAutoId:(NSUInteger)autoId
                                pageNumber:(NSUInteger)pageNumber
                                 totalPage:(NSUInteger)totalPage
                                   pptStep:(NSUInteger)step;

@end

@interface PLVDocumentView : UIView

@property (nonatomic, weak) id<PLVDocumentViewDelegate> delegate;

/// 数据
/// scene 为 PLVDocumentViewSceneCloudClass 或 PLVDocumentViewSceneEcommerce 的数据
@property (nonatomic, assign, readonly) NSInteger autoId;                     // ppt id, 0是白板
@property (nonatomic, assign, readonly) NSInteger currPageNum;                // 当前页码
@property (nonatomic, assign, readonly) NSInteger totalPageNum;               // 总页码
@property (nonatomic, assign, readonly) NSUInteger pptStep;                   // 当前文档所处于动画步数

/// scene 为 PLVDocumentViewSceneStreamer 的数据
@property (nonatomic, assign, readonly) BOOL mainSpeakerPPTOnMain;            // 观看场景中 主讲的PPT当前是否在主屏

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

#pragma mark - 观看专用方法(scene == PLVDocumentViewSceneCloudClass/PLVDocumentViewSceneEcommerce 时方生效）

/// 【观看直播时】设置视频SEI信息
/// @param newTimeStamp SEI信息
- (void)setSEIDataWithNewTimestamp:(long)newTimeStamp;

/// 【观看回放时】加载回放PPT
/// @param vid 回放视频的vid
- (void)pptStart:(NSString *)vid;

#pragma mark - 推流专用方法(scene == PLVDocumentViewSceneStreamer 时方生效）

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

@end

NS_ASSUME_NONNULL_END
