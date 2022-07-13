//
//  PLVLCCardPushPopupView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2022/7/6.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PLVLCCardPushPopupDirection) {
    PLVLCCardPushPopupDirectionTop = 0,
    PLVLCCardPushPopupDirectionLeft
};

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCCardPushPopupView : UIView

@property (nonatomic, strong, readonly) UILabel *titleLabel;

- (void)setPopupViewDirection:(PLVLCCardPushPopupDirection)popupDirection;

- (void)setPopupViewTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
