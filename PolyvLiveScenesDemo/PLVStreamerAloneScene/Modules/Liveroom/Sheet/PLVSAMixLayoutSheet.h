//
//  PLVSAMixLayoutSheet.h
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2023/7/25.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVSABottomSheet.h"
#import "PLVRoomData.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVSAMixLayoutSheet;

@protocol PLVSAMixLayoutSheetDelegate <NSObject>

- (void)plvsaMixLayoutSheet:(PLVSAMixLayoutSheet *)mixLayoutSheet mixLayoutButtonClickWithMixLayoutType:(PLVMixLayoutType)type;

@end

@interface PLVSAMixLayoutSheet : PLVSABottomSheet

@property (nonatomic, weak) id<PLVSAMixLayoutSheetDelegate> delegate;

/**
  初始化传入混流布局选中对应按钮
 
 @param currentType 当前混流布局类型
 */
- (void)setupMixLayoutTypeOptionsWithCurrentMixLayoutType:(PLVMixLayoutType)currentType;

/**
 更新混流布局选中对应按钮
 
 @param currentType 当前混流布局类型
 */
- (void)updateMixLayoutType:(PLVMixLayoutType)currentType;

@end

NS_ASSUME_NONNULL_END
