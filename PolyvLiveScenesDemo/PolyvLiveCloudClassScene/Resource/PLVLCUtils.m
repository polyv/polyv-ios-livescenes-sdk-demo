//
//  PLVLCUtils.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/8/7.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCUtils.h"

@implementation PLVLCUtils

#pragma mark - [ Public Methods ]
+ (UIImage *)imageForLiveRoomResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVLiveRoom" imageName:imageName];
}

+ (UIImage *)imageForLinkMicResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVLinkMic" imageName:imageName];
}

+ (UIImage *)imageForMediaResource:(NSString *)imageName{
    return [self imageFromBundle:@"PLVMedia" imageName:imageName];
}

+ (UIImage *)imageForMenuResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVMenu" imageName:imageName];
}

+ (UIImage *)imageForChatroomResource:(NSString *)imageName {
    return [self imageFromBundle:@"PLVChatroom" imageName:imageName];
}

#pragma mark - [ Private Methods ]
+ (NSBundle *)LCBundle {
    return [NSBundle bundleForClass:[PLVLCUtils class]];
}

+ (UIImage *)imageFromBundle:(NSString *)bundleName imageName:(NSString *)imageName{
    NSBundle * resourceBundle = [NSBundle bundleWithPath:[[PLVLCUtils LCBundle] pathForResource:bundleName ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

@end
