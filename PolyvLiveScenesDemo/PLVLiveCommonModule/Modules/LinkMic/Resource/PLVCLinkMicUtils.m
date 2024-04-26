//
//  PLVCLinkMicUtils.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/5/20.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVCLinkMicUtils.h"

@implementation PLVCLinkMicUtils

#pragma mark - [ Public Methods ]
+ (NSURL *)URLForCLinkMicResource:(NSString *)resourceName {
    NSBundle *bundle = [NSBundle bundleWithPath:[[PLVCLinkMicUtils bundle] pathForResource:@"PLVCLinkMic" ofType:@"bundle"]];
    NSURL *resourceURL = [bundle URLForResource:resourceName withExtension:nil];
    return resourceURL;
}

#pragma mark - [ Private Methods ]
+ (NSBundle *)bundle {
    return [NSBundle bundleForClass:[PLVCLinkMicUtils class]];
}

@end
