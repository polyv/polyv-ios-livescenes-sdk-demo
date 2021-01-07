//
//  PLVPPTView.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/9/17.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVPPTViewDelegate;

/// PPT视图
@interface PLVPPTView : UIView

/// delegate
@property (nonatomic, weak) id <PLVPPTViewDelegate> delegate;

/// 直播场景中 主讲的PPT 当前是否在主屏
@property (nonatomic, assign, readonly) BOOL mainSpeakerPPTOnMain;

@property (nonatomic, strong, readonly) UIImageView * backgroudImageView;

- (void)setSEIDataWithNewTimestamp:(long)newTimeStamp;

#pragma mark - 回放场景相关方法 [TODO:可能废弃]
/// 加载回放PPT
///
/// @param vid 回放视频的vid
- (void)pptStart:(NSString *)vid;

/// PPT 恢复播放
///
/// @param currentTime 当前播放时间点
- (void)pptPlay:(long)currentTime;

/// PPT 暂停播放
///
/// @param currentTime 当前播放时间点
- (void)pptPause:(long)currentTime;

/// PPT 跳至某个播放点
///
/// @param toTime 需要跳至的播放时间点
- (void)pptSeek:(long)toTime;

@end

@protocol PLVPPTViewDelegate <NSObject>

/// 获取刷新PPT的延迟时间
///
/// @note 不同场景下，PPT的刷新延迟时间不一，需向外部获知当前合适的延迟时间。
///
/// @param pptView PPT视图对象
///
/// @return unsigned int 返回刷新延迟时间 (单位:毫秒)
- (unsigned int)plvPPTViewGetPPTRefreshDelayTime:(PLVPPTView *)pptView;

/// PPT视图 PPT位置需切换
///
/// @note 直播场景中，收到此回调，表示讲师开播的默认PPT位置，或是 表示讲师发出切换PPT位置的指令；
///       回放场景中，将复现讲师对PPT的位置操作。收到此回调时，外部应根据 pptToMain 值相应切换PPT视图位置；
///
/// @param pptView PPT视图对象
/// @param pptToMain PPT是否需要切换至主窗口 (YES:PPT需要切至主窗口 NO:PPT需要切至小窗，视频需要切至主窗口)
- (void)plvPPTView:(PLVPPTView *)pptView changePPTPosition:(BOOL)pptToMain;

#pragma mark - 回放场景回调
/// [回放场景] PPT视图 需要获取视频播放器的当前播放时间点
///
/// @param pptView PPT视图对象
///
/// @return NSTimeInterval 当前播放时间点 (单位:毫秒)
- (NSTimeInterval)plvPPTViewGetPlayerCurrentTime:(PLVPPTView *)pptView;

@end

NS_ASSUME_NONNULL_END
