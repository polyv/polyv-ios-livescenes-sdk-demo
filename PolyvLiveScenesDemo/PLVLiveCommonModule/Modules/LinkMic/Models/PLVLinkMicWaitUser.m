//
//  PLVLinkMicWaitUser.m
//  PLVLiveStreamerDemo
//
//  Created by Lincal on 2021/4/30.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLinkMicWaitUser.h"
#import "PLVChatUser.h"

@interface PLVLinkMicWaitUser ()

#pragma mark 对象
@property (nonatomic, strong) NSMapTable <id, PLVLinkMicWaitUserWillDeallocBlock> * willDealloc_MultiReceiverMap;

#pragma mark 数据
@property (nonatomic, copy) NSString * userId;
@property (nonatomic, copy) NSString * linkMicUserId;
@property (nonatomic, copy, nullable) NSString * actor;
@property (nonatomic, copy, nullable) NSString * nickname;
@property (nonatomic, copy, nullable) NSString * avatarPic;
@property (nonatomic, assign) PLVSocketUserType userType;
@property (nonatomic, assign) BOOL localUser;
@property (nonatomic, strong) NSDictionary * originalUserDict;

#pragma mark 状态
@property (nonatomic, assign) BOOL currentRaiseHand;
@property (nonatomic, assign) BOOL currentAnswerAgreeJoin;
@property (nonatomic, assign) PLVLinkMicUserLinkMicStatus linkMicStatus;

@end

@implementation PLVLinkMicWaitUser

#pragma mark - [ Life Period ]
- (void)dealloc{
    if (self.willDeallocBlock) {
        self.willDeallocBlock(self);
        self.willDeallocBlock = nil;
    }
    
    if (_willDealloc_MultiReceiverMap.count > 0) {
        NSEnumerator * enumerator = [_willDealloc_MultiReceiverMap objectEnumerator];
        PLVLinkMicWaitUserWillDeallocBlock block;
        while ((block = [enumerator nextObject])) {
            block(self);
        }
    }
}


#pragma mark - [ Private Methods ]
#pragma mark Getter
- (NSMapTable<id,PLVLinkMicWaitUserWillDeallocBlock> *)willDealloc_MultiReceiverMap{
    if (!_willDealloc_MultiReceiverMap) {
        _willDealloc_MultiReceiverMap = [NSMapTable weakToStrongObjectsMapTable];
    }
    return _willDealloc_MultiReceiverMap;
}


#pragma mark - [ Public Methods ]
#pragma mark 创建
+ (instancetype)modelWithDictionary:(NSDictionary *)dictionary{
    if ([PLVFdUtil checkDictionaryUseable:dictionary]) {
        PLVLinkMicWaitUser * user = [[PLVLinkMicWaitUser alloc]init];
        
        /// 用户类型
        NSString * userType = [NSString stringWithFormat:@"%@",dictionary[@"userType"]];
        if ([@"teacher" isEqualToString:userType]) {
            user.userType = PLVSocketUserTypeTeacher;
        } else if ([@"viewer" isEqualToString:userType]) {
            user.userType = PLVSocketUserTypeViewer;
        } else if ([@"guest" isEqualToString:userType]){
            user.userType = PLVSocketUserTypeGuest;
        } else if ([@"slice" isEqualToString:userType]){
            user.userType = PLVSocketUserTypeSlice;
        } else if ([@"student" isEqualToString:userType]){
            user.userType = PLVSocketUserTypeStudent;
        }
        
        /// 用户信息
        user.userId = [PLVFdUtil checkStringUseable:dictionary[@"loginId"]] ? dictionary[@"loginId"] : nil;
        user.linkMicUserId = [PLVFdUtil checkStringUseable:dictionary[@"userId"]] ? dictionary[@"userId"] : nil;
        // 特殊情况创建的等待观众观众用户
        NSString *isCreat = PLV_SafeStringForDictKey(dictionary, @"isCreat");
        if ([PLVFdUtil checkStringUseable:isCreat] && [isCreat isEqualToString:@"1"]) {
            user.userId = [PLVFdUtil checkStringUseable:dictionary[@"userId"]] ? dictionary[@"userId"] : nil;
            user.linkMicUserId = [PLVFdUtil checkStringUseable:dictionary[@"loginId"]] ? dictionary[@"loginId"] : nil;
        }
        
        user.nickname = [PLVFdUtil checkStringUseable:dictionary[@"nick"]] ? dictionary[@"nick"] : nil;
        user.avatarPic = [PLVFdUtil checkStringUseable:dictionary[@"pic"]] ? dictionary[@"pic"] : nil;
        user.actor = [PLVFdUtil checkStringUseable:dictionary[@"actor"]] ? dictionary[@"actor"] : nil;
        
        if (user.userType == PLVSocketUserTypeGuest) {
            user.userId = [PLVFdUtil checkStringUseable:dictionary[@"userId"]] ? dictionary[@"userId"] : nil;
        }
        
        /// 原始数据
        user.originalUserDict = dictionary;
        
        return user;
    }
    return nil;
}

