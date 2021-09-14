//
//  PLVLSDocumentInputView.h
//  PLVCloudClassStreamerModul
//
//  Created by MissYasiky on 2019/12/18.
//  Copyright © 2019 easefun. All rights reserved.
//  PPT文字输入视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSDocumentInputView : UIView

@property (nonatomic, copy) void (^documentInputCompleteHandler)(NSString *inputText);

/// 显示视图
///
/// @param content 文字内容
/// @param hexColor 文字颜色
/// @param vctrl 待展示的父视图VC
- (void)presentWithText:(NSString *)content
              textColor:(NSString *)hexColor
       inViewController:(UIViewController *)vctrl;

/// 隐藏视图
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
