//
//  PLVBroadcastNotificationsManager.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/7/4.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^PLVBroadcastNotificationListenerBlock)(void);

@interface PLVBroadcastNotificationsManager : NSObject

- (void)sendNotificationWithIdentifier:(nullable NSString *)identifier;

- (void)listenForMessageWithIdentifier:(nullable NSString *)identifier
                              listener:(PLVBroadcastNotificationListenerBlock)listener;

@end

NS_ASSUME_NONNULL_END
