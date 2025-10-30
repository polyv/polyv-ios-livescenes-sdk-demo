//
//  PLVCastDefinitionModel.h
//  PLVCloudClassDemo
//
//  Created by MissYasiky on 2020/7/17.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVCastDefinitionModel : NSObject
/// 清晰度：高清、超清、标清
@property (nonatomic, copy, readonly) NSString *definition;
/// 对应清晰度的播放链接
@property (nonatomic, copy, readonly) NSString *playUrlString;
/// 对应清晰度的 m3u8 播放链接
@property (nonatomic, copy, readonly) NSString *m3u8UrlString;

/// 根据后台返回数据进行初始化
- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
