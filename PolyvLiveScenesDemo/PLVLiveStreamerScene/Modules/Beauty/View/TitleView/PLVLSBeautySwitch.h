//
//  PLVLSBeautySwitch.h
//  PolyvLiveScenesDemo
//
//  Created by JTom on 2022/4/14.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class  PLVLSBeautySwitch;
@protocol PLVLSBeautySwitchDelegate <NSObject>

- (void)beautySwitch:(PLVLSBeautySwitch *)beautySwitch didChangeOn:(BOOL)on;

@end

@interface PLVLSBeautySwitch : UIView

@property (nonatomic, weak) id<PLVLSBeautySwitchDelegate> delegate;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UISwitch *beautySwitch;

@property(nonatomic,getter=isOn) BOOL on;

@end

NS_ASSUME_NONNULL_END
