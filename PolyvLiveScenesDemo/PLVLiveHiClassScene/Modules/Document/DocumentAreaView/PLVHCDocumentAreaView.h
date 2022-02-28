//
//  PLVHCDocumentAreaView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 PLV. All rights reserved.
//
// PPT/白板区域视图

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import "PLVHCBrushToolBarView.h"
#import "PLVRoomUser.h"
#import "PLVDocumentContainerView.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVHCDocumentAreaView;
@class PLVHCDocumentMinimumModel;

@protocol PLVHCDocumentAreaViewDelegate <NSObject>

/// 刷新画笔工具权限 时调用
/// @param permission YES: 已被授予画笔权限；NO: 画笔权限已被移除
/// @param userId 用户Id
- (void)documentAreaView:(PLVHCDocumentAreaView *)documentAreaView didRefreshBrushPermission:(BOOL)permission userId:(NSString *)userId;

@end

@interface PLVHCDocumentAreaView : UIView

@property (nonatomic, weak) id<PLVHCDocumentAreaViewDelegate> delegate;
/// PPT、白板功能模块视图
@property (nonatomic, strong, readonly) PLVDocumentContainerView *containerView;
/// 是否为最大最小化文档数量，当前版本限制最多为5个
@property (nonatomic, assign, readonly, getter=isMaxMinimumNum) BOOL maxMinimumNum;

#pragma mark 正式进入课室

- (void)enterClassroom;

#pragma mark JS交互(native -> js）

/// 打开文档
/// @note 只有讲师、组长方可操作
/// @param autoId 文档autoId
- (void)openPptWithAutoId:(NSUInteger)autoId;

/// 授予画笔权限
/// @note 只有讲师、组长方可操作
/// @param userId 用户Id
- (void)setPaintBrushAuthWithUserId:(NSString *)userId;

/// 移除画笔权限
/// @note 只有讲师、组长方可操作
/// @param userId 用户Id
- (void)removePaintBrushAuthWithUserId:(NSString *)userId;

/// 移除自己的画笔权限,可用于学生端在讲师下课后重置移除自己的画笔权限
/// @note 对齐服务端数据，无需发送socket消息，只需通知白板更新权限即可
- (void)removeSelfPaintBrushAuth;

/// 设为组长或移除组长
/// @note 根据socket消息得知是否需要设置为，触发后如果是组长，内部会自动授予画笔权限，无需另外发送 givePaintBrushAuth 到 webview 中
/// @param isLeader 是否设为组长，YES:设为组长，NO：移除组长，默认为 false
- (void)setOrRemoveGroupLeader:(BOOL)isLeader;

/// 切换房间，用于开始或结束分组讨论时切换房间，更新'PPT/白板'数据
/// @param ackData leaveDiscuss、joinDiscuss 这两个Socket事件的Ack回调数据
/// @param callback js回调
- (void)switchRoomWithAckData:(NSDictionary *)ackData datacallback:(_Nullable PLVContainerResponseCallback)callback;

@end

NS_ASSUME_NONNULL_END
