//
//  PLVSALinkMicLayoutSwitchGuideView.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/11/10.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 连麦布局切换新手引导
@interface PLVSALinkMicLayoutSwitchGuideView : UIView

/// 显示、隐藏连麦布局切换新手引导
/// @param show YES：显示，NO：隐藏
- (void)showLinkMicLayoutSwitchGuide:(BOOL)show;

@end

NS_ASSUME_NONNULL_END
