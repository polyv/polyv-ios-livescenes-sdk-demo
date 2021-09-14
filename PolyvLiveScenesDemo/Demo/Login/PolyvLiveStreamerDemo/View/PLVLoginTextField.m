//
//  PLVLoginTextField.m
//  PLVLiveStreamerDemo
//
//  Created by jiaweihuang on 2021/6/15.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLoginTextField.h"

@implementation PLVLoginTextField

#pragma mark - Override
- (CGRect)clearButtonRectForBounds:(CGRect)bounds {
    return CGRectMake(CGRectGetWidth(self.frame) - 12 - 18, (CGRectGetHeight(self.frame) - 18) / 2, 18, 18);
}

@end
