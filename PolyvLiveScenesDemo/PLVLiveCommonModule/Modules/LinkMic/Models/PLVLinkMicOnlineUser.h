//
//  PLVLinkMicOnlineUser.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/8/19.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLinkMicUserDefine.h"

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVChatUser, PLVLinkMicOnlineUser;

/// 回调定义
///
/// [状态] 用户的 ’音量‘ 改变Block
typedef void (^PLVLinkMicOnlineUserVolumeChangedBlock)(PLVLinkMicOnlineUser * onlineUser);
/// [状态] 用户的 ’麦克风开关状态‘ 改变Block
typedef void (^PLVLinkMicOnlineUserMicOpenChangedBlock)(PLVLinkMicOnlineUser * onlineUser);
/// [状态] 用户的 ’摄像头开关状态‘ 改变Block
typedef void (^PLVLinkMicOnlineUserCameraOpenChangedBlock)(PLVLinkMicOnlineUser * onlineUser);
/// [状态] 用户的 ’摄像头是否应该显示值‘ 改变Block
typedef void (^PLVLinkMicOnlineUserCameraShouldShowChangedBlock)(PLVLinkMicOnlineUser * onlineUser);
/// [状态] 用户的 ’摄像头前后置状态值‘ 改变Block
typedef void (^PLVLinkMicOnlineUserCameraFrontChangedBlock)(PLVLinkMicOnlineUser * onlineUser);
/// [状态] 用户的 ’闪光灯开关状态‘ 改变Block
typedef void (^PLVLinkMicOnlineUserCameraTorchOpenChangedBlock)(PLVLinkMicOnlineUser * onlineUser);
/// [状态] 用户的 ’网络状态‘ 改变Block
typedef void (^PLVLinkMicOnlineUserNetworkQualityChangedBlock)(PLVLinkMicOnlineUser * onlineUser);
/// [状态] 用户画笔授权状态改变Block
typedef void (^PLVLinkMicOnlineUserBrushAuthChangedBlock)(PLVLinkMicOnlineUser * onlineUser);
/// [状态] 用户被授予奖杯数量改变Block
typedef void (^PLVLinkMicOnlineUserGrantCupCountChangedBlock)(PLVLinkMicOnlineUser * onlineUser);
/// [状态] 用户举手或者取消举手状态改变Block
typedef void (^PLVLinkMicOnlineUserHandUpChangedBlock)(PLVLinkMicOnlineUser * onlineUser);
/// [状态] 用户的 ’当前是否上麦状态‘ 改变Block
typedef void (^PLVLinkMicOnlineUserCurrentStatusVoiceChangedBlock)(PLVLinkMicOnlineUser * onlineUser);
/// [状态] 用户的 ’当前的主讲权限‘ 改变Block
typedef void (^PLVLinkMicOnlineUserCurrentSpeakerAuthChangedBlock)(PLVLinkMicOnlineUser * onlineUser);
/// [状态] 用户的 ’屏幕共享开关状态‘ 改变Block
typedef void (^PLVLinkMicOnlineUserScreenShareOpenChangedBlock)(PLVLinkMicOnlineUser * onlineUser);
/// [状态] 用户的 ’连麦状态‘ 改变Block
typedef void (^PLVLinkMicOnlineUserLinkMicStatusChangedBlock)(PLVLinkMicOnlineUser * onlineUser);

