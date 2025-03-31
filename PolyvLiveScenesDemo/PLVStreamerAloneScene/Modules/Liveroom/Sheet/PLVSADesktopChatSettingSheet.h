//
//  PLVSADesktopChatSettingSheet.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/3/20.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVSABottomSheet.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVSADesktopChatSettingSheet;

@protocol PLVSADesktopChatSettingSheetDelegate <NSObject>

- (void)desktopChatSettingSheet:(PLVSADesktopChatSettingSheet *)sheet didChangeDesktopChatEnable:(BOOL)desktopChatEnable;

@end

@interface PLVSADesktopChatSettingSheet : PLVSABottomSheet

@property (nonatomic, weak) id<PLVSADesktopChatSettingSheetDelegate> delegate;

@property (nonatomic, assign) BOOL desktopChatEnable;

@end

NS_ASSUME_NONNULL_END
