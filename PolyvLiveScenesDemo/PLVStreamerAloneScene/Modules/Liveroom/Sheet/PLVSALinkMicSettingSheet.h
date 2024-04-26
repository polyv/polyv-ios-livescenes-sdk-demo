//
//  PLVSALinkMicSettingSheet.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/4/9.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVSABottomSheet.h"

NS_ASSUME_NONNULL_BEGIN
@protocol PLVSALinkMicSettingSheetDelegate <NSObject>

- (void)plvsaLinkMicSettingSheet_wannaChangeLinkMicType:(BOOL)linkMicOnAudio;

@end

@interface PLVSALinkMicSettingSheet : PLVSABottomSheet

@property (nonatomic, weak) id<PLVSALinkMicSettingSheetDelegate> delegate;

/**
  更新选中连麦按钮
 @param linkMicOnAudio 连麦类型 (YES:音频连麦 NO:视频连麦)
 */
- (void)updateLinkMicType:(BOOL)linkMicOnAudio;

@end

NS_ASSUME_NONNULL_END
