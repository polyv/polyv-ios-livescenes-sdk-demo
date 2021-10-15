//
//  PLVECWatchRoomScrollView.m
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/7/19.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVECWatchRoomScrollView.h"
#import "PLVECHomePageView.h"
#import "PLVECChatroomView.h"

@implementation PLVECWatchRoomScrollView

#pragma mark - [ Override ]

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    for (NSInteger i = self.subviews.count - 1; i >= 0; i--) {
        UIView *grandChildren = self.subviews[i];
        CGPoint grandChildrenPoint = [self convertPoint:point toView:grandChildren];
        UIView *fitView = [grandChildren hitTest:grandChildrenPoint withEvent:event];
        if ([fitView isKindOfClass:PLVECChatroomView.class] || [fitView isKindOfClass:PLVECHomePageView.class]) {
            for (NSInteger k = self.playerDisplayView.subviews.count - 1; k >= 0; k--) {
                UIView *grandChildren = self.playerDisplayView.subviews[k];
                CGPoint grandChildrenPoint = [self convertPoint:point toView:grandChildren];
                fitView = [grandChildren hitTest:grandChildrenPoint withEvent:event];
                if (fitView) {
                    return fitView;
                }
            }
        }
        if (fitView) {
            return fitView;
        }
    }
    return self;
}



@end
