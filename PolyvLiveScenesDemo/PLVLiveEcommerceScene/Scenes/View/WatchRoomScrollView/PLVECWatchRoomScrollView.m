//
//  PLVECWatchRoomScrollView.m
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/7/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVECWatchRoomScrollView.h"
#import "PLVECHomePageView.h"
#import "PLVECChatroomView.h"
#import "PLVECPlayerContolView.h"

@implementation PLVECWatchRoomScrollView

#pragma mark - [ Override ]

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    for (NSInteger i = self.subviews.count - 1; i >= 0; i--) {
        UIView *grandChildren = self.subviews[i];
        CGPoint grandChildrenPoint = [self convertPoint:point toView:grandChildren];
        UIView *fitView = [grandChildren hitTest:grandChildrenPoint withEvent:event];
        if ([fitView isKindOfClass:[UISlider class]] || [fitView isKindOfClass:PLVECPlayerContolView.class] || [fitView.superview isKindOfClass:UITableViewCell.class]) { //如果响应view是UISlider或者是播放器控制视图，则禁止滑动
             self.scrollEnabled = NO;
         } else {
             self.scrollEnabled = YES;
         }
        if (([fitView isKindOfClass:PLVECChatroomView.class] ||
             [fitView isKindOfClass:PLVECHomePageView.class]) && self.pinMsgPopupView.hidden == NO) {
            for (NSInteger k = self.pinMsgPopupView.subviews.count - 1; k >= 0; k--) {
                UIView *grandChildren = self.pinMsgPopupView.subviews[k];
                if ([grandChildren isKindOfClass:UIButton.class] || [grandChildren isKindOfClass:UIScrollView.class]) {
                    CGPoint grandChildrenPoint = [self convertPoint:point toView:grandChildren];
                    UIView *fitPopupView = [grandChildren hitTest:grandChildrenPoint withEvent:event];
                    if (fitPopupView) {
                        return fitPopupView;
                    }
                }
            }
        }
        if (([fitView isKindOfClass:PLVECChatroomView.class] || [fitView isKindOfClass:PLVECHomePageView.class]) && self.playerDisplayView.alpha > 0) {
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
