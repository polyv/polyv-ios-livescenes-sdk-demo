//
//  PLVLSSendMessageToolView.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/21.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVLSSendMessageTextView;

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSSendMessageToolView : UIView

/// UI
@property (nonatomic, strong) UIView *textViewBgView;
@property (nonatomic, strong) PLVLSSendMessageTextView *textView;
@property (nonatomic, strong) UIButton *emojiButton;
@property (nonatomic, strong) UIButton *imageButton;
@property (nonatomic, strong) UIButton *sendButton;
/// 回调
@property (nonatomic, copy) void(^didTapSendButton)(void);
@property (nonatomic, copy) void(^didTapEmojiButton)(BOOL selected);
@property (nonatomic, copy) void(^didTapImagePickerButton)(void);

@end

NS_ASSUME_NONNULL_END
