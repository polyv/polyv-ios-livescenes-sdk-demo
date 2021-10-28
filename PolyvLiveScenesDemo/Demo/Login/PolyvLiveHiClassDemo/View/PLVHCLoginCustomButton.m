//
//  PLVHCLoginCustomButton.m
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/9/17.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCLoginCustomButton.h"

@implementation PLVHCLoginCustomButton

#pragma mark - [ Override ]

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect buttonFrame = self.bounds;
    CGRect hitFrame = CGRectInset(buttonFrame, -10, -10);
    
    return CGRectContainsPoint(hitFrame, point);
}

@end
