//
//  PLVLCLinkMicControlBarProtocol.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/8/31.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - [ Define ]
/// 默认值
#define PLVColor_OnOffButton_BgBlack UIColorFromRGB(@"3E3E4E")
#define PLVColor_OnOffButton_Green UIColorFromRGB(@"49d59b")
#define PLVColor_OnOffButton_Red UIColorFromRGB(@"fd5d5f")
#define PLVColor_OnOffButton_LightGray UIColorFromRGB(@"ededef")
#define PLVColor_OnOffButton_Gray UIColorFromRGB(@"565662")
#define PLVColor_OnOffButton_Clear [UIColor clearColor]

#define PLVLCLinkMicControlBar_ShiftTime 0.3  // 位移时长 (控制栏展开、收起、隐藏过程的位移时长)
#define PLVLCLinkMicControlBar_CommonTime 0.3 // 通用变化时长 (电话图标旋转、文字渐隐动画变更的动画时长)

static const BOOL PLVLCLinkMicControlBarMicDefaultOpen = YES;           // Bar 麦克风按钮 默认开关值
static const BOOL PLVLCLinkMicControlBarCameraDefaultOpen = NO;         // Bar 摄像头按钮 默认开关值
static const BOOL PLVLCLinkMicControlBarSwitchCameraDefaultFront = YES; // Bar 切换前后摄像头按钮 默认前置值

/// 枚举
/// 连麦控制栏 状态 (此状态与 ‘控制栏是否隐藏'状态 互为独立)
typedef NS_ENUM(NSUInteger, PLVLCLinkMicControlBarStatus) {
    PLVLCLinkMicControlBarStatus_Default = 0, // 默认状态，控制栏隐藏
    PLVLCLinkMicControlBarStatus_Open    = 2, // 显示 ‘申请连麦’
    PLVLCLinkMicControlBarStatus_Waiting = 4, // 显示 ‘请求中...’
    PLVLCLinkMicControlBarStatus_Joined  = 6, // 已连麦，显示相关的控制按钮
};

/// 连麦控制栏 类型
typedef NS_ENUM(NSUInteger, PLVLCLinkMicControlBarType) {
    PLVLCLinkMicControlBarType_Video = 0, // 默认状态，视频连麦类型
    PLVLCLinkMicControlBarType_Audio = 1, // 音频连麦类型
};


#pragma mark - [ Abstract Protocol ]
@protocol PLVLCLinkMicControlBarDelegate;

/// PLVLCLinkMicControlBar 连麦控制栏 对象抽象协议
///
/// @note 注意与 PLVLCLinkMicControlBarDelegate 区分；
///       若业务所需，希望自定义一个自家的连麦控制栏，则可遵循 <PLVLCLinkMicControlBarProtocol> 此抽象协议来实现，实现后则自动与其他模块对接起来。
@protocol PLVLCLinkMicControlBarProtocol <NSObject>

@required
#pragma mark 可配置
/// Delegate
@property (nonatomic, weak) id <PLVLCLinkMicControlBarDelegate> delegate;
/// 是否可移动 (默认为 YES)
@property (nonatomic, assign) BOOL canMove;
/// 连麦控制栏类型
@property (nonatomic, assign) PLVLCLinkMicControlBarType barType;

#pragma mark 状态
@property (nonatomic, assign) BOOL switchCameraButtonFront; // ’切换前后置摄像头按钮‘ 的当前前后置状态值 (NO:当前后置 YES:当前前置)
@property (nonatomic, assign) BOOL mediaControlButtonsShow; // 媒体控制按钮当前是否显示
@property (nonatomic, assign) PLVLCLinkMicControlBarStatus status; // 当前连麦控制栏的状态

#pragma mark 数据
@property (nonatomic, assign) CGFloat selfWidth;  // 自身当前的宽度 (目标效果不同时，读取此值得到的数值也相应不同)
@property (nonatomic, assign) CGFloat selfHeight; // 自身当前的高度 (目标效果不同时，读取此值得到的数值也相应不同)

#pragma mark UI
@property (nonatomic, strong) UIView * backgroundView; // 背景视图 (负责展示 圆角效果、控制栏背景色)
@property (nonatomic, strong) UIButton * onOffButton;  // 连麦开关按钮 (申请、挂点连麦的开关按钮)
@property (nonatomic, strong) UILabel * textLabel;     // 当前状态文本框 (负责展示 ‘申请连麦’、‘请求中’)
@property (nonatomic, strong) UIButton * cameraButton; // 摄像头按钮 (点击 将回调 ‘开关摄像头’ 事件)
@property (nonatomic, strong) UIButton * switchCameraButton; // 切换前后摄像头按钮 (点击 将回调 ‘切换前后摄像头’ 事件)
@property (nonatomic, strong) UIButton * micButton;    // 麦克风按钮 (点击 将回调 ‘开关麦克风’ 事件)

