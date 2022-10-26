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

/// 观看地址
@property (nonatomic, copy, readonly) NSString *watchUrl;
/// 海报地址，内部生成
@property (nonatomic, copy, readonly) NSString *posterURLString;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
