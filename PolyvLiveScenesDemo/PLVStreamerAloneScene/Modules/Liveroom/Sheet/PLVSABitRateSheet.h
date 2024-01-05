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

- (void)plvsaBitRateSheet:(PLVSABitRateSheet *)bitRateSheet didSelectStreamQualityLevel:(NSString *)streamQualityLevel;

@end


@interface PLVSABitRateSheet : PLVSABottomSheet

@property (nonatomic, weak) id<PLVSABitRateSheetDelegate> delegate;

/**
  传入清晰度选中对应按钮或传入当前默认的清晰度质量等级
 
 @param currentBitRate 当前清晰度
 @param streamQualityLevel 当前选中的清晰度质量等级
 */
- (void)setupBitRateOptionsWithCurrentBitRate:(PLVResolutionType)currentBitRate streamQualityLevel:(NSString * _Nullable)streamQualityLevel;

@end

NS_ASSUME_NONNULL_END
