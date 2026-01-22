//
//  PLVECWatchRoomViewController.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/12/1.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVECWatchRoomViewController : UIViewController

/// 是否在iPad上显示全屏按钮
///
/// @note NO-在iPad上竖屏时不显示全屏按钮，YES-显示
///       当项目未适配分屏时，建议设置为YES
@property (nonatomic,assign) BOOL fullScreenButtonShowOnIpad;

/// 切换在线人数/观看热度显示逻辑-直播场景
///
/// @note NO-默认直播场景显示观看热度
///       YES-直播场景显示在线人数
@property (nonatomic,assign) BOOL playTimesLabelUseNewStrategy_live;

/// 切换在线人数/观看热度显示逻辑-回放
///
/// @note NO-默认回放场景显示观看热度
///       YES-回放场景显示在线人数
@property (nonatomic,assign) BOOL playTimesLabelUseNewStrategy_playback;

/// 是否启用1v1悬浮窗布局（默认设置为NO，设置为NO时使用传统布局；设置为YES时当1v1连麦时自动显示悬浮窗）
@property (nonatomic, assign) BOOL enableSeparateLinkMicLayout;

/// 退出并清理当前直播控制器
- (void)exitCleanCurrentLiveController;
/// 退出并清理当前直播控制器，完成后再执行回调
- (void)exitCleanCurrentLiveControllerWithCompletion:(void(^ _Nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