#pragma mark 方法
/// 连麦控制栏 切换状态
///
/// 切换过程中，控制栏的样式，将更新至相应的 UI 样式。
///
/// @param status 需要切换至的状态类型
- (void)controlBarStatusSwitchTo:(PLVLCLinkMicControlBarStatus)status;

/// 禁用或启用 控制栏及控制栏上的按钮
///
/// @note 部分场景下，若不希望用户继续点击，而产生未知的错误，可调用此方法以禁用控制栏
///
/// @param enable 启用状态 (YES:启用控制栏 NO:禁用控制栏)
- (void)controlBarUserInteractionEnabled:(BOOL)enable;

/// 刷新控制栏的frame
///
/// @note 此方法将自动根据父视图，对控制栏作frame布局，而无需外部关心控制栏的frame具体布局计算
///       (原因:控制栏的frame计算，与自身当前的各类状态息息相关，外部不容易计算清楚)
- (void)refreshControlBarFrame;

/// 同步其他状态栏的状态
///
/// @param controlBar 其他遵循 <PLVLCLinkMicControlBarProtocol> 抽象协议的状态栏对象
- (void)synchControlBarState:(id<PLVLCLinkMicControlBarProtocol>)controlBar;

- (void)showSelfViewWithAnimation:(BOOL)show;

/// 改变 ’摄像头按钮的 开启关闭UI状态‘
///
/// @note 仅UI变化，不触发按钮对应的回调；
///       当 摄像头按钮的 开启关闭UI状态 被改变时，切换前后置摄像头按钮 的UI状态，也会同步更新；
///
/// @param toCameraOpen ’摄像头按钮’ 的开启关闭目标值
- (void)changeCameraButtonOpenUIWithoutEvent:(BOOL)toCameraOpen;

@optional
#pragma mark UI Optional
@property (nonatomic, strong) UIButton * hideButton;   // 收起按钮 (点击 将收起控制栏)

@end


#pragma mark - [ Delegate ]
/// PLVLCLinkMicControlBar 连麦控制栏 代理协议方法
///
/// @note 注意与 PLVLCLinkMicControlBarProtocol 区分
@protocol PLVLCLinkMicControlBarDelegate <NSObject>

@optional
/// 连麦开关按钮 被点击
///
/// @param bar 控制栏对象
/// @param status 被点击时，控制栏的当前状态
- (void)plvLCLinkMicControlBar:(id<PLVLCLinkMicControlBarProtocol>)bar
onOffButtonClickedCurrentStatus:(PLVLCLinkMicControlBarStatus)status;

/// 摄像头按钮 被点击
///
/// @note openResultBlock 必须被执行回调，否则摄像头按钮将一直处于等待状态无法被点击；若硬件设备开关没有延时，可直接回调 openResultBlock 传参 YES 即可
///
/// @param bar 控制栏对象
/// @param wannaOpen 被点击后，按钮的’目标开关状态’ (代表用户希望的开关状态，YES:希望摄像头开启 NO:希望摄像头关闭)
/// @param openResultBlock 开关结果回调 (硬件设备开关可能存在延时，因此仅在回调 YES 时表示开/关成功，按钮状态才会真正变成希望的状态值；回调 NO 时表示开/关失败，按钮状态将不变化)
- (void)plvLCLinkMicControlBar:(id<PLVLCLinkMicControlBarProtocol>)bar
           cameraButtonClicked:(BOOL)wannaOpen
                    openResult:(void(^)(BOOL openResult))openResultBlock;

/// 切换前后摄像头按钮 被点击
///
/// @param bar 控制栏对象
/// @param front 被点击后，按钮的前后置状态值 (YES:切换至前置摄像头 NO:切换至后置摄像头)
- (void)plvLCLinkMicControlBar:(id<PLVLCLinkMicControlBarProtocol>)bar
     switchCameraButtonClicked:(BOOL)front;

/// 麦克风按钮 被点击
///
/// @param bar 控制栏对象
/// @param open 被点击后，按钮的开关状态值 (YES:麦克风开启 NO:麦克风关闭)
- (void)plvLCLinkMicControlBar:(id<PLVLCLinkMicControlBarProtocol>)bar
        micCameraButtonClicked:(BOOL)open;
@end

NS_ASSUME_NONNULL_END
