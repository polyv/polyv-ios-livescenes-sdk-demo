//
//  PLVECRewardController.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/29.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECRewardController.h"
#import "PLVECChatroomViewModel.h"
#import <PolyvFoundationSDK/PLVFdUtil.h>

@interface PLVECRewardController () <PLVECRewardViewDelegate>

@end

@implementation PLVECRewardController

#pragma mark - Setter

- (void)setView:(PLVECRewardView *)view {
    _view = view;
    if (view) {
        view.delegate = self;
        [view setCloseButtonActionBlock:^(PLVECBottomView * _Nonnull view) {
            [view setHidden:YES];
        }];
    }
}

#pragma mark - Public

- (void)hiddenView:(BOOL)hidden {
    if (_view) {
        _view.hidden = hidden;
    }
}

#pragma mark - <PLVECRewardViewDelegate>

- (void)rewardView:(PLVECRewardView *)rewardView didSelectItem:(PLVECGiftItem *)giftItem {
    [rewardView setHidden:YES];
    
    NSString *giftName = giftItem.name;
    NSString *giftType = [giftItem.imageName substringFromIndex:14];
    
    if (!giftName || !giftType || !self.roomUser) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(showGiftAnimation:giftName:giftType:)]) {
        [self.delegate showGiftAnimation:self.roomUser.viewerName giftName:giftName giftType:giftType];
    }
    
    NSDictionary *data = @{@"giftName" : giftName,
                           @"giftType" : giftType,
                           @"giftCount" : @"1"};
    NSString *tip = [NSString stringWithFormat:@"%@ 赠送了 %@",self.roomUser.viewerName, giftName];
    [[PLVECChatroomViewModel sharedViewModel] sendGiftMessageWithData:data tip:tip];
}

@end
