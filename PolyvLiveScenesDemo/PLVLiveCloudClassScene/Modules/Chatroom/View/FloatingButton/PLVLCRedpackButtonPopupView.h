//
//  PLVLCRedpackButtonPopupView.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2023/1/13.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCRedpackButtonPopupView : UIView

@property (nonatomic, assign, readonly) CGSize caculateSize;

/// 初始化方法
/// @param string 气泡内部Label文案
- (instancetype)initWithLabelString:(NSString *)string isLandscape:(BOOL)isLandscape;

@end

NS_ASSUME_NONNULL_END
