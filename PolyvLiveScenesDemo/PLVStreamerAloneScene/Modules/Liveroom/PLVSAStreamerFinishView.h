//
//  PLVSAStreamerFinishView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/5/19.
//  Copyright © 2021 PLV. All rights reserved.
//
// 开播结束视图，覆盖在 PLVSAStreamerViewController 之上

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVSAStreamerFinishView : UIView

/// 直播开始-直播结束 同时更新直播时间文本(需先设置duration计算出结束时间)
@property (nonatomic, assign) NSTimeInterval startTime;
/// 已上课时长，同时时长文本
@property (nonatomic, assign) NSTimeInterval duration;
/// 确定按钮触发回调
@property (nonatomic, copy) void(^finishButtonHandler)(void);

@end

NS_ASSUME_NONNULL_END
