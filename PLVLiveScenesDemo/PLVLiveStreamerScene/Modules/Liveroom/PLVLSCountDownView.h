//
//  PLVLSCountDownView.h
//  PLVCloudClassStreamerDemo
//
//  Created by Lincal on 2019/10/17.
//  Copyright © 2019 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 倒计时视图
@interface PLVLSCountDownView : UIView

/// 倒计时结束
@property (nonatomic, strong) void (^countDownCompletedBlock) (void);

/// 开始倒计时
- (void)startCountDownOnView:(UIView *)container;

@end

NS_ASSUME_NONNULL_END
