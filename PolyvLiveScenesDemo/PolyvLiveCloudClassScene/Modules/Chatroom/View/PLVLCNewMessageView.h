//
//  PLVLCNewMessageView.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/6.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCNewMessageView : UIView

/// 更新文案上的消息数
- (void)updateMeesageCount:(NSUInteger)count;

/// 显示横幅
- (void)show;

/// 隐藏横幅
- (void)hidden;

@end

NS_ASSUME_NONNULL_END
