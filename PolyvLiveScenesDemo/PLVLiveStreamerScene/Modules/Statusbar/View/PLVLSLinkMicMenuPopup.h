//
//  PLVLSLinkMicMenuPopup.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/4/15.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSLinkMicMenuPopup : UIView

@property (nonatomic, copy) void(^ _Nullable dismissHandler)(void);

@property (nonatomic, copy) BOOL(^ _Nullable videoLinkMicButtonHandler)(BOOL start);

@property (nonatomic, copy) BOOL(^ _Nullable audioLinkMicButtonHandler)(BOOL start);

- (instancetype)initWithMenuFrame:(CGRect)frame buttonFrame:(CGRect)buttonFrame;

- (void)showAtView:(UIView *)superView;

- (void)dismiss;

- (void)resetStatus;

@end

NS_ASSUME_NONNULL_END
