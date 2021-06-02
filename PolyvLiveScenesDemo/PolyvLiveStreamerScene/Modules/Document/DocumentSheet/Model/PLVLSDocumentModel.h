//
//  PLVLSDocumentModel.h
//  PLVCloudClassStreamerModul
//  文档列表 PLVSDocumentListViewController 数据模型，每一个模型包含一个文档的基本数据
//
//  Created by MissYasiky on 2019/10/15.
//  Copyright © 2019 easefun. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSDocumentModel : NSObject

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

+ (PLVLSDocumentModel *)modelWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
