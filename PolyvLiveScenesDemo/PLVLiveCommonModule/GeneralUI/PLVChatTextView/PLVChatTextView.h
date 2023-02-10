//
//  PLVChatTextView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2019/11/12.
//  Copyright © 2021 PLV. All rights reserved.
//
// 自定义UITextView子类，可识别文本中的链接并高亮加下划线显示，
// 不支持滚动、不支持编辑、不支持长按文本出现菜单UIMenuController

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVChatTextView : UITextView

/// 设置显示文本
/// @param attributedString 待显示的多属性文本
/// @param showUrl YES-识别文本中链接并高亮加下划线显示
- (void)setContent:(NSMutableAttributedString *)attributedString showUrl:(BOOL)showUrl;

@end

NS_ASSUME_NONNULL_END
