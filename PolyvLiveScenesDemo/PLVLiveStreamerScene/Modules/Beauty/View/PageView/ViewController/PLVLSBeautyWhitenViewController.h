//
//  PLVLSBeautyWhitenViewController.h
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/15.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSBeautyBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN
@class PLVLSBeautyWhitenViewController;
@class PLVLSBeautyCellModel;
@protocol PLVLSBeautyWhitenViewControllerDelegate <NSObject>

- (void)beautyWhitenViewController:(PLVLSBeautyWhitenViewController *)beautyWhitenViewController didSelectItemAtModel:(PLVLSBeautyCellModel *)model;

@end

@interface PLVLSBeautyWhitenViewController : PLVLSBeautyBaseViewController

@property (nonatomic, weak) id<PLVLSBeautyWhitenViewControllerDelegate> delegate;


@end

NS_ASSUME_NONNULL_END
