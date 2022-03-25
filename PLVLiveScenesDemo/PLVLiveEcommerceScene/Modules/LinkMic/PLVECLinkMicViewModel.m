//
//  PLVECLinkMicViewModel.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/10/11.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVECLinkMicViewModel.h"
#import "PLVLinkMicPresenter.h"
#import "PLVLinkMicOnlineUser+EC.h"

@interface PLVECLinkMicViewModel ()<
PLVLinkMicPresenterDelegate
>
#pragma mark 数据
@property (nonatomic, readonly) NSArray <PLVLinkMicOnlineUser *> * dataArray; // 只读，当前连麦在线用户数组
#pragma mark 对象
@property (nonatomic, strong) PLVLinkMicPresenter * presenter; // 连麦逻辑处理模块

@end

@implementation PLVECLinkMicViewModel

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        // 添加 连麦功能模块
        self.presenter = [[PLVLinkMicPresenter alloc] init];
        self.presenter.delegate = self;
    }
    return self;
}

#pragma mark - Getter

- (NSArray<PLVLinkMicOnlineUser *> *)dataArray{
    return self.presenter.onlineUserArray;
}

#pragma mark - [Private Method]

// 若 连麦用户Model 未有 连麦rtc画布视图，则此时需创建并交由 连麦用户Model 进行管理
- (void)checkUserModelAndSetupLinkMicCanvasView:(PLVLinkMicOnlineUser *)linkMicUserModel{
    if (linkMicUserModel.canvasView == nil) {
        PLVECLinkMicCanvasView * canvasView = [[PLVECLinkMicCanvasView alloc] init];
        [canvasView addRTCView:linkMicUserModel.rtcView];
        linkMicUserModel.canvasView = canvasView;
    }
}

// 设置 连麦用户Model的 ’即将销毁Block‘ Block
// 用于在连麦用户退出时，及时回收资源
- (void)setupUserModelWillDeallocBlock:(PLVLinkMicOnlineUser *)linkMicUserModel{
    linkMicUserModel.willDeallocBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        PLVECLinkMicCanvasView * canvasView = onlineUser.canvasView;
        dispatch_async(dispatch_get_main_queue(), ^{
            /// 回收资源
            [canvasView removeRTCView];
            [canvasView removeFromSuperview];
        });
    };
}

- (void)reloadLinkMicOnlineUserList {
    PLVLinkMicOnlineUser * firstSiteOnlineUser = self.dataArray.firstObject;
    if (firstSiteOnlineUser) {
        [self checkUserModelAndSetupLinkMicCanvasView:firstSiteOnlineUser];
        [self setupUserModelWillDeallocBlock:firstSiteOnlineUser];
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvECLinkMicViewModel:showFirstSiteCanvasViewOnExternal:)]) {
            [self.delegate plvECLinkMicViewModel:self showFirstSiteCanvasViewOnExternal:firstSiteOnlineUser.canvasView];
        }
    }
}

- (void)startWatchNoDelay:(BOOL)startWatch {
    if (startWatch) {
        [self.presenter startWatchNoDelay];
    }else{
        [self.presenter stopWatchNoDelay];
    }
}

#pragma mark - [Delegate]

#pragma mark PLVLinkMicPresenterDelegate

- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter linkMicOnlineUserListRefresh:(NSArray *)onlineUserArray {
    [self reloadLinkMicOnlineUserList];
}

- (void)plvLinkMicPresenter:(PLVLinkMicPresenter *)presenter localUserNetworkRxQuality:(PLVBLinkMicNetworkQuality)rxQuality {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvECLinkMicViewModel:localUserNetworkRxQuality:)]) {
        [self.delegate plvECLinkMicViewModel:self localUserNetworkRxQuality:rxQuality];
    }
}

@end
