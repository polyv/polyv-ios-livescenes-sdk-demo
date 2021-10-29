//
//  PLVHCDocumentListUploadCell.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/30.
//  Copyright © 2021 PLV. All rights reserved.
// 上传文档入口Cell，固定在第一个cell

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCDocumentListUploadCell : UICollectionViewCell

/// 添加上传按钮事件
///
/// @param target 事件方法所在类
/// @param action 事件方法
- (void)uploadTarget:(nullable id)target action:(SEL)action;

/// 添加上传须知按钮事件
///
/// @param target 事件方法所在类
/// @param action 事件方法
- (void)tipTarget:(nullable id)target action:(SEL)action;


@end

NS_ASSUME_NONNULL_END
