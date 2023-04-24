//
//  PLVRedpackResult.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/1/9.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVRedpackResult : NSObject

// 被领取红包ID
@property (nonatomic, copy) NSString * _Nullable redpackId;
// 被领取红包类型
@property (nonatomic, assign) PLVRedpackMessageType type;
// 是否领完
@property (nonatomic, assign, getter=isOver) BOOL over;
// 领取人昵称
@property (nonatomic, strong) NSString *nick;

@end

NS_ASSUME_NONNULL_END
