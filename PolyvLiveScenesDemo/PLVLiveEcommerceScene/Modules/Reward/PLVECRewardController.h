//
//  PLVECRewardController.h
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/6/29.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVECRewardView.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVECRewardController : NSObject

@property (nonatomic, strong) PLVECRewardView *view;

@property (nonatomic, copy) void(^didSendGift)(NSString *giftName, NSString *giftType);

- (void)hiddenView:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
