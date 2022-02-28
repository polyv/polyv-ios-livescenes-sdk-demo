//
//  PLVMultiRoleLinkMicPresenter.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/8/13.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PLVChatUser.h"
#import "PLVLinkMicWaitUser.h"
#import "PLVLinkMicOnlineUser.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVMultiRoleLinkMicPresenterDelegate;

@interface PLVMultiRoleLinkMicPresenter : NSObject

#pragma mark - [ 属性 ]

#pragma mark 可配置项

@property (nonatomic, weak) id<PLVMultiRoleLinkMicPresenterDelegate> delegate;

#pragma mark 状态

/// 是否已进入RTC频道中
@property (nonatomic, assign, readonly) BOOL inRTCRoom;

/// 本地用户的’麦克风‘当前是否开启
@property (nonatomic, assign, readonly) BOOL currentMicOpen;

/// 本地用户的‘摄像头’当前是否开启 (描述的是，该用户本身 ‘摄像头设备’ 此时是否开启)
@property (nonatomic, assign, readonly) BOOL currentCameraOpen;

/// 本地用户的‘摄像头’当前是否应该显示 (描述的是，根据业务逻辑，该用户的 ‘摄像头画面’ 此时是否应该显示)
@property (nonatomic, assign, readonly) BOOL currentCameraShouldShow;

/// 本地用户的‘摄像头’当前是否前置
@property (nonatomic, assign, readonly) BOOL currentCameraFront;

#pragma mark 对象

/// RTC屏幕流渲染画布
/// @note 内部自创建，用于承载 ’RTC屏幕流画面‘ 的渲染。可避免在外部视图中因画面变动，而可能产生反复渲染的问题。
///       用法：直接将该 rtcScreenStreamView，添加在希望展示 ’RTC屏幕流画面‘ 的父视图上。
@property (nonatomic, strong, readonly) UIView *rtcScreenStreamView;

#pragma mark 数据

/// 本地用户
@property (nonatomic, strong, readonly) PLVLinkMicOnlineUser *localUser; 

#pragma mark - [ 方法 ]

#pragma mark RTC房间管理（通用）

/// 加入RTC频道
///
/// @note 加入RTC频道成功，触发回调【multiRoleLinkMicPresenterJoinRTCChannelSuccess:】
///       加入RTC频道失败，触发回调【multiRoleLinkMicPresenterJoinRTCChannelFailure:】
- (void)joinRTCChannel;

/// 退出RTC频道
///
/// @note 可能会触发回调【multiRoleLinkMicPresenterLeaveRTCChannelResult:】
- (void)leaveRTCChannel;

/// 切换RTC频道
- (void)changeChannel;

#pragma mark 本地用户管理（通用）

/// 开启或关闭【本地用户】的麦克风
///
/// @note 若已处于上台状态，开启或关闭麦克风成功触发回调【multiRoleLinkMicPresenter:localUserMicOpenChanged:】
///
/// @param open YES-开启麦克风; NO-关闭麦克风
- (void)openLocalUserMic:(BOOL)open;

/// 开启或关闭【本地用户】的摄像头
///
/// @note 若已处于上台状态，开启或关闭摄像头成功触发回调【multiRoleLinkMicPresenter:localUserCameraShouldShowChanged:】
///
/// @param open YES-开启摄像头; NO-关闭摄像头
- (void)openLocalUserCamera:(BOOL)open;

/// 切换【本地用户】的前后置摄像头
///
/// @note 若已处于上台状态，切换前后置摄像头成功触发回调【multiRoleLinkMicPresenter:localUserCameraFrontChanged:】
///
/// @param front YES-前置; NO-后置
- (void)switchLocalUserCamera:(BOOL)front;

/// 配置 流清晰度
///
/// @note 支持在 正在推流 期间进行调用
///
/// @param streamQuality 流清晰度
- (void)setupStreamQuality:(PLVBLinkMicStreamQuality)streamQuality;

#pragma mark 本地用户管理（以下API仅学员身份时有效）

/// 答复讲师发出的上台请求并加入连麦
- (void)answerForJoinResponse;

#pragma mark 连麦用户数组管理（通用）

/// @return 返回当前连麦用户数组
- (NSArray <PLVLinkMicOnlineUser *> *)currentLinkMicUserArray;

/// 查询某个条件的‘连麦在线用户’，在数组中的下标值
/// @param filtrateBlock 筛选条件Block (参数enumerateUser:遍历过程中的用户Model，请自行判断其是否符合筛选目标；返回值 BOOL，判断后告知此用户Model是否目标)
/// @return 根据 filtrateBlock 的筛选，返回找到的目标用户Model在数组中的下标值 (若小于0，表示查询失败无法找到)
- (NSInteger)linkMicUserIndexWithFiltrateBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filtrateBlock;

