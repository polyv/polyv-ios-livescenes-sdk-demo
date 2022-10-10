//
//  PLVShareLivePosterModel.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2022/9/6.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVShareLivePosterModel : NSObject

/// 邀请海报主题风格
@property (nonatomic, assign) NSInteger invitePosterTheme;
/// 头像
@property (nonatomic, copy) NSString *avatar;
/// 名称
@property (nonatomic, copy) NSString *nickname;
/// 频道名称
@property (nonatomic, copy) NSString *name;
/// 海报封面图
@property (nonatomic, copy) NSString *inviteCoverImage;
/// 主持人姓名
@property (nonatomic, copy) NSString *publisher;
/// 开始时间
@property (nonatomic, copy) NSString *startTime;
/// 观看域名
@property (nonatomic, copy) NSString *watchDomain;
/// 频道号
@property (nonatomic, copy) NSString *channelId;
/// 观看地址
@property (nonatomic, copy) NSString *watchUrl;
/// 定制用户类型
@property (nonatomic, copy) NSString *customUserType;
/// 页脚文案
@property (nonatomic, copy) NSString *footerText;
/// 海报地址，内部生成
@property (nonatomic, copy, readonly) NSString *posterURLString;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
