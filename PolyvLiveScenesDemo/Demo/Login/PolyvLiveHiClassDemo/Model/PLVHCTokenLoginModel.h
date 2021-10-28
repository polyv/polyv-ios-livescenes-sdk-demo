//
//  PLVHCTokenLoginModel.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/9/6.
//  Copyright © 2021 polyv. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCTokenLoginModel : NSObject<NSCoding,NSCopying>

///登录用户token
@property (nonatomic, copy) NSString *token;
///关联讲师Id
@property (nonatomic, copy) NSString *userId;
///讲师昵称
@property (nonatomic, copy) NSString *nickname;
///上课课节Id
@property (nonatomic, copy) NSString *lessonId;

@end

NS_ASSUME_NONNULL_END
