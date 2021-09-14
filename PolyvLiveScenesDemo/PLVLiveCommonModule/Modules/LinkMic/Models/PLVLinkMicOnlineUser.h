//
//  PLVLinkMicOnlineUser.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/8/19.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLinkMicOnlineUser;

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
/// [状态] 用户的 ’当前是否上麦状态‘ 改变Block
typedef void (^PLVLinkMicOnlineUserCurrentStatusVoiceChangedBlock)(PLVLinkMicOnlineUser * onlineUser);
///
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

/// [状态] 用户的 ’当前是否上麦状态‘ 改变Block
///
/// @note 仅在 currentStatusVoice状态值 有改变时会触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) PLVLinkMicOnlineUserCurrentStatusVoiceChangedBlock currentStatusVoiceChangedBlock;

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

/// 是否为 真实主讲 (即‘第一画面’；代表推流端设置的主讲)
@property (nonatomic, assign) BOOL isRealMainSpeaker;

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

/// 用户的 当前网络状态
@property (nonatomic, assign, readonly) PLVBLinkMicNetworkQuality currentNetworkQuality;

/// rtvView 此时是否已经渲染了 ’RTC画面‘
@property (nonatomic, assign, readonly) BOOL rtcRendered;

/// 用户 当前是否上麦状态 (注意：仅在 [userType] 为Guests时，此值有使用意义；若当前为本地用户，则该值以本地更新为准)
@property (nonatomic, assign, readonly) BOOL currentStatusVoice;


#pragma mark - [ 方法 ]
#pragma mark 创建
/// 通过 数据字典 创建模型 (适用于远端用户)
+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary;

/// 通过 传值 创建模型 (适用于本地用户)
+ (instancetype)localUserModelWithUserId:(NSString *)userId linkMicUserId:(NSString *)linkMicUserId nickname:(NSString *)nickname avatarPic:(NSString *)avatarPic userType:(PLVSocketUserType)userType actor:(NSString *)actor;

#pragma mark 状态更新
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

/// 更新用户的 ‘当前网络状态值’
///
/// @note 若最终 网络状态值 有所改变，则将触发 [networkQualityChangedBlock]；
- (void)updateUserCurrentNetworkQuality:(PLVBLinkMicNetworkQuality)networkQuality;

/// 更新用户的 ‘当前是否上麦状态值’
///
/// @note 若最终 当前是否上麦状态值 有所改变，则将触发 [currentStatusVoiceChangedBlock]；
///       根据业务逻辑，仅当该用户为 ‘本地用户’ 即 [localUser] 为YES时，该方法调用有效；
- (void)updateUserCurrentStatusVoice:(BOOL)currentStatusVoice;

#pragma mark 通知机制
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

@end

NS_ASSUME_NONNULL_END
