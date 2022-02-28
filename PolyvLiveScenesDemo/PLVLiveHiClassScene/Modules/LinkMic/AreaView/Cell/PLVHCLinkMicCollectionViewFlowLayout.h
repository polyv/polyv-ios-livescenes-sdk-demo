//
//  PLVHCLinkMicCollectionViewFlowLayout.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/9/24.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVHCLinkMicCollectionViewFlowLayoutDelegate;

@interface PLVHCLinkMicCollectionViewFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, weak) id <PLVHCLinkMicCollectionViewFlowLayoutDelegate> delegate;

@end

@protocol PLVHCLinkMicCollectionViewFlowLayoutDelegate <NSObject>

/// 获取indexPath对应的Cell是否是讲师 【仅在1v16是需要用到】
/// @param indexPath Cell对应的下标
- (BOOL)linkMicFlowLayout:(PLVHCLinkMicCollectionViewFlowLayout *)flowLayout teacherItemAtIndexPath:(NSIndexPath *)indexPath;

/// 获取WindowsView界面的size，为了设置CollectionView的frame
- (CGSize)linkMicFlowLayoutGetWindowsViewSize:(PLVHCLinkMicCollectionViewFlowLayout *)flowLayout;

@end

NS_ASSUME_NONNULL_END