/// 根据下标值获取‘连麦在线用户’模型
/// @param index 下标值
/// @return 成功时返回符合要求的‘连麦在线用户’模型；失败返回 nil
- (PLVLinkMicOnlineUser *)linkMicUserWithIndex:(NSInteger)index;

/// 根据连麦用户ID获取‘连麦在线用户’模型
/// @param linkMicId 连麦用户ID
/// @return 成功时返回符合要求的‘连麦在线用户’模型；失败返回 nil
- (PLVLinkMicOnlineUser *)linkMicUserWithLinkMicId:(NSString *)linkMicId;

/// 切换组长时，更新连麦用户的groupLeader字段，并对用户列表重新排序，组长排在讲师之后，组员之前
- (void)updateGroudLeader;

#pragma mark 连麦用户操作管理（以下API仅讲师身份时有效）

/// 允许某位远端用户上麦
///
/// @note 该接口仅讲师身份时有效
///       上麦成功触发回调【multiRoleLinkMicPresenter:linkMicUserArrayChanged:】刷新列表
///       以及触发回调【multiRoleLinkMicPresenter:didJoinUserLinkMic:】提醒已允许'某位远端用户'上台
///
/// @param chatUser 待上麦用户数据模型
- (void)allowUserLinkMic:(PLVChatUser *)chatUser;

/// 挂断某位远端用户的连麦
///
/// @note 该接口仅讲师身份时有效
///       挂断成功触发回调【multiRoleLinkMicPresenter:linkMicUserArrayChanged:】刷新列表
///       以及触发回调【multiRoleLinkMicPresenter:didCloseUserLinkMic:】提醒已挂断'某位远端连麦用户'
///
/// @param linkMicUser 待下麦用户数据模型
- (void)closeUserLinkMic:(PLVLinkMicOnlineUser *)linkMicUser;

/// 挂断全部连麦用户
///
/// @note 该接口仅讲师身份时有效
///       不触发任何回调
- (BOOL)closeAllLinkMicUser;

/// 禁用或取消禁用‘远端用户麦克风’
///
/// @note 该接口仅讲师身份时有效
///       操作成功触发回调【multiRoleLinkMicPresenter:linkMicUser:audioMuted:】
///
/// @param linkMicUser 待操作的用户数据模型
/// @param mute YES-禁用; NO-取消禁用
- (void)muteMicrophoneWithLinkMicUser:(PLVLinkMicOnlineUser *)linkMicUser mute:(BOOL)mute;

/// 禁用或取消禁用‘远端用户摄像头’
///
/// @note 该接口仅讲师身份时有效
///       操作成功触发回调【multiRoleLinkMicPresenter:linkMicUser:videoMuted:】
///
/// @param linkMicUser 待操作的用户数据模型
/// @param mute YES-禁用; NO-取消禁用
- (void)muteCameraWithLinkMicUser:(PLVLinkMicOnlineUser *)linkMicUser mute:(BOOL)mute;

/// 静音或取消静音全部连麦用户的麦克风
///
/// @note 该接口仅讲师身份时有效
///       不触发任何回调
///
/// @param mute YES-静音;NO-取消静音
- (void)muteAllLinkMicUserMicrophone:(BOOL)mute;

@end

#pragma mark - [ 代理方法 ]
/// 连麦管理器 代理方法
@protocol PLVMultiRoleLinkMicPresenterDelegate <NSObject>

@optional

#pragma mark RTC房间事件（通用）

/// 加入 RTC 频道成功
/// @note 由方法【joinRTCChannel】触发
- (void)multiRoleLinkMicPresenterJoinRTCChannelSuccess:(PLVMultiRoleLinkMicPresenter *)presenter;

/// 加入 RTC 频道失败
/// @note 由方法【joinRTCChannel】触发
- (void)multiRoleLinkMicPresenterJoinRTCChannelFailure:(PLVMultiRoleLinkMicPresenter *)presenter;

/// 离开 RTC 频道
/// @note 由方法【leaveRTCChannel]】主动触发 或者 RTC 模块发送错误，被动离开也会触发
- (void)multiRoleLinkMicPresenterLeaveRTCChannelResult:(PLVMultiRoleLinkMicPresenter *)presenter;

/// ‘网络状态’发生变化时触发
/// @note 在inRTCRoom为NO时，无法获取网络状态
///       若自己有连麦，返回自己的上行网络；否则，返回连麦列表第一个用户的下行网络
/// @param networkQuality 当前 ‘网络状态’ 状态值
- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter
          networkQualityChanged:(PLVBLinkMicNetworkQuality)networkQuality;

/// 本地用户上行时延回调
/// @note 该回调的时间间隔约为 100ms~300ms，获取不到当前用户数据时不触发
///       若自己有连麦，返回自己的上行时延；否则，返回连麦列表第一个用户的上行时延
/// @param presenter 连麦管理器
/// @param rtt 本地用户上行时延(单位毫秒)
- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter localUserRttMS:(NSInteger)rtt;

