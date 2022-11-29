//
//  PLVLCDescViewController.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCDescViewController.h"
#import "PLVLCDescBottomView.h"
#import <PLVLiveScenesSDK/PLVLiveVideoChannelMenuInfo.h>
#import "PLVRoomDataManager.h"

@interface PLVLCDescViewController ()

@property (nonatomic, strong) PLVLiveVideoChannelMenuInfo *channelInfo;
@property (nonatomic, copy) NSString *content;

@property (nonatomic, strong) PLVLCDescTopView *topView;
@property (nonatomic, strong) PLVLCDescBottomView *bottomView;

@end

@implementation PLVLCDescViewController

#pragma mark - Life Cycle

- (instancetype)initWithChannelInfo:(PLVLiveVideoChannelMenuInfo *)channelInfo content:(NSString *)content {
    self = [super init];
    if (self) {
        _channelInfo = channelInfo;
        _content = content;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0x20/255.0 green:0x21/255.0 blue:0x27/255.0 alpha:1.0];
    
    [self.view addSubview:self.topView];
    [self.view addSubview:self.bottomView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGFloat topViewHeight = 71+1+36;
    self.topView.frame = CGRectMake(0, 0, self.view.bounds.size.width, topViewHeight);
    CGFloat originY = CGRectGetMaxY(self.topView.frame);
    self.bottomView.frame = CGRectMake(0, originY, self.view.bounds.size.width, self.view.bounds.size.height - originY);
}

#pragma mark - Getter & Setter

- (PLVLCDescTopView *)topView {
    if (!_topView) {
        _topView = [[PLVLCDescTopView alloc] init];
        _topView.channelInfo = self.channelInfo;
    }
    return _topView;
}

- (PLVLCDescBottomView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[PLVLCDescBottomView alloc] init];
        _bottomView.content = self.content;
    }
    return _bottomView;
}

#pragma mark - Public Method

- (void)updateLiveStatus:(PLVLCLiveStatus)liveStatus {
    if (liveStatus == PLVLCLiveStatusEnd &&
        self.topView.status == PLVLCLiveStatusWaiting) {
        liveStatus = PLVLCLiveStatusWaiting;
    } else if (liveStatus == PLVLCLiveStatusEnd && self.topView.status == PLVLCLiveStatusUnStart) {
        liveStatus = PLVLCLiveStatusUnStart;
    }
    self.topView.status = liveStatus;
}

@end
