//
//  PLVLCLotteryWidgetPopupView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/7/12.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVLCLotteryWidgetPopupDirection) {
    PLVLCLotteryWidgetPopupDirectionTop = 0,
    PLVLCLotteryWidgetPopupDirectionLeft
};

@interface PLVLCLotteryWidgetPopupView : UIView

@property (nonatomic, strong, readonly) UILabel *titleLabel;

- (void)setPopupViewDirection:(PLVLCLotteryWidgetPopupDirection)popupDirection;

- (void)setPopupViewTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
