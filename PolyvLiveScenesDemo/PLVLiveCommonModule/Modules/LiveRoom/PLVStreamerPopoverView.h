//
//  PLVStreamerPopoverView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2024/5/13.
//  Copyright © 2024 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVStreamerInteractGenericView.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVStreamerPopoverView : UIView

/// 互动视图
@property (nonatomic, strong, readonly) PLVStreamerInteractGenericView *interactView;

@end

NS_ASSUME_NONNULL_END
