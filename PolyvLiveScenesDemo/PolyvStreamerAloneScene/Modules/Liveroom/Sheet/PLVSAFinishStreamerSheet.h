//
//  PLVSAFinishStreamerSheet.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/11.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVSABottomSheet.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVSAFinishStreamerSheet : PLVSABottomSheet

- (void)showInView:(UIView *)parentView finishAction:(void (^)(void))finishHandler;

@end

NS_ASSUME_NONNULL_END
