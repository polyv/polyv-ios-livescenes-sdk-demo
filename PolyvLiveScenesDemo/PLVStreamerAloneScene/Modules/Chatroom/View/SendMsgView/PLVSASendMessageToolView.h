//
//  PLVSASendMessageToolView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/26.
//  Copyright © 2021 PLV. All rights reserved.
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
//textView 的点击手势 当处于表情面板时点击切换输入法面板
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

/// 回调
@property (nonatomic, copy) void(^didTapSendButton)(void);
@property (nonatomic, copy) void(^didTapEmojiButton)(BOOL selected);
@property (nonatomic, copy) void(^didTapImagePickerButton)(void);


@end

NS_ASSUME_NONNULL_END
