//
//  PLVSAMasterPlaybackSettingSheet.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/2/27.
//  Copyright © 2024 PLV. All rights reserved.
// 母流设置弹层

#import "PLVSABottomSheet.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVSAMasterPlaybackSettingSheet;

@protocol PLVSAMasterPlaybackSettingSheetDelegate <NSObject>

- (void)masterPlaybackSettingSheet:(PLVSAMasterPlaybackSettingSheet *)playbackSetting didChangedStartPosition:(NSTimeInterval)startPosition;

@end

@interface PLVSAMasterPlaybackSettingSheet : PLVSABottomSheet

@property (nonatomic, weak) id<PLVSAMasterPlaybackSettingSheetDelegate> delegate;

/// 设置预览视频
/// @param previewUrl 预览视频url
/// @param startPosition 预览视频起播时间
- (void)setupPreviewUrl:(NSString *)previewUrl startPosition:(NSTimeInterval)startPosition;

@end

NS_ASSUME_NONNULL_END
