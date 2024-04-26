//
//  PLVLSSipView.h
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2022/3/25.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLSSipView;

@protocol PLVLSSipViewDelegate <NSObject>

/// SIP有新的来电
- (void)newCallingInSipView:(PLVLSSipView *)sipView;

@end

@interface PLVLSSipView : UIView

@property (nonatomic, weak) id<PLVLSSipViewDelegate> delegate;

/// 显示SIP来电提醒
- (void)showNewIncomingTelegramView;

@end

NS_ASSUME_NONNULL_END
