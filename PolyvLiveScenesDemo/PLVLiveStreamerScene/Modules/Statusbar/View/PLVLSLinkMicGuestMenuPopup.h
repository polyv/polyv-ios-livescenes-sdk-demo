//
//  PLVLSLinkMicGuestMenuPopup.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/5/18.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSLinkMicGuestMenuPopup : UIView

@property (nonatomic, copy) void(^ _Nullable dismissHandler)(void);

@property (nonatomic, copy) void(^cancelRequestLinkMicButtonHandler)(void);

@property (nonatomic, copy) void(^closeLinkMicButtonHandler)(void);

- (instancetype)initWithMenuFrame:(CGRect)frame buttonFrame:(CGRect)buttonFrame;

- (void)showAtView:(UIView *)superView;

- (void)updateMenuPopupInLinkMic:(BOOL)inLinkMic;

- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