///
/// [事件] 希望用户申请加入连麦 回调Block
typedef void (^PLVLinkMicOnlineUserWantRequestJoinLinkMicBlock)(PLVLinkMicOnlineUser * onlineUser, BOOL wantRequest);
/// [事件] 用户模型 即将销毁 回调Block
typedef void (^PLVLinkMicOnlineUserWillDeallocBlock)(PLVLinkMicOnlineUser * onlineUser);
/// [事件] 希望开关该用户的麦克风 回调Block
typedef void (^PLVLinkMicOnlineUserWantOpenMicBlock)(PLVLinkMicOnlineUser * onlineUser, BOOL wantOpen);
/// [事件] 希望开关该用户的摄像头 回调Block
typedef void (^PLVLinkMicOnlineUserWantOpenCameraBlock)(PLVLinkMicOnlineUser * onlineUser, BOOL wantOpen);
/// [事件] 希望切换该用户的前后置摄像头 回调Block
typedef void (^PLVLinkMicOnlineUserWantSwitchFrontCameraBlock)(PLVLinkMicOnlineUser * onlineUser, BOOL wantFront);
/// [事件] 希望挂断该用户的连麦 回调Block
typedef void (^PLVLinkMicOnlineUserWantCloseLinkMicBlock)(PLVLinkMicOnlineUser * onlineUser);
/// [事件] 希望授权用户画笔 回调Block
typedef void (^PLVLinkMicOnlineUserWantBrushAuthBlock)(PLVLinkMicOnlineUser * onlineUser, BOOL auth);
/// [事件] 希望授予用户奖杯 回调Block
typedef void (^PLVLinkMicOnlineUserWantGrantCupBlock)(PLVLinkMicOnlineUser * onlineUser);
/// [事件] 希望授予用户主讲权限 回调Block
typedef void (^PLVLinkMicOnlineUserWantAuthUserSpeakerBlock)(PLVLinkMicOnlineUser * onlineUser, BOOL wantAuth);
/// [事件] 希望开关该用户的屏幕共享 回调Block
typedef void (^PLVLinkMicOnlineUserWantOpenScreenShareBlock)(PLVLinkMicOnlineUser * onlineUser, BOOL wantOpen);
/// [事件] 希望改变该用户PPT是否在主视图 回调Block
typedef void (^PLVLinkMicOnlineUserWantChangePPTToMainBlock)(PLVLinkMicOnlineUser * onlineUser, BOOL wantChange);
 
/// RTC在线用户模型
///
/// @note 描述及代表了一位 RTC在线 的用户
///       该模型适用于 无延迟观看场景、连麦在线场景
@interface PLVLinkMicOnlineUser : NSObject

#pragma mark - [ 属性 ]
#pragma mark 可配置项
/// [状态] 用户的 ’音量‘ 改变Block
///
/// @note 仅在 currentVolume音量值 有改变时会触发；
///       若当前 currentMicOpen麦克风开关值 为NO时，则必定不触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserVolumeChangedBlock volumeChangedBlock;

/// [状态] 用户的 ’麦克风开关状态‘ 改变Block
///
/// @note 仅在 currentOpenMic开关值 有改变时会触发；
///       将在主线程回调；
///       支持 ’多接收方回调‘，参见 [addMicOpenChangedBlock:blockKey:]
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserMicOpenChangedBlock micOpenChangedBlock;

/// [状态] 用户的 ’摄像头开关状态‘ 改变Block
///
/// @note 仅在 currentCameraOpen开关值 有改变时会触发；
///       将在主线程回调；
///       对比 [cameraOpenChangedBlock] 更推荐使用 [cameraShouldShowChangedBlock]，后者代表了考虑业务逻辑后的最终结果；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserCameraOpenChangedBlock cameraOpenChangedBlock;

/// [状态] 用户的 ’摄像头是否应该显示值‘ 改变Block
///
/// @note 仅在 currentCameraShouldShow开关值 有改变时会触发；
///       将在主线程回调；
///       对比 [cameraOpenChangedBlock] 更推荐使用 [cameraShouldShowChangedBlock]，后者代表了考虑业务逻辑后的最终结果；
///       支持 ’多接收方回调‘，参见 [addCameraShouldShowChangedBlock:blockKey:]
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserCameraShouldShowChangedBlock cameraShouldShowChangedBlock;

/// [状态] 用户的 ’摄像头前后置状态值‘ 改变Block
///
/// @note 仅在 currentCameraFront开关值 有改变时会触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserCameraFrontChangedBlock cameraFrontChangedBlock;

/// [状态] 用户的 ’闪光灯开关状态‘ 改变Block
///
/// @note 仅在 currentCameraTorchOpen开关值 有改变时会触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserCameraTorchOpenChangedBlock cameraTorchOpenChangedBlock;

/// [状态] 用户的 ’网络状态‘ 改变Block
///
/// @note 仅在 currentNetworkQuality状态值 有改变时会触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserNetworkQualityChangedBlock networkQualityChangedBlock;

/// [状态] 用户的 ‘画笔授权状态’ 改变Block
///
/// @note 仅在 currentBrushAuth状态值 有改变时会触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserBrushAuthChangedBlock brushAuthChangedBlock;

