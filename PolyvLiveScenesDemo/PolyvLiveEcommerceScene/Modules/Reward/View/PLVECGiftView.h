//
//  PLVECGiftView.h
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/30.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 打赏礼物视图
@interface PLVECGiftView : UIView

- (void)showGiftAnimation:(NSString *)userName giftName:(NSString *)giftName giftType:(NSString *)giftType;

@end

NS_ASSUME_NONNULL_END
