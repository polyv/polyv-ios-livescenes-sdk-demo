//
//  PLVLSSettingSheet.h
//  PolyvLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/5.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVLSSideSheet.h"
#import "PLVRoomData.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLSSettingSheetProtocol <NSObject>

- (void)settingSheet_didTapLogoutButton;

- (void)settingSheet_didChangeResolution:(PLVLSResolutionType)resolution;

@end

/// 设置弹层
@interface PLVLSSettingSheet : PLVLSSideSheet

/// 当前 清晰度
@property (nonatomic, assign) PLVLSResolutionType resolution;

@property (nonatomic, weak) id<PLVLSSettingSheetProtocol> delegate;

@end

NS_ASSUME_NONNULL_END
