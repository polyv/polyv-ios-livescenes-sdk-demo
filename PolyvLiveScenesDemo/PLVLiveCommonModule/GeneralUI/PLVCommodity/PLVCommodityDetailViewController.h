//
//  PLVCommodityDetailViewController.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/2.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVCommodityDetailViewControllerDelegate <NSObject>

- (void)plvCommodityDetailViewControllerAfterTheBack;

@end

@interface PLVCommodityDetailViewController : UIViewController

- (instancetype)initWithCommodityURL:(NSURL *)URL;

@property (nonatomic, weak) id<PLVCommodityDetailViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
