//
//  PLVECPIPPlaysetPopView.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/2/28.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVECBottomView.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVECPIPPlaysetPopView : PLVECBottomView

/// 离开直播间 小窗启动选项状态
@property (nonatomic, assign) BOOL exitRoomState;
/// 进入app后台 小窗启动选项状态
@property (nonatomic, assign) BOOL enterBackState;

/// 开关事件回调
@property (nonatomic, copy) void(^exitRoomSwitchChanged)(BOOL on);
@property (nonatomic, copy) void(^enterBackSwitchChanged)(BOOL on);


@end

NS_ASSUME_NONNULL_END