/// 获取成员列表数据
/// @param presenter 连麦管理器
- (NSArray <PLVChatUser *> *)onlineUserArrayForMultiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter;

/// 获取指定ID的在线成员数据模型
/// @param presenter 连麦管理器
/// @param userId 待获取的用户ID
- (PLVChatUser * _Nullable)onlineUserForMultiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter withUserId:(NSString *)userId;

#pragma mark 本地用户事件（通用）

/// 本地用户的’麦克风开关状态‘发生变化
/// @param presenter 连麦管理器
/// @param open 本地用户的’麦克风‘当前是否开启
- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter localUserMicOpenChanged:(BOOL)open;

/// 本地用户的’摄像头是否应该显示值‘发生变化
/// @param presenter 连麦管理器
/// @param show 本地用户的‘摄像头’当前是否应该显示
- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter localUserCameraShouldShowChanged:(BOOL)show;

/// 本地用户的 ’摄像头前后置状态值‘ 发生变化
/// @param presenter 连麦管理器
/// @param front 本地用户‘摄像头’当前是否前置
- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter localUserCameraFrontChanged:(BOOL)front;

/// 本地用户的 ’上下台状态‘ 发生变化
/// @param presenter 连麦管理器
/// @param linkMic YES-本地用户被请上台；NO-本地用户被请下台
- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter localUserLinkMicStatusChanged:(BOOL)linkMic;

#pragma mark 本地用户事件（以下回调仅学员身份时会触发）

/// 本地用户收到讲师发起的 joinResponse 请求并要求答复
/// @param presenter 连麦管理器
- (void)multiRoleLinkMicPresenterNeedAnswerForJoinResponseEvent:(PLVMultiRoleLinkMicPresenter *)presenter;

#pragma mark 连麦用户事件（通用）

/// ’连麦在线用户数组‘发生改变
/// @param presenter 连麦管理器
/// @param linkMicUserArray 当前 连麦在线用户数组
- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter
        linkMicUserArrayChanged:(NSArray <PLVLinkMicOnlineUser *>*)linkMicUserArray;

#pragma mark 连麦用户事件（以下回调仅讲师身份时会触发）

/// 已允许'某位用户'上台事件回调
/// @param presenter 连麦管理器
/// @param linkMicUser 上台的 远端连麦用户(不包含本地用户）
- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter
             didJoinUserLinkMic:(PLVLinkMicOnlineUser *)linkMicUser;

/// 对上台请求作出答复
/// @param presenter 连麦管理器
/// @param success 上台成功与否
/// @param linkMicId 发出答复的 远端连麦用户ID
- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter
              didUserJoinAnswer:(BOOL)success
                      linkMicId:(NSString *)linkMicId;

/// 已挂断'某位远端连麦用户'事件回调
/// @param presenter 连麦管理器
/// @param linkMicUser 被挂断的 远端连麦用户(不包含本地用户）
- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter
            didCloseUserLinkMic:(PLVLinkMicOnlineUser *)linkMicUser;

/// 静音或取消静音‘远端用户’成功回调
/// @param presenter 连麦管理器
/// @param linkMicUser 连麦在线用户
/// @param mute YES-静音;NO-取消静音
- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter
                    linkMicUser:(PLVLinkMicOnlineUser *)linkMicUser
                     audioMuted:(BOOL)mute;

/// 禁用或取消禁用‘远端用户摄像头’成功回调
/// @param presenter 连麦管理器
/// @param linkMicUser 连麦在线用户
/// @param mute YES-禁用;NO-取消禁用
- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter
                    linkMicUser:(PLVLinkMicOnlineUser *)linkMicUser
                     videoMuted:(BOOL)mute;

/// 讲师希望对某个用户授权/取消授权画笔
/// @param presenter 连麦管理器
/// @param authUser 授权画笔的远端用户
/// @param authBrush 授权画笔(YES 授权 NO取消授权)
- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter
                  authBrushUser:(PLVLinkMicOnlineUser *)authUser
                      authBrush:(BOOL)authBrush;

/// 讲师希望对某个用户授予奖杯
/// @param presenter 连麦管理器
/// @param grantUser 授予奖杯的远端用户
- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter
                   grantCupUser:(PLVLinkMicOnlineUser *)grantUser;

#pragma mark 连麦用户事件（以下回调仅学员身份时会触发）

/// 讲师’屏幕流‘已渲染
/// @param presenter 连麦管理器
/// @param screenStreamView 讲师’屏幕流‘渲染视图，也可直接读取 rtcScreenStreamView 属性
- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter didTeacherScreenStreamRenderdIn:(UIView *)screenStreamView;

/// 讲师’屏幕流‘已移除
/// @param presenter 连麦管理器
- (void)multiRoleLinkMicPresenter:(PLVMultiRoleLinkMicPresenter *)presenter didTeacherScreenStreamRemovedIn:(UIView *)screenStreamView;

@end

NS_ASSUME_NONNULL_END