/// [状态] 用户的 ‘授予奖杯数量’ 改变Block
///
/// @note 仅在 currentCupCount状态值 有改变时会触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserGrantCupCountChangedBlock grantCupCountChangedBlock;

/// [状态] 用户的 ‘举手状态’ 改变Block
///
/// @note 仅在 currentHandUp状态值 有改变时会触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserHandUpChangedBlock handUpChangedBlock;

/// [状态] 用户的 ’当前是否上麦状态‘ 改变Block
///
/// @note 仅在 currentStatusVoice状态值 有改变时会触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserCurrentStatusVoiceChangedBlock currentStatusVoiceChangedBlock;

/// [状态] 用户的 ‘当前主讲权限’ 改变Block
///
/// @note 仅在isRealMainSpeaker状态值 有改变时会触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserCurrentSpeakerAuthChangedBlock currentSpeakerAuthChangedBlock;

/// [状态] 用户的 ‘屏幕共享开关状态’ 改变Block
///
/// @note 仅在 currentScreenShareOpen 开关值 有改变时会触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserScreenShareOpenChangedBlock screenShareOpenChangedBlock;

/// [状态] 用户 ‘连麦状态改变’ 回调Block
///
/// @note 仅在 linkMicStatus 状态 有改变时会触发；不保证在主线程回调
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserLinkMicStatusChangedBlock linkMicStatusBlock;

/// [事件] 希望用户申请加入连麦 回调Block
///
/// @note 由 [wantUserRequestJoinLinkMic] 方法直接触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserWantRequestJoinLinkMicBlock wantRequestJoinLinkMicBlock;

/// [事件] 用户模型 即将销毁 回调Block
///
/// @note 不保证在主线程回调
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserWillDeallocBlock willDeallocBlock;

/// [事件] 希望开关该用户的麦克风 回调Block
///
/// @note 由 [wantOpenUserMic:] 方法直接触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserWantOpenMicBlock wantOpenMicBlock;

/// [事件] 希望开关该用户的摄像头 回调Block
///
/// @note 由 [wantOpenUserCamera:] 方法直接触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserWantOpenCameraBlock wantOpenCameraBlock;

/// [事件] 希望切换该用户的前后置摄像头 回调Block
///
/// @note 由 [wantSwitchUserFrontCamera:] 方法直接触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserWantSwitchFrontCameraBlock wantSwitchFrontCameraBlock;

/// [事件] 希望挂断该用户的连麦 回调Block
///
/// @note 由 [wantCloseUserLinkMic] 方法直接触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserWantCloseLinkMicBlock wantCloseLinkMicBlock;

/// [事件] 希望授权该用户画笔的 回调Block
///
/// @note 由 [wantAuthUserBrush] 方法直接触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserWantBrushAuthBlock wantBrushAuthBlock;

/// [事件] 希望授予该用户奖杯的 回调Block
///
/// @note 由 [wantGrantUserCup] 方法直接触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserWantGrantCupBlock wantGrantCupBlock;

/// [事件] 希望授予用户主讲权限 回调Block
///
/// @note 由 [wantAuthUserSpeaker] 方法直接触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserWantAuthUserSpeakerBlock wantAuthSpeakerBlock;

/// [事件] 希望开关该用户的屏幕共享 回调Block
///
/// @note 由 [wantOpenScreenShare] 方法直接触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserWantOpenScreenShareBlock wantOpenScreenShareBlock;

/// [事件] 希望改变该用户PPT是否在主视图 回调Block
///
/// @note 由 [wantChangeUserPPTToMain] 方法直接触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserWantChangePPTToMainBlock wantChangePPTToMainBlock;


/// 是否为 本地主讲 (即‘第一画面’；可能是本地点击而成为的主讲)
@property (nonatomic, assign) BOOL isLocalMainSpeaker;

#pragma mark 对象
/// RTC渲染画布
///
/// @note 由 PLVLinkMicOnlineUser 内部自创建，用于承载 ’RTC画面‘ 的渲染。
///       由 PLVLinkMicOnlineUser 进行持有、管理，可避免在外部视图中因画面变动，而可能产生反复渲染的问题。
///       判断 rtcView 是否为空无意义，若希望得知 rtcView 此时是否已渲染了 ’RTC画面‘，可读取 [BOOL rtcRendered]。
///       用法：直接将该 rtcView，添加在希望展示 ’RTC画面‘ 的父视图上。
@property (nonatomic, strong, readonly) UIView * rtcView;

