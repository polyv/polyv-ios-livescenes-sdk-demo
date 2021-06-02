//
//  PLVLSMemberSheet.h
//  PolyvLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/29.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVLSSideSheet.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLSMemberSheetProtocol <NSObject>

- (void)memberSheet_didTapCloseAllUserLinkMicChangeBlock:(void(^)(BOOL needChange))changeBlock;

- (void)memberSheet_didTapMuteAllUserMic:(BOOL)mute changeBlock:(void(^)(BOOL needChange))changeBlock;

@end

@interface PLVLSMemberSheet : PLVLSSideSheet

@property (nonatomic, weak) id<PLVLSMemberSheetProtocol> delegate;

#pragma mark 连麦业务相关
- (void)refreshUserListWithLinkMicWaitUserArray:(NSArray *)linkMicWaitUserArray;

- (void)refreshUserListWithLinkMicOnlineUserArray:(NSArray *)linkMicOnlineUserArray;

@end

NS_ASSUME_NONNULL_END
