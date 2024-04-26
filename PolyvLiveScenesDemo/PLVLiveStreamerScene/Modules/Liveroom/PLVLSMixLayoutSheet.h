//
//  PLVLSMixLayoutSheet.h
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2023/7/25.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVLSSideSheet.h"
#import "PLVRoomData.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLSMixLayoutSheetDelegate <NSObject>

- (void)mixLayoutSheet_didChangeMixLayoutType:(PLVMixLayoutType)type;

@end

@interface PLVLSMixLayoutSheet : PLVLSSideSheet

@property (nonatomic, weak) id<PLVLSMixLayoutSheetDelegate> delegate;


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
