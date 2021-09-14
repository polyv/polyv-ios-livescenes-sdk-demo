//
//  PLVLSDocumentListCell.h
//  PLVLiveScenesDemo
//  文档列表页 PLVLSDocumentListView 的 cell
//
//  Created by MissYasiky on 2019/10/14.
//  Copyright © 2019 easefun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVDocumentUploadModel, PLVDocumentModel;

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSDocumentListCell : UICollectionViewCell

@property (nonatomic, copy) void (^animateLossButtonHandler)(void);

@property (nonatomic, copy) void (^buttonHandler)(NSInteger state);

@property (nonatomic, copy) void (^longPressHandler)(NSInteger tag);

// 开启loading
- (void)startLoading;

// 关闭loading
- (void)stopLoading;

- (void)setUploadModel:(PLVDocumentUploadModel *)uploadModel;

- (void)setDocumentModel:(PLVDocumentModel *)documentModel;

@end

NS_ASSUME_NONNULL_END