#pragma mark 数据
/// 用户聊天室Id
@property (nonatomic, copy, readonly) NSString * userId;

/// 用户连麦Id
@property (nonatomic, copy, readonly) NSString * linkMicUserId;

/// 用户头衔
@property (nonatomic, copy, nullable, readonly) NSString * actor;

/// 用户昵称 (若是本地用户，将自动拼接‘(我)‘后缀)
@property (nonatomic, copy, nullable, readonly) NSString * nickname;

/// 用户头像
@property (nonatomic, copy, nullable, readonly) NSString * avatarPic;

/// 用户类型
@property (nonatomic, assign, readonly) PLVSocketUserType userType;

/// 是否为本地用户 (即‘当前用户自己’)
@property (nonatomic, assign, readonly) BOOL localUser;

/// 原始的 用户数据字典
@property (nonatomic, strong, readonly) NSDictionary * originalUserDict;

#pragma mark 状态
/// 用户的 当前音量 (范围 0.0~1.0)
@property (nonatomic, assign, readonly) CGFloat currentVolume;

/// 用户的 麦克风 当前是否开启
@property (nonatomic, assign, readonly) BOOL currentMicOpen;

/// 用户的 摄像头 当前是否开启 (描述的是，该用户本身 ‘摄像头设备’ 此时是否开启)
@property (nonatomic, assign, readonly) BOOL currentCameraOpen;

/// 用户的 摄像头 当前是否应该显示 (描述的是，根据业务逻辑，该用户的 ‘摄像头画面’ 此时是否应该显示)
@property (nonatomic, assign, readonly) BOOL currentCameraShouldShow;

/// 用户的 摄像头 当前是否前置 (注意：当前业务场景下，决定了此值仅在 [localUser] 为YES，即该对象代表本地用户时，此值有意义)
@property (nonatomic, assign, readonly) BOOL currentCameraFront;

/// 用户的 闪光灯 当前是否开启 (注意：当前业务场景下，决定了此值仅在 [localUser] 为YES，即该对象代表本地用户时，此值有意义)
@property (nonatomic, assign, readonly) BOOL currentCameraTorchOpen;

/// 当前 本地视频预览画面 镜像类型 （该值仅为了同步讲师端开播时的镜像状态，非本地用户，此值无意义）
@property (nonatomic, assign, readonly) PLVBRTCVideoMirrorMode localVideoMirrorMode;

/// 用户的 当前网络状态
@property (nonatomic, assign, readonly) PLVBLinkMicNetworkQuality currentNetworkQuality;

/// rtvView 此时是否已经渲染了 ’RTC画面‘
@property (nonatomic, assign, readonly) BOOL rtcRendered;

/// 用户 当前是否上麦状态 (注意：仅在 [userType] 为Guests时，此值有使用意义；若当前为本地用户，则该值以本地更新为准)
@property (nonatomic, assign, readonly) BOOL currentStatusVoice;

/// 用户 是否被授权画笔（YES授权 NO 取消取消授权）
@property (nonatomic, assign, readonly) BOOL currentBrushAuth;

/// 用户 当前的奖杯数量
@property (nonatomic, assign, readonly) NSInteger currentCupCount;

/// 用户 是否举手（YES举手 NO 取消举手）
@property (nonatomic, assign, readonly) BOOL currentHandUp;

/// 当前用户是否是组长
@property (nonatomic, assign) BOOL groupLeader;

/// 当前用户的流是否已离开房间，默认为NO，为YES时可用于显示占位图（目前该字段只在互动学堂场景讲师身份时有效）
@property (nonatomic, assign) BOOL streamLeaveRoom;

/// 是否为 真实主讲 (代表推流端设置的主讲)
/// 主讲将会拥有第一画面、上传打开课件、翻页PPT、画笔权限
@property (nonatomic, assign, readonly) BOOL isRealMainSpeaker;

/// 是否为 嘉宾移交主讲权限
/// 主讲权限可通过主讲和嘉宾授权，嘉宾授权时需要区分
@property (nonatomic, assign, readonly) BOOL isGuestTransferPermission;

