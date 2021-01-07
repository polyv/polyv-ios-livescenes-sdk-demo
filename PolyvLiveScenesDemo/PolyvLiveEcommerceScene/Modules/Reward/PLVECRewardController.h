//
//  PLVECRewardController.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/29.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PLVECRewardView.h"
#import "PLVRoomUser.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVECRewardController;
@protocol PLVECRewardControllerDelegate <NSObject>

- (void)showGiftAnimation:(NSString *)userName giftName:(NSString *)giftName giftType:(NSString *)giftType;

@end

@interface PLVECRewardController : NSObject

@property (nonatomic, strong) PLVECRewardView *view;

@property (nonatomic, strong) PLVRoomUser *roomUser;

@property (nonatomic, weak) id<PLVECRewardControllerDelegate> delegate;

//- (void)receiveCustomMessage:(NSDictionary *)jsonDict;

- (void)hiddenView:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
