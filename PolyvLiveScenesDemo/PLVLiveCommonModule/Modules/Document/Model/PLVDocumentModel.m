//
//  PLVDocumentModel.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/1.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVDocumentModel.h"

#import <PLVFoundationSDK/PLVFdUtil.h>

@interface PLVDocumentModel ()

@property (nonatomic, assign) NSUInteger autoId;

@property (nonatomic, copy) NSString *fileId;

@property (nonatomic, copy) NSString *fileName;

@property (nonatomic, copy) NSString *fileType;

@property (nonatomic, assign) NSUInteger totalPage;

@property (nonatomic, copy) NSString *convertType;

@property (nonatomic, copy) NSString *previewImage;

@property (nonatomic, copy) NSString *previewBigImage;

@end

@implementation PLVDocumentModel

+ (PLVDocumentModel *)modelWithDictionary:(NSDictionary *)dict {
    PLVDocumentModel *model = [[PLVDocumentModel alloc] init];
    model.autoId = [dict[@"autoId"] integerValue];
    model.fileId = dict[@"fileId"];
    model.fileName = dict[@"fileName"];
    model.fileType = dict[@"fileType"];
    model.totalPage = [dict[@"totalPage"] integerValue];
    model.convertType = dict[@"convertType"];
    model.previewImage = dict[@"previewImage"];
    model.previewBigImage = dict[@"previewBigImage"];
    
    return model;
}

- (void)setFileType:(NSString *)fileType {
    if ([fileType hasPrefix:@"."]) {
        _fileType = [fileType substringFromIndex:1];
    } else {
        _fileType = fileType;
    }
}

- (void)setPreviewImage:(NSString *)previewImage {
    _previewImage = [PLVFdUtil packageURLStringWithHTTPS:previewImage];
}

- (void)setPreviewBigImage:(NSString *)previewBigImage {
    _previewBigImage = [PLVFdUtil packageURLStringWithHTTPS:previewBigImage];
}

@end
