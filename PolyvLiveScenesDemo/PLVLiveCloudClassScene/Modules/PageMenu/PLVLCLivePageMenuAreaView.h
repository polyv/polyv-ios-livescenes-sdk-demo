//
//  PLVLCMenuAreaView.h
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/7/23.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLCChatViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVLCLivePageMenuType) {
    PLVLCLivePageMenuTypeUnknown = -1,  // 未知
    PLVLCLivePageMenuTypeDesc = 0,      // 直播介绍
    PLVLCLivePageMenuTypeChat,          // 互动聊天
    PLVLCLivePageMenuTypeQuiz,          // 咨询提问
    PLVLCLivePageMenuTypeTuwen,         // 图文直播
    PLVLCLivePageMenuTypeText,          // 自定义图文直播
    PLVLCLivePageMenuTypeQA,            // 问答功能
    PLVLCLivePageMenuTypeIframe,        // 推广外链
};

/// 将后端返回的menu字符串转化为枚举值PLVLCLivePageMenuType
PLVLCLivePageMenuType PLVLCMenuTypeWithMenuTypeString(NSString *menuString);

@protocol PLVLCLivePageMenuAreaViewDelegate;

@interface PLVLCLivePageMenuAreaView : UIView

@property (nonatomic, weak) id <PLVLCLivePageMenuAreaViewDelegate> delegate;

/// 互动聊天页，退出直播时需要clearResource，切换全屏时需要提取聊天室的点赞Button
@property (nonatomic, strong) PLVLCChatViewController *chatVctrl;

/// 初始化方法
/// @param liveRoom 直播间控制器，传递给互动聊天室用于弹出拍照、相册控制器
- (instancetype)initWithLiveRoom:(UIViewController *)liveRoom;

/// 直播状态改变时调用，调用该方法自动将 inPlaybackScene 置为 NO
- (void)updateliveStatue:(BOOL)living;

@end

@protocol PLVLCLivePageMenuAreaViewDelegate <NSObject>

/// 获取当前播放进度
/// @param pageMenuAreaView 菜单视图
- (NSTimeInterval)plvLCLivePageMenuAreaViewGetPlayerCurrentTime:(PLVLCLivePageMenuAreaView *)pageMenuAreaView;

/// 跳转到指定时间
/// @param pageMenuAreaView 菜单视图
/// @param time 跳转指定时间
- (void)plvLCLivePageMenuAreaView:(PLVLCLivePageMenuAreaView *)pageMenuAreaView seekTime:(NSTimeInterval)time;

@end
NS_ASSUME_NONNULL_END