/// 用户的 屏幕共享 当前是否开启
@property (nonatomic, assign, readonly) BOOL currentScreenShareOpen;

/// 用户的连麦状态【当本地为嘉宾用户时有效】
@property (nonatomic, assign, readonly) PLVLinkMicUserLinkMicStatus linkMicStatus;

/// 当前用户的连麦画面是否在放大区域，默认为NO，此时连麦画面在连麦列表上，为YES时表示在放大区域，当前连麦列表需要显示占位图（目前该字段只在互动学堂场景有效）
@property (nonatomic, assign) BOOL inLinkMicZoom;

/// 当前用户已订阅的流类型
@property (nonatomic, assign) PLVBRTCSubscribeStreamSourceType subscribeStreamType;

#pragma mark - [ 方法 ]
#pragma mark 创建

/// 通过 数据字典 创建模型 (适用于远端用户)
+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary;

/// 通过 PLVChatUser 数据模型 创建模型 (适用于远端用户)
+ (instancetype)localUserModelWithChatUser:(PLVChatUser *)chatUser;

/// 通过 传值 创建模型 (适用于本地用户)
+ (instancetype)localUserModelWithUserId:(NSString *)userId linkMicUserId:(NSString *)linkMicUserId nickname:(NSString *)nickname avatarPic:(NSString *)avatarPic userType:(PLVSocketUserType)userType actor:(NSString *)actor;

#pragma mark 状态更新

/// 通过 数据字典 更新用户所有属性
- (void)updateWithDictionary:(NSDictionary *)dictionary;

/// 更新用户的 ‘当前麦克风音量’
///
/// @note 若最终 音量值 有所改变，则将触发 [volumeChangedBlock]；范围 0.0~1.0；
- (void)updateUserCurrentVolume:(CGFloat)volume;

/// 更新用户的 ‘当前麦克风开关状态值’
///
/// @note 若最终 麦克风开关状态值 有所改变，则将触发 [micOpenChangedBlock]；
- (void)updateUserCurrentMicOpen:(BOOL)micOpen;

/// 更新用户的 ‘当前摄像头开关状态值’
///
/// @note 若最终 摄像头开关状态值 有所改变，则将触发 [cameraOpenChangedBlock]、[cameraShouldShowChangedBlock]；
- (void)updateUserCurrentCameraOpen:(BOOL)cameraOpen;

/// 更新用户的 ‘当前摄像头前后置状态值’
///
/// @note 若最终 摄像头前后置状态值 有所改变，则将触发 [cameraFrontChangedBlock]；
- (void)updateUserCurrentCameraFront:(BOOL)cameraFront;

/// 更新用户的 ‘当前闪光灯开关状态值’
///
/// @note 若最终 闪光灯开关状态值 有所改变，则将触发 [cameraTorchOpenChangedBlock]；
- (void)updateUserCurrentCameraTorchOpen:(BOOL)cameraTorchOpen;

/// 更新用户的 ‘当前镜像状态值’ （该值仅为了同步讲师端开播时的镜像状态，非本地用户，此值无意义）
- (void)updateUserLocalVideoMirrorMode:(PLVBRTCVideoMirrorMode)localVideoMirrorMode;

/// 更新用户的 ‘当前网络状态值’
///
/// @note 若最终 网络状态值 有所改变，则将触发 [networkQualityChangedBlock]；
- (void)updateUserCurrentNetworkQuality:(PLVBLinkMicNetworkQuality)networkQuality;

/// 更新用户的 ‘画笔授权状态’
///
/// @note 若学生被授权画笔或者取消授权，则将触发 [brushAuthChangedBlock]；
- (void)updateUserCurrentBrushAuth:(BOOL)brushAuth;

/// 更新用户的 ‘授予奖杯’ 数量
///
/// @note 若学生被授予奖杯，则将触发 [grantCupCountChangedBlock]；
- (void)updateUserCurrentGrantCupCount:(NSInteger)cupCount;

/// 更新用户的 ‘当前举手状态’
///
/// @note 若学生端举手或者取消举手，则将触发 [handUpChangedBlock]；
- (void)updateUserCurrentHandUp:(BOOL)handUp;

