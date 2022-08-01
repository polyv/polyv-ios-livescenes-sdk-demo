//
//  PLVECCardPushButtonPopupView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2022/7/13.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVECCardPushButtonPopupView : UIView

@property (nonatomic, strong, readonly) UILabel *titleLabel;

- (void)setPopupViewTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
