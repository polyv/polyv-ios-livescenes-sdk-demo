//
//  PLVLSBeautyCollectionViewCell.h
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/15.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLSBeautyCellModel;
@interface PLVLSBeautyCollectionViewCell : UICollectionViewCell

- (void)updateCellModel:(PLVLSBeautyCellModel *)cellModel beautyOpen:(BOOL)beautyOpen;

+ (NSString *)cellID;

@end

NS_ASSUME_NONNULL_END