/// 更新用户的 ‘当前是否上麦状态值’
///
/// @note 若最终 当前是否上麦状态值 有所改变，则将触发 [currentStatusVoiceChangedBlock]；
///       根据业务逻辑，仅当该用户为 ‘本地用户’ 即 [localUser] 为YES时，该方法调用有效；
- (void)updateUserCurrentStatusVoice:(BOOL)currentStatusVoice;

/// 更新用户的 ‘当前主讲权限’
///
/// @note 若最终 用户当前主讲权限 有所改变，则将触发 [currentSpeakerAuthChangedBlock]；
- (void)updateUserCurrentSpeakerAuth:(BOOL)isRealMainSpeaker;

/// 更新用户的 ‘是否是嘉宾移交的权限’
- (void)updateUserIsGuestTransferPermission:(BOOL)isGuestTransferPermission;

/// 更新用户的 ‘屏幕共享状态’
///
/// @note 若最终 用户屏幕共享状态 有所改变，则将触发 [screenShareOpenChangedBlock]；
- (void)updateUserCurrentScreenShareOpen:(BOOL)screenShareOpen;

/// 更新用户的 ‘当前连麦状态值’
///
/// @note 仅在 本地用户为嘉宾时，调用此方法生效；
- (void)updateUserCurrentLinkMicStatus:(PLVLinkMicUserLinkMicStatus)linkMicStatus;

#pragma mark 通知机制
/// 希望该用户申请加入连麦
///
/// @note 不直接改变该模型内部的任何值；
///       而是作为通知机制，直接触发 [wantRequestJoinLinkMicBlock]，由Block实现方去执行相关逻辑
///
/// @param request 是否希望用户申请加入连麦 (YES:希望请求，NO:取消请求)
- (void)wantUserRequestJoinLinkMic:(BOOL)request;

/// 希望开关该用户的麦克风
///
/// @note 不直接改变该模型内部的任何值；
///       而是作为通知机制，直接触发 [wantOpenMicBlock]，由Block实现方去执行相关逻辑
///
/// @param openMic 是否希望开启该用户的麦克风 (YES:开启，NO:关闭)
- (void)wantOpenUserMic:(BOOL)openMic;

/// 希望开关该用户的摄像头
///
/// @note 不直接改变该模型内部的任何值；
///       而是作为通知机制，直接触发 [wantOpenCameraBlock]，由Block实现方去执行相关逻辑
///
/// @param openCamera 是否希望开启该用户的摄像头 (YES:开启，NO:关闭)
- (void)wantOpenUserCamera:(BOOL)openCamera;

/// 希望切换该用户的前后置摄像头
///
/// @note 不直接改变该模型内部的任何值；
///       而是作为通知机制，直接触发 [wantSwitchFrontCameraBlock]，由Block实现方去执行相关逻辑
///
/// @param frontCamera 是否希望切换该用户的摄像头为前置 (YES:切换为前置，NO:切换为后置)
- (void)wantSwitchUserFrontCamera:(BOOL)frontCamera;

/// 希望挂断该用户的连麦
///
/// @note 不直接改变该模型内部的任何值；
///       而是作为通知机制，直接触发 [wantCloseLinkMicBlock]，由Block实现方去执行相关逻辑
- (void)wantCloseUserLinkMic;

/// 希望授权该用户画笔
///
/// @note 不直接改变该模型内部的任何值；
///       而是作为通知机制，直接触发 [wantBrushAuthBlock]，由Block实现方去执行相关逻辑
/// @param auth 授权用户画笔(YES 授权 NO取消授权)
- (void)wantAuthUserBrush:(BOOL)auth;

/// 希望授予该用户的奖杯
///
/// @note 不直接改变该模型内部的任何值；
///       而是作为通知机制，直接触发 [wantGrantCupBlock]，由Block实现方去执行相关逻辑
- (void)wantGrantUserCup;

/// 希望授权该用户主讲
///
/// @note 不直接改变该模型内部的任何值；
///       而是作为通知机制，直接触发 [wantAuthSpeakerBlock]，由Block实现方去执行相关逻辑
/// @param authSpeaker (YES 授权 NO取消授权)
- (void)wantAuthUserSpeaker:(BOOL)authSpeaker;

