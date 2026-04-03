//
//  PLVSALiveTemplateSheet.h
//  PLVLiveScenesDemo
//
//  Created by Cursor on 2026/3/26.
//

#import "PLVSABottomSheet.h"
#import <PLVLiveScenesSDK/PLVMobileTemplateModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVSALiveTemplateSheet : PLVSABottomSheet

@property (nonatomic, copy) void(^applyHandler)(PLVMobileTemplateModel *model);
@property (nonatomic, copy) dispatch_block_t retryHandler;

- (void)showLoading;
- (void)showError:(NSString *)errorMessage;
- (void)updateTemplateList:(NSArray<PLVMobileTemplateModel *> *)templateList;

@end

NS_ASSUME_NONNULL_END
