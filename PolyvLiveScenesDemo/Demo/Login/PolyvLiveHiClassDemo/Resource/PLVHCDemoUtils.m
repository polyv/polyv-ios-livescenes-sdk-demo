//
//  PLVHCDemoUtil.m
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/7/1.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCDemoUtils.h"

@implementation PLVHCDemoUtils

#pragma mark - [ Public Method ]
+ (UIImage *)imageForHiClassResource:(NSString *)imageName {
    return [self imageFromBundle:@"HiClass" imageName:imageName];
}

+ (NSDictionary *)plistDictionartForHiClassResource:(NSString *)plistName {
    return [self plistDictionartFromBundle:@"HiClass" plistName:plistName];
}

#pragma mark - [ Private Method ]

+ (NSBundle *)bundle {
    return [NSBundle bundleForClass:[self class]];
}

+ (UIImage *)imageFromBundle:(NSString *)bundleName imageName:(NSString *)imageName {
    NSBundle * resourceBundle = [NSBundle bundleWithPath:[[PLVHCDemoUtils bundle] pathForResource:bundleName ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

+ (NSDictionary *)plistDictionartFromBundle:(NSString *)bundleName plistName:(NSString *)plistName {
    NSBundle * resourceBundle = [NSBundle bundleWithPath:[[PLVHCDemoUtils bundle] pathForResource:bundleName ofType:@"bundle"]];
    NSString *plistPath = [resourceBundle pathForResource:plistName ofType:@"plist"];
    return [[NSDictionary alloc] initWithContentsOfFile:plistPath];
}
@end