/// 希望开关该用户的屏幕共享
///
/// @note 不直接改变该模型内部的任何值；
///       而是作为通知机制，直接触发 [wantOpenScreenShareBlock]，由Block实现方去执行相关逻辑
///
/// @param openScreenShare 是否希望开启该用户的屏幕共享 (YES:开启，NO:关闭)
- (void)wantOpenScreenShare:(BOOL)openScreenShare;

/// 希望切换该用户的PPT位置到主视图
///
/// @note 不直接改变该模型内部的任何值；
///       而是作为通知机制，直接触发 [wantChangePPTToMainBlock]，由Block实现方去执行相关逻辑
///
/// @param pptToMain 是否希望切换该用户的PPT位置到主视图 (YES:在主视图，NO:不切换到主视图)
- (void)wantChangeUserPPTToMain:(BOOL)pptToMain;

#pragma mark 多接收方回调配置
/// 使用 blockKey 添加一个 ’用户模型 即将销毁‘ 回调Block
///
/// @note (1) 仅当您所处于的业务场景里，需要多个模块，同时接收回调时，才需要认识该方法；
///           否则，建议直接使用属性声明中的 [willDeallocBlock]，将更加便捷；
///       (2) 具体回调规则，与 [willDeallocBlock] 相同无异；
///       (3) 无需考虑 ‘什么时机去释放、去解除绑定’，随着 weakBlockKey 销毁，strongBlock 也将自动销毁；
///
/// @param strongBlock ’用户模型 即将销毁‘ 回调Block (强引用)
/// @param weakBlockKey 接收方Key (用于区分接收方；建议直接传 接收方 对象本身；弱引用)
- (void)addWillDeallocBlock:(PLVLinkMicOnlineUserWillDeallocBlock)strongBlock blockKey:(id)weakBlockKey;

/// 使用 blockKey 添加一个 ’麦克风开关状态‘ 改变Block
///
/// @note (1) 仅当您所处于的业务场景里，需要多个模块，同时接收回调时，才需要认识该方法；
///           否则，建议直接使用属性声明中的 [micOpenChangedBlock]，将更加便捷；
///       (2) 具体回调规则，与 [micOpenChangedBlock] 相同无异；
///       (3) 无需考虑 ‘什么时机去释放、去解除绑定’，随着 weakBlockKey 销毁，strongBlock 也将自动销毁；
///
/// @param strongBlock ’麦克风开关状态‘ 改变Block (强引用)
/// @param weakBlockKey 接收方Key (用于区分接收方；建议直接传 接收方 对象本身；弱引用)
- (void)addMicOpenChangedBlock:(PLVLinkMicOnlineUserMicOpenChangedBlock)strongBlock blockKey:(id)weakBlockKey;

/// 使用 blockKey 添加一个 ’摄像头是否应该显示值‘ 改变Block
///
/// @note (1) 仅当您所处于的业务场景里，需要多个模块，同时接收回调时，才需要认识该方法；
///           否则，建议直接使用属性声明中的 [cameraShouldShowChangedBlock]，将更加便捷；
///       (2) 具体回调规则，与 [cameraShouldShowChangedBlock] 相同无异；
///       (3) 无需考虑 ‘什么时机去释放、去解除绑定’，随着 weakBlockKey 销毁，strongBlock 也将自动销毁；
///
/// @param strongBlock ’摄像头是否应该显示值‘ 改变Block (强引用)
/// @param weakBlockKey 接收方Key (用于区分接收方；建议直接传 接收方 对象本身；弱引用)
- (void)addCameraShouldShowChangedBlock:(PLVLinkMicOnlineUserCameraShouldShowChangedBlock)strongBlock blockKey:(id)weakBlockKey;

/// 使用 blockKey 添加一个 ’摄像头前后置状态值‘ 改变Block
///
/// @note (1) 仅当您所处于的业务场景里，需要多个模块，同时接收回调时，才需要认识该方法；
///           否则，建议直接使用属性声明中的 [cameraFrontChangedBlock]，将更加便捷；
///       (2) 具体回调规则，与 [cameraFrontChangedBlock] 相同无异；
///       (3) 无需考虑 ‘什么时机去释放、去解除绑定’，随着 weakBlockKey 销毁，strongBlock 也将自动销毁；
///
/// @param strongBlock ’摄像头前后置状态值‘ 改变Block (强引用)
/// @param weakBlockKey 接收方Key (用于区分接收方；建议直接传 接收方 对象本身；弱引用)
- (void)addCameraFrontChangedBlock:(PLVLinkMicOnlineUserCameraFrontChangedBlock)strongBlock blockKey:(id)weakBlockKey;

