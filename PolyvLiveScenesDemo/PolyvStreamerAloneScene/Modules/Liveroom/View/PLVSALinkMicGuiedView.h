//
//  PLVSALinkMicGuiedView.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/10.
//  Copyright © 2021 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 连麦操作新手引导
@interface PLVSALinkMicGuiedView : UIView

/// 显示、隐藏连麦新手引导
/// @param show YES：显示，NO：隐藏
- (void)showLinMicGuied:(BOOL)show;

@end

NS_ASSUME_NONNULL_END
