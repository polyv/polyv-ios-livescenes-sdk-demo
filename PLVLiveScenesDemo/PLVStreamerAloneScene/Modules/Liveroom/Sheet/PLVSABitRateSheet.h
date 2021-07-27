//
//  PLVSABitRateSheet.h
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/5/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSABottomSheet.h"
#import "PLVRoomDataManager.h"


NS_ASSUME_NONNULL_BEGIN

@class PLVSABitRateSheet;

@protocol PLVSABitRateSheetDelegate <NSObject>

- (void)plvsaBitRateSheet:(PLVSABitRateSheet *)bitRateSheet bitRateButtonClickWithBitRate:(PLVResolutionType)bitRate;

@end


@interface PLVSABitRateSheet : PLVSABottomSheet

@property (nonatomic, weak) id<PLVSABitRateSheetDelegate> delegate;

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight;

/**
  传入清晰度选中对应按钮
 
 @param currentBitRate 当前清晰度
 */
- (void)setupBitRateOptionsWithCurrentBitRate:(PLVResolutionType)currentBitRate;


@end

NS_ASSUME_NONNULL_END
