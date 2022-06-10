//
//  PLVLCDownloadBottomSheet.h
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/5/25.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVLCBottomSheet.h"
#import "PLVRoomData.h"

NS_ASSUME_NONNULL_BEGIN

/// 下载视频的底部弹窗sheet
@interface PLVLCDownloadBottomSheet : PLVLCBottomSheet

@property (nonatomic, copy) void (^clickDownloadListBlock)(void);

/// 更新回放视频信息
- (void)updatePlaybackInfoWithData:(PLVRoomData *)roomData;

@end

NS_ASSUME_NONNULL_END
