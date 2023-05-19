//
//  PLVLSMoreInfoSheet.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/4/24.
//  Copyright © 2022 PLV. All rights reserved.
// 更多设置弹层

#import "PLVLSSideSheet.h"

NS_ASSUME_NONNULL_BEGIN
@class PLVLSMoreInfoSheet;
@protocol PLVLSMoreInfoSheetDelegate <NSObject>

- (void)moreInfoSheetDidTapBeautyButton:(PLVLSMoreInfoSheet *)moreInfoSheet;

- (void)moreInfoSheetDidTapResolutionButton:(PLVLSMoreInfoSheet *)moreInfoSheet;

- (void)moreInfoSheetDidTapShareButton:(PLVLSMoreInfoSheet *)moreInfoSheet;

- (void)moreInfoSheetDidTapLogoutButton:(PLVLSMoreInfoSheet *)moreInfoSheet;

- (void)moreInfoSheetDidBadNetworkButton:(PLVLSMoreInfoSheet *)moreInfoSheet;

@end

@interface PLVLSMoreInfoSheet : PLVLSSideSheet

@property (nonatomic, weak) id<PLVLSMoreInfoSheetDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
