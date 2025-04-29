//
//  PLVVirtualBackgroundUtil.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/4/14.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVVirtualBackgroundUtil.h"

@implementation PLVVirtualBackgroundUtil

+ (UIImage *)imageForResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVVirtualBackgroud" imageName:imageName];
}

#pragma mark - [ Private Method ]

+ (NSBundle *)bundle {
    return [NSBundle bundleForClass:[PLVVirtualBackgroundUtil class]];
}

+ (UIImage *)imageFromBundle:(NSString *)bundleName imageName:(NSString *)imageName {
    NSBundle * resourceBundle = [NSBundle bundleWithPath:[[PLVVirtualBackgroundUtil bundle] pathForResource:bundleName ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

@end
