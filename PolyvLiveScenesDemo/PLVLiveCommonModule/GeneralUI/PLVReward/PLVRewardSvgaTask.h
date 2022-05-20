//
//  PLVRewardSvgaTask.h
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/8/31.
//  Copyright © 2021 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVRewardSvgaTask : NSOperation

@property (nonatomic, weak) UIView *superView;
@property (nonatomic, strong) NSString *rewardImageUrl;

@end

NS_ASSUME_NONNULL_END
