//
//  PLVHCDocumentListCell.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/30.
//  Copyright © 2021 polyv. All rights reserved.
// 文档列表页 PLVHCDocumentListView 的 cell

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVDocumentUploadModel;
@class PLVDocumentModel;

@interface PLVHCDocumentListCell : UICollectionViewCell

@property (nonatomic, strong) PLVDocumentModel *documentModel;

@property (nonatomic, strong) PLVDocumentUploadModel *uploadModel;

@property (nonatomic, copy) void (^animateLossButtonHandler)(NSString *fileId);

@property (nonatomic, copy) void (^buttonHandler)(PLVDocumentUploadStatus state, PLVDocumentUploadModel *uploadModel);

@property (nonatomic, copy) void (^longPressHandler)(NSInteger tag);

@end

NS_ASSUME_NONNULL_END
