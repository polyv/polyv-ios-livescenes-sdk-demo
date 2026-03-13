//
//  PLVInteractLatestGenericView.h
//  PolyvLiveScenesDemo
//
//  最新互动页容器视图（叠加在原互动页之上）
//

#import <UIKit/UIKit.h>
#import "PLVChatModel.h"
#import "PLVInteractGenericView.h"

NS_ASSUME_NONNULL_BEGIN

/// 最新互动页视图
///
/// @note 接口与 `PLVInteractGenericView` 对齐，当前主要实现
///       `loadOnlineInteract`、`updateUserInfo` 等基础能力。
@interface PLVInteractLatestGenericView : UIView

@property (nonatomic, weak) id<PLVInteractGenericViewDelegate> delegate;

/// 此时是否不允许转屏 (默认NO)
@property (nonatomic, assign, readonly) BOOL forbidRotateNow;

/// 是否保持互动视图在同级视图中最顶层，默认 YES
@property (nonatomic, assign) BOOL keepInteractViewTop;

/// 创建 最新互动视图
/// @param liveType 直播场景（与原互动页保持一致）
/// @param liveRoom 是否直播房间
- (instancetype)initWithLiveType:(PLVInteractGenericViewLiveType)liveType liveRoom:(BOOL)liveRoom;

#pragma mark - 页面加载

/// 加载在线 最新互动页面
- (void)loadOnlineInteract;

/// 更新用户信息
/// 在用户的信息改变后进行通知，目前主要是用户频道信息【sessionId】的改变
- (void)updateUserInfo;

/// 打开互动应用弹窗（透传事件名给最新互动页）
/// @param eventName 事件名称，由 JS 约定
- (void)openInteractAppWithEventName:(NSString *)eventName;

@end

NS_ASSUME_NONNULL_END

