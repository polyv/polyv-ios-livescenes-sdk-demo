//
//  PLVLSResolutionSheet.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/5.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSSideSheet.h"
#import "PLVRoomData.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLSResolutionSheetDelegate <NSObject>

- (void)settingSheet_didChangeResolution:(PLVResolutionType)resolution;

- (void)settingSheet_didSelectStreamQualityLevel:(NSString *)streamQualityLevel;

@end

/// 清晰度弹层
@interface PLVLSResolutionSheet : PLVLSSideSheet

/// 当前 清晰度
@property (nonatomic, assign) PLVResolutionType resolution;

@property (nonatomic, weak) id<PLVLSResolutionSheetDelegate> delegate;

/// 推流视频模版默认清晰度（已区分讲师和嘉宾）
@property (nonatomic, copy, readonly) NSString *defaultQualityLevel;

@end

NS_ASSUME_NONNULL_END
