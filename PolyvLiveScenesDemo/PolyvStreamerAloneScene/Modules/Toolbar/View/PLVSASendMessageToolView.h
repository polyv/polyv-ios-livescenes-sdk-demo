//
//  PLVSASendMessageToolView.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/5/26.
//  Copyright © 2021 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVSASendMessageTextView;

@interface PLVSASendMessageToolView : UIView

/// UI
@property (nonatomic, strong) UIView *textViewBgView;
@property (nonatomic, strong) PLVSASendMessageTextView *textView;
@property (nonatomic, strong) UIButton *emojiButton;
@property (nonatomic, strong) UIButton *imageButton;
@property (nonatomic, strong) UIButton *sendButton;
/// 回调
@property (nonatomic, copy) void(^didTapSendButton)(void);
@property (nonatomic, copy) void(^didTapEmojiButton)(BOOL selected);
@property (nonatomic, copy) void(^didTapImagePickerButton)(void);


@end

NS_ASSUME_NONNULL_END
