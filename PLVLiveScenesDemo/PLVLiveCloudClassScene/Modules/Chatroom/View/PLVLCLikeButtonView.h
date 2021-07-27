//
//  PLVLCLikeButtonView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/10/10.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

#define PLVLCLikeButtonViewWidth (46.0)
#define PLVLCLikeButtonViewHeight (46.0 + 2.0 + 16.0)

NS_ASSUME_NONNULL_BEGIN

@class PLVLCLikeButtonView;

@protocol PLVLCLikeButtonViewDelegate <NSObject>

@required

- (void)didTapLikeButton:(PLVLCLikeButtonView *)likeButtonView;

@end

@interface PLVLCLikeButtonView : UIView

@property (nonatomic, assign) NSUInteger likeCount;

@property (nonatomic, weak) id<PLVLCLikeButtonViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
