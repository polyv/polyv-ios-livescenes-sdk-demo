//
//  PLVECRewardController.m
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/6/29.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECRewardController.h"

// 工具
#import "PLVECUtils.h"

// 模块
#import "PLVECChatroomViewModel.h"
#import "PLVRoomDataManager.h"

// 依赖库
#import <PLVFoundationSDK/PLVFdUtil.h>

@interface PLVECRewardController () <PLVECRewardViewDelegate>

@end

@implementation PLVECRewardController

#pragma mark - Setter

- (void)setView:(PLVECRewardView *)view {
    _view = view;
    if (view) {
        view.delegate = self;
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
    
    if (!giftName || !giftType) {
        return;
    }
    
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    NSDictionary *data = @{@"giftName" : giftName,
                           @"giftType" : giftType,
                           @"giftCount" : @"1"};
    NSString *tip = [NSString stringWithFormat:@"%@ 赠送了 %@", roomUser.viewerName, giftName];
    BOOL success = [[PLVECChatroomViewModel sharedViewModel] sendGiftMessageWithData:data tip:tip];
    if (success) {
        self.didSendGift ? self.didSendGift(giftName, giftType) : nil;
    } else {
        [PLVECUtils showHUDWithTitle:@"发送失败" detail:@"" view:self.view.superview];
    }
}

@end
