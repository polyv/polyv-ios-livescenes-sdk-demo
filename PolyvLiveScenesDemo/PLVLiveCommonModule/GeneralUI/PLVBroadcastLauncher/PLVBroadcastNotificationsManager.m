//
//  PLVBroadcastNotificationsManager.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/7/4.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVBroadcastNotificationsManager.h"

static NSString * const PLVDarwinBroadcastNotificationName = @"PLVDarwinBroadcastNotificationName";

@interface PLVBroadcastNotificationsManager()

@property (nonatomic, strong) NSMutableDictionary *listenerBlocks;

@end

@implementation PLVBroadcastNotificationsManager

#pragma mark - [ Life Period ]
- (instancetype)init {
    if ((self = [super init])) {
        _listenerBlocks = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMessageNotification:)
                                                     name:PLVDarwinBroadcastNotificationName
                                                   object:self];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    CFNotificationCenterRef const center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterRemoveEveryObserver(center, (__bridge const void *)(self));
}

#pragma mark - [ Public Methods ]
- (void)sendNotificationWithIdentifier:(nullable NSString *)identifier {
    CFNotificationCenterRef const center = CFNotificationCenterGetDarwinNotifyCenter();
    CFDictionaryRef const userInfo = NULL;
    BOOL const deliverImmediately = YES;
    CFStringRef str = (__bridge CFStringRef)identifier;
    CFNotificationCenterPostNotification(center, str, NULL, userInfo, deliverImmediately);
}

- (void)listenForMessageWithIdentifier:(nullable NSString *)identifier listener:(PLVBroadcastNotificationListenerBlock)listener {
    if (identifier != nil) {
        if (listener) {
            [self.listenerBlocks setValue:listener forKey:identifier];
        }
        [self registerForNotificationsWithIdentifier:identifier];
    }
}

#pragma mark - [ Private Methods ]
- (void)registerForNotificationsWithIdentifier:(nullable NSString *)identifier {
    [self unregisterForNotificationsWithIdentifier:identifier];

    CFNotificationCenterRef const center = CFNotificationCenterGetDarwinNotifyCenter();
    CFStringRef str = (__bridge CFStringRef)identifier;
    CFNotificationCenterAddObserver(center,
                                    (__bridge const void *)(self),
                                    plvDarwinNotificationCallback,
                                    str,
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
}

- (void)unregisterForNotificationsWithIdentifier:(nullable NSString *)identifier {
    CFNotificationCenterRef const center = CFNotificationCenterGetDarwinNotifyCenter();
    CFStringRef str = (__bridge CFStringRef)identifier;
    CFNotificationCenterRemoveObserver(center,
                                       (__bridge const void *)(self),
                                       str,
                                       NULL);
}

void plvDarwinNotificationCallback(CFNotificationCenterRef center,
                               void * observer,
                               CFStringRef name,
                               void const * object,
                               CFDictionaryRef userInfo) {
    NSString *identifier = (__bridge NSString *)name;
    NSObject *sender = (__bridge NSObject *)(observer);
    [[NSNotificationCenter defaultCenter] postNotificationName:PLVDarwinBroadcastNotificationName
                                                        object:sender
                                                      userInfo:@{@"identifier" : identifier}];
}

- (id)listenerBlockForIdentifier:(NSString *)identifier {
    return [self.listenerBlocks valueForKey:identifier];
}

- (void)notifyListenerWithIdentifier:(nullable NSString *)identifier {
    PLVBroadcastNotificationListenerBlock listenerBlock = [self listenerBlockForIdentifier:identifier];
    if (listenerBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            listenerBlock();
        });
    }
}

#pragma mark Getter
- (NSMutableDictionary *)listenerBlocks {
    if (!_listenerBlocks) {
        _listenerBlocks = [NSMutableDictionary dictionary];
    }
    return _listenerBlocks;
}

#pragma mark - [ Event ]
#pragma mark Notification
- (void)didReceiveMessageNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSString *identifier = [userInfo valueForKey:@"identifier"];
    if (identifier != nil) {
        [self notifyListenerWithIdentifier:identifier];
    }
}

@end
