//
//  PLVECUtils.h
//  PLVLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVECUtils : NSObject

+ (void)showHUDWithTitle:(NSString *)title detail:(NSString *)detail view:(UIView *)view;

+ (void)showHUDWithTitle:(NSString * _Nullable)title detail:(NSString *)detail view:(UIView *)view afterDelay:(CGFloat)delay;

+ (UIImage *)imageForWatchResource:(NSString *)imageName;

@end

NS_ASSUME_NONNULL_END
