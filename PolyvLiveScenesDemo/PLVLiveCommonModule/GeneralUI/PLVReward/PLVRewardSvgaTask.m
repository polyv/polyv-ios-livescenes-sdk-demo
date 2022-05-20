//
//  PLVRewardSvgaTask.m
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/8/31.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVRewardSvgaTask.h"
#import "PLVRewardSvgaView.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>


@implementation PLVRewardSvgaTask

@synthesize executing = _executing;
@synthesize finished = _finished;


- (void)start{
    if (!self.isExecuting) self.executing = YES;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf showSvgaView];
    });
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)showSvgaView {
    PLVRewardSvgaView *svgaView = [[PLVRewardSvgaView alloc] init];
    // 横屏
    if (CGRectGetWidth(self.superView.frame) > CGRectGetHeight(self.superView.frame)) {
        svgaView.frame = CGRectMake((CGRectGetWidth(self.superView.frame) - 400) / 2, 0, 400, CGRectGetHeight(self.superView.frame));
    } else {
        // 竖屏
        CGFloat keyboardHeight = 56 + P_SafeAreaBottomEdgeInsets();
        svgaView.frame = CGRectMake(0, CGRectGetHeight(self.superView.bounds) - keyboardHeight - 306, CGRectGetWidth(self.superView.bounds), 306);
    }
    __weak typeof(self) weakSelf = self;
    svgaView.willRemoveBlock = ^{
        if (weakSelf.isExecuting) weakSelf.executing = NO;
        if (!weakSelf.isFinished) weakSelf.finished = YES;
    };
    
    NSURL *rewardImageURL = [NSURL URLWithString:self.rewardImageUrl];
    NSString *rewardImageLastPath = rewardImageURL.lastPathComponent;
    NSString *itemName = [rewardImageLastPath substringWithRange:NSMakeRange(3, rewardImageLastPath.length - 7)];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [svgaView parseWithRewardItemName:itemName completion:^{
            [weakSelf.superView addSubview:svgaView];
        }];
    });
}

@end
