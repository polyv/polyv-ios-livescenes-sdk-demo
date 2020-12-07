//
//  PLVLCChatTextView.h
//  TextViewLink
//
//  Created by MissYasiky on 2019/11/12.
//  Copyright © 2019 MissYasiky. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLCChatTextView : UITextView

- (void)setContent:(NSMutableAttributedString *)attributedString showUrl:(BOOL)showUrl;

- (CGSize)setContent:(NSAttributedString *)attributedString
            fontSize:(CGFloat)contentFontSize
             showUrl:(BOOL)showUrl
               width:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
