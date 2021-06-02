//
//  PLVLSDocumentModel.m
//  PLVCloudClassStreamerModul
//
//  Created by MissYasiky on 2019/10/15.
//  Copyright © 2019 easefun. All rights reserved.
//

#import "PLVLSDocumentModel.h"
#import <PolyvFoundationSDK/PLVFdUtil.h>

@interface PLVLSDocumentModel ()

@property (nonatomic, assign) NSUInteger autoId;

@property (nonatomic, copy) NSString *fileId;

@property (nonatomic, copy) NSString *fileName;

@property (nonatomic, copy) NSString *fileType;

@property (nonatomic, assign) NSUInteger totalPage;

@property (nonatomic, copy) NSString *convertType;

@property (nonatomic, copy) NSString *previewImage;

@property (nonatomic, copy) NSString *previewBigImage;

@end

@implementation PLVLSDocumentModel

+ (PLVLSDocumentModel *)modelWithDictionary:(NSDictionary *)dict {
    PLVLSDocumentModel *model = [[PLVLSDocumentModel alloc] init];
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
