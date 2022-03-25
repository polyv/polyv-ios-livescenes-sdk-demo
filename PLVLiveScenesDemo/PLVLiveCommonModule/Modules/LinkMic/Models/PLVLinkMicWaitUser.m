//
//  PLVLinkMicWaitUser.m
//  PLVLiveStreamerDemo
//
//  Created by Lincal on 2021/4/30.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLinkMicWaitUser.h"

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

#pragma mark 状态更新
- (void)updateUserCurrentRaiseHand:(BOOL)raiseHand{
    if (self.userType == PLVSocketUserTypeGuest) {
        _currentRaiseHand = raiseHand;
    }
}

- (void)updateUserCurrentAnswerAgreeJoin:(BOOL)answerAgreeJoin{
    if (self.userType == PLVSocketUserTypeGuest) {
        _currentAnswerAgreeJoin = answerAgreeJoin;
    }
}

#pragma mark 通知机制
- (void)wantAllowUserJoinLinkMic{
    if (self.wantAllowJoinLinkMicBlock) {
        __weak typeof(self) weakSelf = self;
        plv_dispatch_main_async_safe(^{
            if (weakSelf) { weakSelf.wantAllowJoinLinkMicBlock(weakSelf); }
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
