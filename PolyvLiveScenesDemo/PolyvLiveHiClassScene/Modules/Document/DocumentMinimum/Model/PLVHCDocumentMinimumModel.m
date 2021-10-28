//
//  PLVHCDocumentMinimumModel.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/7/15.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCDocumentMinimumModel.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCDocumentMinimumModel()

@property (nonatomic, copy) NSString *containerId;

@property (nonatomic, copy) NSString *fileName;

@property (nonatomic, copy) NSString *fileExtension;

@end

@implementation PLVHCDocumentMinimumModel

+ (PLVHCDocumentMinimumModel *)modelWithDictionary:(NSDictionary *)dict {
    PLVHCDocumentMinimumModel *model = [[PLVHCDocumentMinimumModel alloc] init];
    if (dict) {
        model.containerId = dict[@"containerId"];
        model.fileName = dict[@"fileName"];
        model.fileExtension = dict[@"fileExtension"];
    }
    return model;
}

@end
