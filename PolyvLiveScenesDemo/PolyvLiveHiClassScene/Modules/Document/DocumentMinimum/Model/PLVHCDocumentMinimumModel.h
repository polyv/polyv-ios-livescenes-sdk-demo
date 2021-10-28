//
//  PLVHCDocumentMinimumModel.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/7/15.
//  Copyright © 2021 polyv. All rights reserved.
// 文档最小化文档列表模型

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCDocumentMinimumModel : NSObject

/// 容器(ppt、word各类文档统称)Id
@property (nonatomic, copy, readonly) NSString *containerId;
/// 文件名
@property (nonatomic, copy, readonly) NSString *fileName;
/// 文件拓展名
@property (nonatomic, copy, readonly) NSString *fileExtension;

/// 将字典数据源 转成PLVHCDocumentMinimumModel模型
/// @param dict 数据源
+ (PLVHCDocumentMinimumModel *)modelWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
