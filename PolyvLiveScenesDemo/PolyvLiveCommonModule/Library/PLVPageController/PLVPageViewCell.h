//
//  PLVPageViewCell.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVPageViewCell : UICollectionViewCell

@property (nonatomic, assign) BOOL clicked;

@property (strong, nonatomic) UILabel *titleLabel;

@property (strong, nonatomic) UIView *indicatorView;

@end

NS_ASSUME_NONNULL_END
