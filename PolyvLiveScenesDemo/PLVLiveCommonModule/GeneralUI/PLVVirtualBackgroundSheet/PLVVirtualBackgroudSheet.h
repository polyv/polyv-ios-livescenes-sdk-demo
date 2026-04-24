//
//  PLVVirtualBackgroudSheet.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/4/10.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVVirtualBackgroudBaseSheet.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVVirtualBackgroudMatType) {
    PLVVirtualBackgroudMatTypeNone = 1,
    PLVVirtualBackgroudMatTypeBlur,
    PLVVirtualBackgroudMatTypeCustomImage
};

@class PLVVirtualBackgroudSheet;

@protocol PLVVirtualBackgroudSheetDelegate <NSObject>

- (void)virtualBackgroudSheet:(PLVVirtualBackgroudSheet *)sheet
                      matType:(PLVVirtualBackgroudMatType)matType
                        image:(nullable UIImage *)matBgImage;

@optional
- (void)virtualBackgroudSheet:(PLVVirtualBackgroudSheet *)sheet didChangeGreenScreenEnabled:(BOOL)enabled;
- (void)virtualBackgroudSheet:(PLVVirtualBackgroudSheet *)sheet didChangeKeyColorWithR:(float)keyColorR g:(float)keyColorG b:(float)keyColorB;
- (void)virtualBackgroudSheet:(PLVVirtualBackgroudSheet *)sheet didChangeSimilarity:(float)similarity;
- (void)virtualBackgroudSheet:(PLVVirtualBackgroudSheet *)sheet didChangeSmoothness:(float)smoothness;
- (void)virtualBackgroudSheet:(PLVVirtualBackgroudSheet *)sheet didChangeSpill:(float)spill;
/// 取色时返回可采样预览区域（默认可不实现）
- (CGRect)previewSamplingFrameInVirtualBackgroudSheet:(PLVVirtualBackgroudSheet *)sheet;
/// 取色时返回预览截图（仅采样视频预览，不采 UI）
- (nullable UIImage *)previewSamplingSnapshotInVirtualBackgroudSheet:(PLVVirtualBackgroudSheet *)sheet;

@end

@interface PLVVirtualBackgroudSheet : PLVVirtualBackgroudBaseSheet

@property (nonatomic, weak) id<PLVVirtualBackgroudSheetDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
