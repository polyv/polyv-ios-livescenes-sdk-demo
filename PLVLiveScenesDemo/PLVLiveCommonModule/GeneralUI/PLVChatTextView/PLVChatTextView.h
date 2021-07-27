//
//  PLVChatTextView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2019/11/12.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVChatTextView : UITextView

@property (nonatomic, assign) BOOL showMenu;

@property (nonatomic, copy) void(^ _Nullable replyHandler)(void);

- (void)setContent:(NSMutableAttributedString *)attributedString showUrl:(BOOL)showUrl;

- (CGSize)setContent:(NSAttributedString *)attributedString
            fontSize:(CGFloat)contentFontSize
             showUrl:(BOOL)showUrl
               width:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
