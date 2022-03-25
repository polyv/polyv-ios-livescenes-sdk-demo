//
//  PLVHCLinkMicZoomManager.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/11/17.
//  Copyright © 2021 PLV. All rights reserved.
// 【连麦放大视图数据模型管理类】用于管理socket数据的发送与监听

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN
@class PLVHCLinkMicZoomManager,PLVHCLinkMicZoomModel;

@protocol PLVHCLinkMicZoomManagerDelegate <NSObject>

/// 更新窗口 时回调
- (void)linkMicZoomManager:(PLVHCLinkMicZoomManager *)linkMicZoomManager didUpdateZoomWithModel:(PLVHCLinkMicZoomModel *)model;

/// 移除窗口 时回调
- (void)linkMicZoomManager:(PLVHCLinkMicZoomManager *)linkMicZoomManager didRemoveZoomWithModel:(PLVHCLinkMicZoomModel *)model;

@end

static int kPLVHCLinkMicZoomMAXNum = 4; // 最大放大数量

@interface PLVHCLinkMicZoomManager : NSObject

/// 代理
@property (nonatomic, weak) id<PLVHCLinkMicZoomManagerDelegate> delegate;
/// 当前窗口最大下标
@property (nonatomic, assign, readonly) NSInteger windowMaxIndex;
/// 是否为最大的放大数量，最大数量限制参考：kPLVHCLinkMicZoomMAXNum
@property (nonatomic, assign, readonly) BOOL isMaxZoomNum;
/// 当前身份是否为讲师
@property (nonatomic, assign, readonly, getter=isTeacher) BOOL teacher;
/// 当前在放大区域的窗口数据模型
@property (nonatomic, strong, readonly) NSMutableArray <PLVHCLinkMicZoomModel *> *zoomModelArrayM;

/// 单例方法
+ (instancetype)sharedInstance;

/// 启动管理器
- (void)setup;

/// 退出前调用，用于资源释放、状态位清零
- (void)clear;

/// 开始分组
/// @note 移除所有连麦窗口
- (void)startGroup;

/// 从分组离开回到大房间
/// @note 重新加载大房间的窗口放大数据
/// @param ackData 大房间数据
- (void)leaveGroupRoomWithAckData:(NSDictionary *)ackData;

/// 【讲师】连麦用户退出时，移除连麦放大视图窗口
/// @note 发送 changeMicSite/remove socket消息
/// @param userId 用户Id
- (void)linkMicUserWillDealloc:(NSString *)userId;

 /// 【讲师】将窗口添加到连麦放大视图区域或将窗口移动、放大
/// @note 发送 changeMicSite/update socket消息
/// @param model 模型
- (BOOL)zoomWithModel:(PLVHCLinkMicZoomModel *)model;

/// 【讲师】移除连麦放大视图窗口
/// @note 发送 changeMicSite/remove socket消息
/// @param model 模型
- (BOOL)zoomOutWithModel:(PLVHCLinkMicZoomModel *)model;

/// 【讲师】移除全部连麦放大视图窗口
/// @note 发送 changeMicSite/remove socket消息
- (BOOL)zoomOutAll;

/// 判断当前是否在连麦放大视图区域
/// @param userId 用户Id
- (BOOL)isInZoomWithUserId:(NSString *)userId;

@end

NS_ASSUME_NONNULL_END
