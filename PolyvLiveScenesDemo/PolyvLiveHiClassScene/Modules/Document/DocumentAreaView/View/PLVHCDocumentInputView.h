//
//  PLVHCDocumentInputView.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/30.
//  Copyright © 2021 polyv. All rights reserved.
// 画板文字输入视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCDocumentInputView : UIView

// 文字输入回调，inputText可为空
@property (nonatomic, copy) void (^documentInputCompleteHandler)(NSString * _Nullable inputText);

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
