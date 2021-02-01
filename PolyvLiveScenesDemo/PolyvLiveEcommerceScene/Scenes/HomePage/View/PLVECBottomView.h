//
//  PLVECBottomView.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/28.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVECBottomView;

@interface PLVECBottomView : UIView

@property (nonatomic, copy) void(^closeButtonActionBlock)(PLVECBottomView *view);

@end

NS_ASSUME_NONNULL_END
