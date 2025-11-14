//
//  PLVCommodityExplainedViewController.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/9/18.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVCommodityExplainedViewControllerDelegate <NSObject>

- (void)PLVCommodityExplainedViewControllerAfterTheBack;

@end

@interface PLVCommodityExplainedViewController : UIViewController

- (instancetype)initWithProductId:(NSString *)productId;

@property (nonatomic, weak) id<PLVCommodityExplainedViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
