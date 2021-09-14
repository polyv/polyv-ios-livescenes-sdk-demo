//
//  PLVSlideRightTipsView.h
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/5/31.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVSASlideRightTipsView : UIView
/// 关闭按钮触发回调
@property (nonatomic, copy) void(^closeButtonHandler)(void);

@end

NS_ASSUME_NONNULL_END
