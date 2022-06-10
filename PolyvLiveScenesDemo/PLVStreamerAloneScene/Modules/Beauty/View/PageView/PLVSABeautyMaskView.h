//
//  PLVSABeautyMaskView.h
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/15.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVSABeautyMaskView : UIView

@property (nonatomic, strong) UIImageView *maskImageView;

- (void)beautyOpen:(BOOL)open;

@end

NS_ASSUME_NONNULL_END
