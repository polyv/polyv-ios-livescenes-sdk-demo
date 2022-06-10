//
//  PLVLCTabbarItemCell.h
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/5/26.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCTabbarItemCell : UICollectionViewCell

@property (nonatomic, assign) BOOL clicked;

@property (strong, nonatomic) UILabel *titleLabel;

@property (strong, nonatomic) UIView *indicatorView;

@end

NS_ASSUME_NONNULL_END
