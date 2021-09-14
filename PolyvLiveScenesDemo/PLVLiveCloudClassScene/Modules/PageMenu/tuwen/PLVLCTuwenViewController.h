//
//  PLVLCTuwenViewController.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLCTuwenDelegate <NSObject>

- (void)clickTuwenImage:(BOOL)showImage;

@end

@interface PLVLCTuwenViewController : UIViewController

@property (nonatomic, weak) id<PLVLCTuwenDelegate> delegate;

- (instancetype)initWithChannelId:(NSNumber *)channelId;

- (void)reconnect;

@end

NS_ASSUME_NONNULL_END
