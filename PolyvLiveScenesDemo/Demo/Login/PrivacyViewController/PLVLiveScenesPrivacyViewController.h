//
//  PLVLiveStreamerPrivacyViewController.h
//  PLVCloudClassStreamerDemo
//
//  Created by MissYasiky on 2020/2/4.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVPolicyControllerType) {
    PLVPolicyControllerTypePrivacyPolicy = 0,
    PLVPolicyControllerTypeUserAgreement
};

@interface PLVLiveScenesPrivacyViewController : UIViewController

- (instancetype)initWithUrlString:(NSString *)urlString;

+ (instancetype)controllerWithPolicyControllerType:(PLVPolicyControllerType)type;

@end

NS_ASSUME_NONNULL_END
