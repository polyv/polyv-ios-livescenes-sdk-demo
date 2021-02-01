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

/// RTC在线用户模型
///
/// @note 描述及代表了一位 RTC在线 的用户
@interface PLVLinkMicOnlineUser : NSObject

#pragma mark - [ 属性 ]
#pragma mark 可配置项
/// 用户模型 即将销毁 回调Block
///
/// @note 不保证在主线程回调
@property (nonatomic, copy, nullable) void (^willDeallocBlock) (PLVLinkMicOnlineUser * onlineUser);

/// 用户的 ’音量‘ 改变Block
///
/// @note 仅在 currentVolume 音量值有改变时会触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) void (^volumeChangedBlock) (PLVLinkMicOnlineUser * onlineUser);

/// 用户的 ’麦克风开关状态‘ 改变Block
///
/// @note 仅在 currentOpenMic 开关值有改变时会触发；
///       将在主线程回调；
@property (nonatomic, copy, nullable) void (^micOpenChangedBlock) (PLVLinkMicOnlineUser * onlineUser);

/// 用户的 ’摄像头开关状态‘ 改变Block
///
/// @note 仅在 currentCameraOpen 开关值有改变时会触发；
///       将在主线程回调；
///       对比 [cameraOpenChangedBlock] 更推荐使用 [cameraShouldShowChangedBlock]，后者代表了考虑业务逻辑后的最终结果；
@property (nonatomic, copy, nullable) void (^cameraOpenChangedBlock) (PLVLinkMicOnlineUser * onlineUser);

/// 用户的 ’摄像头是否应该显示值‘ 改变Block
///
/// @note 仅在 currentCameraShouldShow 开关值有改变时会触发；
///       将在主线程回调；
///       对比 [cameraOpenChangedBlock] 更推荐使用 [cameraShouldShowChangedBlock]，后者代表了考虑业务逻辑后的最终结果；
@property (nonatomic, copy, nullable) void (^cameraShouldShowChangedBlock) (PLVLinkMicOnlineUser * onlineUser);

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
/// 用户连麦Id
@property (nonatomic, copy, readonly) NSString * linkMicUserId;

/// 用户头衔
@property (nonatomic, copy, nullable, readonly) NSString * actor;

/// 用户昵称 (若是本地用户，将自动拼接‘(我)‘后缀)
@property (nonatomic, copy, nullable, readonly) NSString * nickname;

/// 用户头像
@property (nonatomic, copy, nullable, readonly) NSString * avatarPic;

/// 用户类型
@property (nonatomic, assign, readonly) PLVLinkMicOnlineUserType userType;

/// 是否为本地用户 (即‘当前用户自己’)
@property (nonatomic, assign, readonly) BOOL localUser;

#pragma mark 状态
/// 用户的 当前音量 (范围 0.0~1.0)
@property (nonatomic, assign, readonly) CGFloat currentVolume;

/// 用户的 麦克风 当前是否开启
@property (nonatomic, assign, readonly) BOOL currentMicOpen;

/// 用户的 摄像头 当前是否开启 (描述的是，该用户本身 ‘摄像头设备’ 此时是否开启)
@property (nonatomic, assign, readonly) BOOL currentCameraOpen;

/// 用户的 摄像头 当前是否应该显示 (描述的是，根据业务逻辑，该用户的 ‘摄像头画面’ 此时是否应该显示)
@property (nonatomic, assign, readonly) BOOL currentCameraShouldShow;

/// rtvView 此时是否已经渲染了 ’RTC画面‘
@property (nonatomic, assign, readonly) BOOL rtcRendered;


#pragma mark - [ 方法 ]
#pragma mark 创建
/// 通过数据字典创建模型
+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary;

+ (instancetype)teacherModelWithUserId:(NSString *)userId;

+ (instancetype)localUserModelWithUserId:(NSString *)userId nickname:(NSString *)nickname avatarPic:(NSString *)avatarPic;

#pragma mark 状态更新
/// 更新用户的 ‘当前连麦音量’
///
/// @note 若 音量值 有所改变，则将触发 [volumeChangedBlock]；范围 0.0~1.0；
- (void)updateUserCurrentVolume:(CGFloat)volume;

/// 更新用户的 ‘当前麦克风开关状态’
///
/// @note 若 麦克风开关状态 有所改变，则将触发 [micOpenChangedBlock]；
- (void)updateUserCurrentMicOpen:(BOOL)micOpen;

/// 更新用户的 ‘当前摄像头开关状态’
///
/// @note 若 摄像头开关状态 有所改变，则将触发 [cameraOpenChangedBlock]、[cameraShouldShowChangedBlock]；
- (void)updateUserCurrentCameraOpen:(BOOL)cameraOpen;

@end

NS_ASSUME_NONNULL_END
