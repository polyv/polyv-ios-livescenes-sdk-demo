//
//  PLVSAManageCommoditySheet.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2022/10/9.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSABottomSheet.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVSAManageCommoditySheetDelegate <NSObject>

- (NSString *)plvSAManageCommoditySheetCurrentStreamState;

@end

@interface PLVSAManageCommoditySheet : PLVSABottomSheet

@property (nonatomic, weak) id<PLVSAManageCommoditySheetDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
