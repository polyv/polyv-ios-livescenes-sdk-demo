//
//  PLVSALinkMicMenuPopup.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/5/9.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVSALinkMicMenuPopup : UIView

@property (nonatomic, copy) void(^ _Nullable dismissHandler)(void);

@property (nonatomic, copy) void(^ _Nullable videoLinkMicButtonHandler)(void);

@property (nonatomic, copy) void(^ _Nullable audioLinkMicButtonHandler)(void);

- (instancetype)initWithMenuFrame:(CGRect)frame buttonFrame:(CGRect)buttonFrame;

- (void)showAtView:(UIView *)superView;

- (void)dismiss;

- (void)resetStatus;

- (void)refreshWithMenuFrame:(CGRect)frame buttonFrame:(CGRect)buttonFrame;

@end

NS_ASSUME_NONNULL_END
