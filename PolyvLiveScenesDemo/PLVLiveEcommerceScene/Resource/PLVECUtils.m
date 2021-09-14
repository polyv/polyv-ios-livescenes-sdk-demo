//
//  PLVECUtils.m
//  PLVLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECUtils.h"
#import <PLVFoundationSDK/PLVProgressHUD.h>

@implementation PLVECUtils

#pragma mark - [ Public Methods ]

+ (void)showHUDWithTitle:(NSString *)title detail:(NSString *)detail view:(UIView *)view {
    NSLog(@"HUD info title:%@,detail:%@",title,detail);
    if (view == nil) {
        return;
    }
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = PLVProgressHUDModeText;
    hud.label.text = title;
    hud.detailsLabel.text = detail;
    [hud hideAnimated:YES afterDelay:2.0];
}

+ (UIImage *)imageForWatchResource:(NSString *)imageName {
    return [self imageFromBundle:@"WatchResource" imageName:imageName];
}

#pragma mark - [ Private Methods ]

+ (NSBundle *)ECBundle {
    return [NSBundle bundleForClass:[PLVECUtils class]];
}

+ (UIImage *)imageFromBundle:(NSString *)bundleName imageName:(NSString *)imageName{
    NSBundle * resourceBundle = [NSBundle bundleWithPath:[[PLVECUtils ECBundle] pathForResource:bundleName ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

@end
