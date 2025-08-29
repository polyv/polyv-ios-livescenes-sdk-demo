//
//  PLVStickerImageView.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/3/17.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVStickerImageView;

@protocol PLVStickerImageViewDelegate <NSObject>

@optional

- (void)plv_StickerViewDidTapContentView:(PLVStickerImageView *)stickerView;
- (void)plv_StickerViewHandleMove:(PLVStickerImageView *)stickerView point:(CGPoint)point gestureEnded:(BOOL)ended;
// 新增：Done按钮点击回调
- (void)plv_StickerViewDidTapDoneButton:(PLVStickerImageView *)stickerView;

@end

@interface PLVStickerImageView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, weak, nullable) id<PLVStickerImageViewDelegate> delegate;
@property (nonatomic, assign) CGFloat stickerMinScale;
@property (nonatomic, assign) CGFloat stickerMaxScale;
@property (nonatomic, assign) BOOL enabledControl;
@property (nonatomic, assign) BOOL enabledShakeAnimation;
@property (nonatomic, assign) BOOL enabledBorder;
@property (nonatomic, assign) BOOL enableEdit;
@property (nonatomic, strong, nullable) UIImage *contentImage;

- (instancetype)initWithFrame:(CGRect)frame contentImage:(UIImage *)contentImage;
- (void)performTapOperation;


@end

NS_ASSUME_NONNULL_END
