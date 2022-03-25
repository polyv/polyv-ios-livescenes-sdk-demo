//
//  PLVSALinkMicGuideView.h
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/6/10.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 连麦操作新手引导
@interface PLVSALinkMicGuideView : UIView

@property (nonatomic, assign, readonly) BOOL hadShowedLinkMicGuide; //是否显示过连麦引导
@property (nonatomic, assign, readonly) BOOL showingLinkMicGuide; //是否正在显示连麦引导

/// 更新连麦操作引导视图
/// @param superview 焦点视图的父视图
/// @param frame 焦点视图的坐标 需要添加Tip 提示到此位置
- (void)updateGuideViewWithSuperview:(UIView *)superview focusViewFrame:(CGRect)frame;

- (void)hideGuideView;

@end

NS_ASSUME_NONNULL_END
