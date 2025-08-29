//
//  PLVStickerTypeSelectionView.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2023/9/15.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVSABottomSheet.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVStickerType) {
    PLVStickerTypeText,       // 文字贴图
    PLVStickerTypeImage       // 图片贴图
};

@class PLVStickerTypeSelectionView;

@protocol PLVStickerTypeSelectionViewDelegate <NSObject>


/// 选择贴图类型的回调
- (void)stickerTypeSelectionView:(PLVStickerTypeSelectionView *)selectionView didSelectType:(PLVStickerType)type;

/// 取消选择的回调
- (void)stickerTypeSelectionViewDidCancel:(PLVStickerTypeSelectionView *)selectionView;

@end

@interface PLVStickerTypeSelectionView : PLVSABottomSheet

@property (nonatomic, weak) id<PLVStickerTypeSelectionViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END 
