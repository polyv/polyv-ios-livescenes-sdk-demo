//
//  PLVECCardView.h
//  PLVLiveEcommerceDemo
//
//  Created by ftao on 2020/5/25.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVECCardView;
@protocol PLVECCardViewDelegate <NSObject>

@optional
- (void)cardView:(PLVECCardView *)cardView didInteractWithURL:(NSURL *)URL;

@end

@interface PLVECCardView : UIView

@property (nonatomic, weak) id<PLVECCardViewDelegate> delegate;

@property (nonatomic, strong) UILabel *titleLB;

@property (nonatomic, strong) UIImageView *iconImgView;

@end

NS_ASSUME_NONNULL_END
