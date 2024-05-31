//
//  PLVStreamerInteractGenericView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2024/5/13.
//  Copyright © 2024 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVStreamerInteractGenericView : UIView

/// 加载互动 WebView
- (void)loadInteractWebView;

/// 打开互动应用弹窗
/// @param eventName 事件名称，由 JS 传递过来。
- (void)openInteractViewWithEventName:(NSString *)eventName;

@end

NS_ASSUME_NONNULL_END
