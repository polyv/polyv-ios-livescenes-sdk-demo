//
//  PLVCastDefinitionModel.m
//  PLVCloudClassDemo
//
//  Created by MissYasiky on 2020/7/17.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVCastDefinitionModel.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVCastDefinitionModel ()

@property (nonatomic, copy) NSString *definition;

@property (nonatomic, copy) NSString *playUrlString;

@property (nonatomic, copy) NSString *m3u8UrlString;

@end

@implementation PLVCastDefinitionModel

- (instancetype)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        if (dict && [dict isKindOfClass:[NSDictionary class]] && [dict count] > 0) {
            _definition = dict[@"definition"] ?: @"未知";
            _playUrlString = dict[@"url"] ?: @"";
            _m3u8UrlString = dict[@"m3u8"] ?: @"";
        }
    }
    return self;
}

@end
