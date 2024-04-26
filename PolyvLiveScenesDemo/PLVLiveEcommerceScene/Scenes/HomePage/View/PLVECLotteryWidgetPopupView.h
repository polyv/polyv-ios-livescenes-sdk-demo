//
//  PLVECLotteryWidgetPopupView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/7/12.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVECLotteryWidgetPopupView : UIView

@property (nonatomic, strong, readonly) UILabel *titleLabel;

- (void)setPopupViewTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