/// 使用 blockKey 添加一个 ’闪光灯开关状态‘ 改变Block
///
/// @note (1) 仅当您所处于的业务场景里，需要多个模块，同时接收回调时，才需要认识该方法；
///           否则，建议直接使用属性声明中的 [cameraTorchOpenChangedBlock]，将更加便捷；
///       (2) 具体回调规则，与 [cameraTorchOpenChangedBlock] 相同无异；
///       (3) 无需考虑 ‘什么时机去释放、去解除绑定’，随着 weakBlockKey 销毁，strongBlock 也将自动销毁；
///
/// @param strongBlock ’闪光灯开关状态‘ 改变Block (强引用)
/// @param weakBlockKey 接收方Key (用于区分接收方；建议直接传 接收方 对象本身；弱引用)
- (void)addCameraTorchOpenChangedBlock:(PLVLinkMicOnlineUserCameraTorchOpenChangedBlock)strongBlock blockKey:(id)weakBlockKey;

/// 使用 blockKey 添加一个 ’当前是否上麦状态‘ 改变Block
///
/// @note (1) 仅当您所处于的业务场景里，需要多个模块，同时接收回调时，才需要认识该方法；
///           否则，建议直接使用属性声明中的 [currentStatusVoiceChangedBlock]，将更加便捷；
///       (2) 具体回调规则，与 [currentStatusVoiceChangedBlock] 相同无异；
///       (3) 无需考虑 ‘什么时机去释放、去解除绑定’，随着 weakBlockKey 销毁，strongBlock 也将自动销毁；
///
/// @param strongBlock ’当前是否上麦状态‘ 改变Block (强引用)
/// @param weakBlockKey 接收方Key (用于区分接收方；建议直接传 接收方 对象本身；弱引用)
- (void)addCurrentStatusVoiceChangedBlock:(PLVLinkMicOnlineUserCurrentStatusVoiceChangedBlock)strongBlock blockKey:(id)weakBlockKey;

/// 使用 blockKey 添加一个 ’当前主讲权限‘ 改变Block
///
/// @note (1) 仅当您所处于的业务场景里，需要多个模块，同时接收回调时，才需要认识该方法；
///           否则，建议直接使用属性声明中的 [currentSpeakerAuthChangedBlock]，将更加便捷；
///       (2) 具体回调规则，与 [currentSpeakerAuthChangedBlock] 相同无异；
///       (3) 无需考虑 ‘什么时机去释放、去解除绑定’，随着 weakBlockKey 销毁，strongBlock 也将自动销毁；
///
/// @param strongBlock ’当前主讲权限‘ 改变Block (强引用)
/// @param weakBlockKey 接收方Key (用于区分接收方；建议直接传 接收方 对象本身；弱引用)
- (void)addCurrentSpeakerAuthChangedBlock:(PLVLinkMicOnlineUserCurrentSpeakerAuthChangedBlock)strongBlock blockKey:(id)weakBlockKey;

/// 使用 blockKey 添加一个 ’屏幕共享开关状态‘ 改变Block
///
/// @note (1) 仅当您所处于的业务场景里，需要多个模块，同时接收回调时，才需要认识该方法；
///           否则，建议直接使用属性声明中的 [screenShareOpenChangedBlock]，将更加便捷；
///       (2) 具体回调规则，与 [screenShareOpenChangedBlock] 相同无异；
///       (3) 无需考虑 ‘什么时机去释放、去解除绑定’，随着 weakBlockKey 销毁，strongBlock 也将自动销毁；
///
/// @param strongBlock ’主讲授权状态‘ 改变Block (强引用)
/// @param weakBlockKey 接收方Key (用于区分接收方；建议直接传 接收方 对象本身；弱引用)
- (void)addScreenShareOpenChangedBlock:(PLVLinkMicOnlineUserScreenShareOpenChangedBlock)strongBlock blockKey:(id)weakBlockKey;

@end

NS_ASSUME_NONNULL_END
