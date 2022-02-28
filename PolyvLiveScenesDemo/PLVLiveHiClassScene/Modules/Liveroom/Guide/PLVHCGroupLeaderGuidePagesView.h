//
//  PLVHCGroupLeaderGuidePagesView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/11/1.
//  Copyright © 2021 PLV. All rights reserved.
// 组长引导页

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCGroupLeaderGuidePagesView : UIView

/// 显示引导页视图
/// @param view 引导页添加的视图
+ (void)showGuidePagesViewinView:(UIView *)view
                        endBlock:(void(^ _Nullable)(void))endBlock;

@end

NS_ASSUME_NONNULL_END
