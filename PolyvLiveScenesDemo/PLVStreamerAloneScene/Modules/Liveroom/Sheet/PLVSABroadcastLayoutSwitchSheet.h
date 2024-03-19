//
//  PLVSABroadcastLayoutSwitchSheet.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2023/9/18.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVSABottomSheet.h"
#import "PLVRoomData.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVSABroadcastLayoutSwitchSheet;

@protocol PLVSABroadcastLayoutSwitchSheetDelegate <NSObject>

- (void)plvsaBroadcastLayoutSwitchSheet:(PLVSABroadcastLayoutSwitchSheet *)broadcastLayoutLayoutSheet broadcastLayoutButtonClickWithMixLayoutType:(PLVBroadcastLayoutType)type;

@end

@interface PLVSABroadcastLayoutSwitchSheet : PLVSABottomSheet

@property (nonatomic, weak) id<PLVSABroadcastLayoutSwitchSheetDelegate> delegate;

/**
  初始化传入转播布局选中对应按钮
 
 @param currentType 当前混流布局类型
 */
- (void)setupBroadcastLayoutTypeOptionsWithCurrentBroadcastLayoutType:(PLVBroadcastLayoutType)currentType;

/**
 更新混转播局选中对应按钮
 
 @param currentType 当前转播布局类型
 */
- (void)updateBroadcastLayoutType:(PLVBroadcastLayoutType)currentType;

@end

NS_ASSUME_NONNULL_END
