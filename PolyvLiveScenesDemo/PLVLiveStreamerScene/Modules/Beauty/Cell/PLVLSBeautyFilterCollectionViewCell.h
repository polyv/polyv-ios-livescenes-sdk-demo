//
//  PLVLSBeautyFilterCollectionViewCell.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/4/18.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLSBeautyCellModel;
@interface PLVLSBeautyFilterCollectionViewCell : UICollectionViewCell

- (void)updateCellModel:(PLVLSBeautyCellModel *)cellModel beautyOpen:(BOOL)beautyOpen;

+ (NSString *)cellID;

@end

NS_ASSUME_NONNULL_END
