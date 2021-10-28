//
//  PLVHCMemberViewModel.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2021/8/6.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCMemberViewModel.h"
#import "PLVChatUser.h"
#import "PLVLinkMicOnlineUser.h"
#import "PLVRoomDataManager.h"

@interface PLVHCMemberViewModel ()<
PLVMemberPresenterDelegate // common层成员Presenter协议
>

/// 成员common层presenter，一个scene层只能初始化一个presenter对象
@property (nonatomic, strong) PLVMemberPresenter *presenter;

/// 聊天室在线人数
@property (nonatomic, assign) NSInteger onlineCount;

/// 聊天室移出人数
@property (nonatomic, assign) NSInteger kickedCount;

/// 聊天室在线学生列表
@property (nonatomic, copy) NSArray <PLVChatUser *> *onlineUserArray;

/// 聊天室移出学生列表
@property (nonatomic, copy) NSArray <PLVChatUser *> *kickedUserArray;

@end

@implementation PLVHCMemberViewModel

#pragma mark - [ Public Method ]

+ (instancetype)sharedViewModel {
    static dispatch_once_t onceToken;
    static PLVHCMemberViewModel *viewModel = nil;
    dispatch_once(&onceToken, ^{
        viewModel = [[self alloc] init];
    });
    return viewModel;
}

- (void)setup {
    // 初始化成员模块
    self.presenter = [[PLVMemberPresenter alloc] init];
    self.presenter.monitorKickUser = YES;
    self.presenter.delegate = self;
    
    if ([PLVRoomDataManager sharedManager].roomData.lessonInfo.hiClassStatus == PLVHiClassStatusInClass) { // 开始上课之后才开始获取成员列表
        [self start];
    }
}

- (void)clear {
    // 成员列表数据停止自动更新
    [self.presenter stop];
    self.presenter = nil;
    
    self.onlineCount = 0;
    self.kickedCount = 0;
    self.onlineUserArray = nil;
    self.kickedUserArray = nil;
}

- (void)start {
    [self.presenter start];
}

- (void)stop {
    [self.presenter stop];
}

- (PLVChatUser * _Nullable)userInListWithUserId:(NSString *)userId {
    return [self.presenter userInListWithUserId:userId];
}

- (void)kickUserWithUserId:(NSString *)userId {
    [self.presenter kickUserWithUserId:userId];
}

- (void)unkickUser:(PLVChatUser *)user {
    [self.presenter unkickUser:user];
}

- (void)banUserWithUserId:(NSString *)userId banned:(BOOL)banned {
    [self.presenter banUserWithUserId:userId banned:banned];
}

- (void)refreshUserListWithLinkMicOnlineUserArray:(NSArray <PLVLinkMicOnlineUser *>*)linkMicUserArray {
    [self.presenter refreshUserListWithLinkMicOnlineUserArray:linkMicUserArray];
}

#pragma mark - [ Private Method ]

- (void)updateOnlineUser {
    NSInteger removeCount = 0;
    NSMutableArray *muArray = [[NSMutableArray alloc] initWithCapacity:self.presenter.userCount];
    for (PLVChatUser *user in [self.presenter userList]) {
        if (user.userType == PLVRoomUserTypeSCStudent) {
            [muArray addObject:user];
        } else {
            removeCount++;
        }
    }
    self.onlineCount = self.presenter.userCount - removeCount;
    self.onlineUserArray = [muArray copy];
}

- (void)updateKickedUser {
    NSInteger removeCount = 0;
    NSMutableArray *muArray = [[NSMutableArray alloc] initWithCapacity:self.presenter.kickedCount];
    for (PLVChatUser *user in [self.presenter kickedUserList]) {
        if (user.userType == PLVRoomUserTypeSCStudent) {
            [muArray addObject:user];
        } else {
            removeCount++;
        }
    }
    self.kickedCount = self.presenter.kickedCount - removeCount;
    self.kickedUserArray = [muArray copy];
}

#pragma mark - [ Delegate ]

#pragma mark PLVMemberPresenterDelegate

- (void)userListChangedInMemberPresenter:(PLVMemberPresenter *)memberPresenter {
    [self updateOnlineUser];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(onlineUserListChangedInMemberViewModel:)]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.delegate onlineUserListChangedInMemberViewModel:weakSelf];
        });
    }
}

- (void)kickedUserListChangedInMemberPresenter:(PLVMemberPresenter *)memberPresenter {
    [self updateKickedUser];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(kickedUserListChangedInMemberViewModel:)]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.delegate kickedUserListChangedInMemberViewModel:weakSelf];
        });
    }
}

@end