+ (instancetype)modelWithChatUser:(PLVChatUser *)chatUser {
    if (!chatUser ||
        ![chatUser isKindOfClass:[PLVChatUser class]]) {
        return nil;
    }
    
    PLVLinkMicWaitUser *user = [[PLVLinkMicWaitUser alloc] init];
    user.userType = [PLVRoomUser sockerUserTypeWithRoomUserType:chatUser.userType];
    user.userId = chatUser.userId;
    user.linkMicUserId = chatUser.micId ? chatUser.micId : chatUser.userId;
    user.nickname = chatUser.userName;
    user.avatarPic = chatUser.avatarUrl;
    user.actor = chatUser.actor;
    user.originalUserDict = @{
        @"actor" : [NSString stringWithFormat:@"%@", chatUser.actor],
        @"userType" : [NSString stringWithFormat:@"%@", [PLVRoomUser userTypeStringWithUserType:chatUser.userType]],
        @"nick" : [NSString stringWithFormat:@"%@", chatUser.userName],
        @"pic" : [NSString stringWithFormat:@"%@",chatUser.avatarUrl],
        @"userId" : [NSString stringWithFormat:@"%@", user.userId],
        @"loginId" : [NSString stringWithFormat:@"%@", user.linkMicUserId],
        @"banned" : @(chatUser.banned),
        @"isCreat" : @"1" // 是否是自己创建的数据
    };
    return user;
}

#pragma mark 状态更新
- (void)updateUserCurrentRaiseHand:(BOOL)raiseHand{
    if (self.userType == PLVSocketUserTypeGuest ||
        self.userType == PLVSocketUserTypeSlice ||
        self.userType == PLVSocketUserTypeStudent) {
        _currentRaiseHand = raiseHand;
    }
}

- (void)updateUserCurrentAnswerAgreeJoin:(BOOL)answerAgreeJoin{
    if (self.userType == PLVSocketUserTypeGuest) {
        _currentAnswerAgreeJoin = answerAgreeJoin;
    }
}

- (void)updateUserCurrentLinkMicStatus:(PLVLinkMicUserLinkMicStatus)linkMicStatus {
    if (self.userType != PLVSocketUserTypeGuest &&
        self.userType != PLVSocketUserTypeSlice &&
        self.userType != PLVSocketUserTypeStudent) {
        return;
    }
    
    _linkMicStatus = linkMicStatus;
    if (self.linkMicStatusBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.linkMicStatusBlock(weakSelf); }
        })
    }
}

#pragma mark 多接收方回调配置
- (void)addWillDeallocBlock:(PLVLinkMicWaitUserWillDeallocBlock)weakBlock blockKey:(id)blockKey{
    if (!weakBlock) {
        NSLog(@"PLVLinkMicWaitUser - addWillDeallocBlock failed，weakBlock illegal");
        return;
    }
    if (!blockKey) {
        NSLog(@"PLVLinkMicWaitUser - addWillDeallocBlock failed，blockKey illegal:%@",blockKey);
        return;
    }
    if (self.willDealloc_MultiReceiverMap.count > 20) {
        NSLog(@"PLVLinkMicWaitUser - addWillDeallocBlock failed，block registration limit has been reached");
        return;
    }
    [self.willDealloc_MultiReceiverMap setObject:weakBlock forKey:blockKey];
}

@end
