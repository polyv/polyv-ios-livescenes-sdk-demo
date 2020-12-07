//
//  PLVLinkMicOnlineUser.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/8/19.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 连麦用户类型
///
/// 连麦用户类型的对应数值，决定了该类型用户的权重，数值越大，权重越高，即业务上排名越靠前
///
/// @note 注意：
/// 1、不能直接使用数值来赋值使用，因数值可能随业务变化而改变
/// 2、数值越大，排名越前，若业务改变，可直接调整枚举顺序，来决定用户的权重及排序
typedef NS_ENUM(NSUInteger, PLVLinkMicOnlineUserType) {
    PLVLinkMicOnlineUserType_Unknown   = 0, // 其他
    PLVLinkMicOnlineUserType_Slice     = 2, // 云课堂学员
    PLVLinkMicOnlineUserType_Student   = 4, // 学生
    PLVLinkMicOnlineUserType_Viewer    = 6, // 参与者（特邀观众）
    PLVLinkMicOnlineUserType_Guests    = 8, // 嘉宾
    PLVLinkMicOnlineUserType_Teacher   = 10,// 讲师
};

@class PLVLinkMicOnlineUser;

/// 连麦用户即将销毁回调Block
typedef void(^PLVLinkMicOnlineUserWillDeallocBlock)(PLVLinkMicOnlineUser * onlineUser);

/// 连麦用户的当前连麦音量改变Block
typedef void(^PLVLinkMicOnlineUserCurrentVolumeChangedBlock)(PLVLinkMicOnlineUser * onlineUser);

/// 连麦用户的麦克风开启状态改变Block
typedef void(^PLVLinkMicOnlineUserCurrentMicOpenChangedBlock)(PLVLinkMicOnlineUser * onlineUser);

/// 连麦用户的摄像头开启状态改变Block
typedef void(^PLVLinkMicOnlineUserCurrentCameraOpenChangedBlock)(PLVLinkMicOnlineUser * onlineUser);

/// 连麦用户模型
@interface PLVLinkMicOnlineUser : NSObject

/// 用户连麦Id
@property (nonatomic, copy, readonly) NSString * linkMicUserId;

/// 用户是否为主讲
@property (nonatomic, assign) BOOL mainSpeaker;

/// 是否为本地用户(自己)
@property (nonatomic, assign, readonly) BOOL localUser;

/// Rtc渲染画面视图
///
/// @note
/// 由 PLVLinkMicOnlineUser 内部自创建，用于承载RTC连麦画面的渲染。
/// 由 PLVLinkMicOnlineUser 进行持有、管理，可避免在外部视图中，因画面变动而可能需要反复渲染的问题。
/// 判断 rtcView 是否为空不反映问题，如需得知 rtcView 是否已渲染 Rtc画面，可参考 [BOOL rtcRendered]。
/// 可直接将该视图，添加在希望展示 ’rtc连麦画面‘ 的视图上
@property (nonatomic, strong, readonly) UIView * rtcView;

/// Rtc画面，是否已经渲染在 rtcView 上
@property (nonatomic, assign, readonly) BOOL rtcRendered;

#pragma mark 数据
/// 用户头衔
@property (nonatomic, copy, nullable) NSString * actor;

/// 用户昵称
@property (nonatomic, copy, nullable) NSString * nickname;

/// 用户头像
@property (nonatomic, copy, nullable) NSString * avatarPic;

/// 用户类型
@property (nonatomic, assign) PLVLinkMicOnlineUserType userType;

#pragma mark 状态
/// 连麦用户即将销毁回调Block
@property (nonatomic, strong, nullable) PLVLinkMicOnlineUserWillDeallocBlock willDeallocBlock;

/// 用户麦克风 当前是否开启
@property (nonatomic, assign, readonly) BOOL currentMicOpen;

/// 连麦用户的麦克风 开关状态改变Block
///
/// @note 并非每一次设置currentOpenMic都将触发此Block，仅在开关值有改变时会触发；将在主线程回调
@property (nonatomic, strong, nullable) PLVLinkMicOnlineUserCurrentMicOpenChangedBlock micOpenChangedBlock;

/// 用户摄像头 当前是否开启
@property (nonatomic, assign, readonly) BOOL currentCameraOpen;

/// 连麦用户的摄像头 开关状态改变Block
///
/// @note 并非每一次设置currentCameraOpen都将触发此Block，仅在开关值有改变时会触发；将在主线程回调
@property (nonatomic, strong, nullable) PLVLinkMicOnlineUserCurrentCameraOpenChangedBlock cameraOpenChangedBlock;

/// 用户的当前连麦音量
///
/// @note 范围 0.0~1.0
@property (nonatomic, assign, readonly) CGFloat currentVolume;

/// 连麦用户的当前连麦音量改变Block
///
/// @note 并非每一次设置currentVolume都将触发此Block，仅在音量值有改变时会触发；将在主线程回调
@property (nonatomic, strong, nullable) PLVLinkMicOnlineUserCurrentVolumeChangedBlock volumeChangedBlock;


#pragma mark - [ 方法 ]
#pragma mark 创建
/// 通过数据字典创建模型
+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary;
+ (instancetype)teacherModelWithUserId:(NSString *)userId;

+ (instancetype)localUserModelWithUserId:(NSString *)userId nickname:(NSString *)nickname avatarPic:(NSString *)avatarPic;

#pragma mark 数据管理
/// 更新用户的当前连麦音量
///
/// @note 若音量值有所改变，则将触发 volumeChangedBlock
- (void)updateUserCurrentVolume:(CGFloat)volume;

- (void)updateUserCurrentMicOpen:(BOOL)open;

- (void)updateUserCurrentCameraOpen:(BOOL)open;


@end

NS_ASSUME_NONNULL_END
