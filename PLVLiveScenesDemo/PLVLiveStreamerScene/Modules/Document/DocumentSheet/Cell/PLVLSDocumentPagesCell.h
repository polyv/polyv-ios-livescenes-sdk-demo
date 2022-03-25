//
//  PLVLSDocumentPagesCell.h
//  PLVLiveStreamerDemo
//
//  Created by Hank on 2021/3/9.
//  Copyright © 2021 PLV. All rights reserved.
//  文档页面列表Cell

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSDocumentPagesCell : UICollectionViewCell

///  设置页面缩略图
///
/// @param imgUrl 文档页面链接
/// @param index 文档页面序号（页码）
- (void)setImgUrl:(NSString *)imgUrl index:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
