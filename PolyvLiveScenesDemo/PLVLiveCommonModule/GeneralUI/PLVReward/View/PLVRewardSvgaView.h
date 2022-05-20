//
//  PLVRewardSvgaView.h
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/8/30.
//  Copyright © 2021 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

/// svga动画播放完毕后，视图被销毁的回调
typedef void (^PLVRewardSvgaViewWillRemovedBlock)(void);

NS_ASSUME_NONNULL_BEGIN

@interface PLVRewardSvgaView : UIView

@property (nonatomic, strong) PLVRewardSvgaViewWillRemovedBlock willRemoveBlock;

- (void)parseWithRewardItemName:(NSString *)name
                     completion:(void(^)(void))completion;

@end

NS_ASSUME_NONNULL_END


