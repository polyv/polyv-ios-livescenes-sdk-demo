//
//  PLVECUtils.m
//  PolyvLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECUtils.h"

@implementation PLVECUtils

+ (NSBundle *)watchBundle {
    /*
     使用 [NSBundle bundleForClass:[PLVECUtils class]] 而非 [NSBundle mainBundle] 的原因在于：
     如果是将 watch 文件夹打包进 framework，也能读到资源文件
     */
    return [NSBundle bundleForClass:[PLVECUtils class]];
}

+ (NSBundle *)watchResource {
    return [NSBundle bundleWithPath:[[PLVECUtils watchBundle] pathForResource:@"WatchResource" ofType:@"bundle"]];
}

+ (UIImage *)imageForWatchResource:(NSString *)imageName {
    return [UIImage imageNamed:imageName inBundle:[self watchResource] compatibleWithTraitCollection:nil];
}

@end
