//
//  PLVDocumentModel.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/1.
//  Copyright © 2021 PLV. All rights reserved.
// 文档列表数据模型，每一个模型包含一个文档的基本数据

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVDocumentModel : NSObject

/// 文档Id
@property (nonatomic, assign, readonly) NSUInteger autoId;
/// 文件Id
@property (nonatomic, copy, readonly) NSString *fileId;
/// 文件名
@property (nonatomic, copy, readonly) NSString *fileName;
/// 文件类型
@property (nonatomic, copy, readonly) NSString *fileType;
/// 文件页数
@property (nonatomic, assign, readonly) NSUInteger totalPage;
/// 转换类型
@property (nonatomic, copy, readonly) NSString *convertType;
/// 预览缩略图
@property (nonatomic, copy, readonly) NSString *previewImage;
/// 预览原图
@property (nonatomic, copy, readonly) NSString *previewBigImage;

/// 将字典数据源 转成PLVDocumentModel模型
/// @param dict 数据源
+ (PLVDocumentModel *)modelWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
