//
//  PLVECNewMessageView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/6.
//  Copyright © 2020 PLV. All rights reserved.
// 

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVECNewMessageView : UIView

/// 点击手势的回调
@property (nonatomic, copy) void(^tapActionHandler)(void);

/// 显示横幅
- (void)show;

/// 隐藏横幅
- (void)hidden;

@end

NS_ASSUME_NONNULL_END
