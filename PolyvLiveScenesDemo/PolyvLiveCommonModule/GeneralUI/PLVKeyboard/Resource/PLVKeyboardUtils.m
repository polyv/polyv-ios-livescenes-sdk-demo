//
//  PLVKeyboardUtils.m
//  PolyvCloudClassDemo
//
//  Created by Lincal on 2020/5/19.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVKeyboardUtils.h"

@implementation PLVKeyboardUtils

+ (UIImage *)imageForKeyboardResource:(NSString *)imageName {
    NSBundle *bundle = [NSBundle bundleForClass:[PLVKeyboardUtils class]];
    NSBundle *resourceBundle = [NSBundle bundleWithPath:[bundle pathForResource:@"PLVKeyboard" ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

@end
