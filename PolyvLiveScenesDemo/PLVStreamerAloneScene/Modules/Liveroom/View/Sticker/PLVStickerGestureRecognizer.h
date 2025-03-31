//
//  PLVStickerGestureRecognizer.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/3/17.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVStickerGestureRecognizer : UIGestureRecognizer

@property (nonatomic, weak) UIView *anchorView;

- (instancetype)initWithTarget:(nullable id)target action:(nullable SEL)action anchorView:(UIView *)anchorView;

@end

NS_ASSUME_NONNULL_END
