//
//  PLVInteractGenericView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/12/15.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 互动视图
///
/// @note 支持 ’答题卡、公告、抽奖、问卷、签到‘；
///       依赖于Socket模块正常运作，若互动视图异常，请先确认Socket已正确连接；
///       添加至相应视图中，并调用加载方法即可;
@interface PLVInteractGenericView : UIView

/// 此时是否不允许转屏 (默认NO；接收到不同互动消息时，此值将根据业务要求，相应地变化)
@property (nonatomic, assign, readonly) BOOL forbidRotateNow;

/// 是否保持互动视图在同级视图中最顶层
///
/// @note 互动视图需要最顶层，才能保证接收到最新互动时，可完整地被用户查看
///      (YES:每次互动出现时，自动移至同级最顶层;  NO:每次互动出现时，不做层级上的变动；默认为YES)
@property (nonatomic, assign) BOOL keepInteractViewTop;

#pragma mark - 页面加载

/// 加载在线 互动页面
///
/// @note 为避免自动布局的警告，需在调用此方法前，设置 PLVInteractGenericView 的frame值
- (void)loadOnlineInteract;

/// 加载本地 互动页面
///
/// @param htmlString 本地 html 解析后内容
/// @param baseURL 可访问的文件夹路径 (注意是 file:// 开头的 URL)
- (void)loadLocalInteractWithHTMLString:(NSString *)htmlString baseURL:(NSURL *)baseURL;

/// 更新用户信息
/// 在用户的信息改变后进行通知，目前主要是用户频道信息【sessionId】的改变
- (void)updateUserInfo;

/// 打开公告
- (void)openLastBulletin;

/// 打开互动应用弹窗
/// @param eventName 事件名称，由 JS 传递过来。
- (void)openInteractAppWithEventName:(NSString *)eventName;

@end

NS_ASSUME_NONNULL_END