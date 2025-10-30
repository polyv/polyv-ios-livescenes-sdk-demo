//
//  PLVCastDeviceViewController.h
//  PLVCloudClassDemo
//
//  Created by MissYasiky on 2020/7/23.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVCastDeviceViewController : UIViewController

@property (nonatomic, copy) void (^ selectConnectDeviceHandler)(NSString *deviceName);

@end

NS_ASSUME_NONNULL_END
