//
//  PLVHCMemberViewModel.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/8/6.
//  Copyright © 2021 PLV. All rights reserved.
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
    
    if ([PLVHiClassManager sharedManager].status == PLVHiClassStatusInClass) { // 开始上课之后才开始获取成员列表
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

- (void)loadOnlineUserList {
    [self.presenter loadOnlineUserList];
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

- (void)handUpWithUserId:(NSString *)userId handUp:(BOOL)handUp {
    if (![PLVFdUtil checkStringUseable:userId]) {
        return;
    }
    
    __block BOOL match = NO;
    [self.onlineUserArray enumerateObjectsUsingBlock:^(PLVChatUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userId isEqualToString:userId]) {
            if (obj.onlineUser) {
                [obj.onlineUser updateUserCurrentHandUp:handUp];
            }
            obj.currentHandUp = handUp;
            match = YES;
            *stop = YES;
        }
    }];
    if (match) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(onlineUserListChangedInMemberViewModel:)]) {
            __weak typeof(self) weakSelf = self;
            plv_dispatch_main_async_safe(^{
                [weakSelf.delegate onlineUserListChangedInMemberViewModel:weakSelf];
            })
        }
    }
}

- (NSString *)grantCupWithUserId:(NSString *)userId {
    if (![PLVFdUtil checkStringUseable:userId]) {
        return nil;
    }
    
    __block NSString *nick = nil;
    [self.onlineUserArray enumerateObjectsUsingBlock:^(PLVChatUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userId isEqualToString:userId]) {
            obj.cupCount++;
            if (obj.onlineUser) {
                [obj.onlineUser updateUserCurrentGrantCupCount:obj.cupCount];
            }
            nick = obj.userName;
            *stop = YES;
        }
    }];
    if (nick) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(onlineUserListChangedInMemberViewModel:)]) {
            __weak typeof(self) weakSelf = self;
            plv_dispatch_main_async_safe(^{
                [weakSelf.delegate onlineUserListChangedInMemberViewModel:weakSelf];
            })
        }
    }
    return nick;
}

- (void)brushPermissionWithUserId:(NSString *)userId auth:(BOOL)auth {
    if (![PLVFdUtil checkStringUseable:userId]) {
        return;
    }
    
    __block BOOL match = NO;
    [self.onlineUserArray enumerateObjectsUsingBlock:^(PLVChatUser * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.userId isEqualToString:userId]) {
            if (obj.onlineUser) {
                [obj.onlineUser updateUserCurrentBrushAuth:auth];
            }
            obj.currentBrushAuth = auth;
            match = YES;
            *stop = YES;
        }
    }];
    if (match) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(onlineUserListChangedInMemberViewModel:)]) {
            __weak typeof(self) weakSelf = self;
            plv_dispatch_main_async_safe(^{
                [weakSelf.delegate onlineUserListChangedInMemberViewModel:weakSelf];
            })
        }
    }
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
        plv_dispatch_main_async_safe(^{
            [weakSelf.delegate onlineUserListChangedInMemberViewModel:weakSelf];
        })
    }
}

- (void)kickedUserListChangedInMemberPresenter:(PLVMemberPresenter *)memberPresenter {
    [self updateKickedUser];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(kickedUserListChangedInMemberViewModel:)]) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            [weakSelf.delegate kickedUserListChangedInMemberViewModel:weakSelf];
        })
    }
}

@end
