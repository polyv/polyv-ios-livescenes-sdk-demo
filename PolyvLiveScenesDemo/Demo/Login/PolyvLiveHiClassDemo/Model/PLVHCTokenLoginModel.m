//
//  PLVHCTokenLoginModel.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/9/6.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCTokenLoginModel.h"

@implementation PLVHCTokenLoginModel

#pragma mark - NSCoding,NSCopying

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.token forKey:@"token"];
    [aCoder encodeObject:self.userId forKey:@"userId"];
    [aCoder encodeObject:self.nickname forKey:@"nickname"];
    [aCoder encodeObject:self.lessonId forKey:@"lessonId"];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.token = [aDecoder decodeObjectForKey:@"token"];
        self.userId = [aDecoder decodeObjectForKey:@"userId"];
        self.nickname = [aDecoder decodeObjectForKey:@"nickname"];
        self.lessonId = [aDecoder decodeObjectForKey:@"lessonId"];
    }
    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return self;
}

@end
