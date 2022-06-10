//
//  PLVSABeautyWhitenViewController.h
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/15.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSABeautyBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN
@class PLVSABeautyWhitenViewController;
@class PLVSABeautyCellModel;
@protocol PLVSABeautyWhitenViewControllerDelegate <NSObject>

- (void)beautyWhitenViewController:(PLVSABeautyWhitenViewController *)beautyWhitenViewController didSelectItemAtModel:(PLVSABeautyCellModel *)model;

@end

@interface PLVSABeautyWhitenViewController : PLVSABeautyBaseViewController

@property (nonatomic, weak) id<PLVSABeautyWhitenViewControllerDelegate> delegate;


@end

NS_ASSUME_NONNULL_END
