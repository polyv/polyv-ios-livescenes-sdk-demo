//
//  PLVLSLinkMicSettingSheet.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/4/2.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVLSSideSheet.h"

NS_ASSUME_NONNULL_BEGIN
@protocol PLVLSLinkMicSettingSheetDelegate <NSObject>

- (void)plvlsLinkMicSettingSheet_wannaChangeLinkMicType:(BOOL)linkMicOnAudio;

@end

@interface PLVLSLinkMicSettingSheet : PLVLSSideSheet

@property (nonatomic, weak) id<PLVLSLinkMicSettingSheetDelegate> delegate;

/**
  更新选中连麦按钮
 @param linkMicOnAudio 连麦类型 (YES:音频连麦 NO:视频连麦)
 */
- (void)updateLinkMicType:(BOOL)linkMicOnAudio;

@end

NS_ASSUME_NONNULL_END
