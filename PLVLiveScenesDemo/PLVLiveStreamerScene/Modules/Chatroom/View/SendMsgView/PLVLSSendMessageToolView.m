//
//  PLVLSSendMessageToolView.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/21.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSSendMessageToolView.h"
#import "PLVLSSendMessageTextView.h"
#import "PLVLSUtils.h"
#import <PLVFoundationSDK/PLVFdUtil.h>
#import <PLVFoundationSDK/PLVColorUtil.h>

@implementation PLVLSSendMessageToolView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0x31/255.0 green:0x35/255.0 blue:0x40/255.0 alpha:1];
        
        [self addSubview:self.emojiButton];
        [self addSubview:self.imageButton];
        [self addSubview:self.textViewBgView];
        [self addSubview:self.sendButton];
        [self.textViewBgView addSubview:self.textView];
    
        [self.textView addGestureRecognizer:self.tapGesture];
    }
    return self;
}

- (void)layoutSubviews {
    CGFloat horizontalSafePad = PLVLSUtils.safeSidePad;
    
    self.emojiButton.frame = CGRectMake(horizontalSafePad - 8, 0, 40, 44);
    self.imageButton.frame = CGRectMake(CGRectGetMaxX(self.emojiButton.frame), 0, 40, 44);
    self.sendButton.frame = CGRectMake(self.bounds.size.width - horizontalSafePad - 64, 6, 64, 32);
    
    CGFloat textViewBgOriginX = CGRectGetMaxX(self.imageButton.frame) + 8;
    CGFloat textViewBgWidth = self.sendButton.frame.origin.x - 16 - textViewBgOriginX;
    self.textViewBgView.frame = CGRectMake(textViewBgOriginX, 6, textViewBgWidth, 32);
    self.textView.frame = CGRectMake(12, 0, textViewBgWidth - 2 * 12, 32);
}

#pragma mark - Getter

- (UIButton *)emojiButton {
    if (!_emojiButton) {
        _emojiButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [PLVLSUtils imageForChatroomResource:@"plvls_emoji_btn"];
        [_emojiButton setImage:image forState:UIControlStateNormal];
        [_emojiButton addTarget:self action:@selector(emojiButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _emojiButton;
}

- (UIButton *)imageButton {
    if (!_imageButton) {
        _imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [PLVLSUtils imageForChatroomResource:@"plvls_image_btn"];
        [_imageButton setImage:image forState:UIControlStateNormal];
        [_imageButton addTarget:self action:@selector(imageButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _imageButton;
}

- (UIView *)textViewBgView {
    if (!_textViewBgView) {
        _textViewBgView = [[UIView alloc] init];
        _textViewBgView.layer.masksToBounds = YES;
        _textViewBgView.layer.cornerRadius = 16.0;
        _textViewBgView.backgroundColor = [UIColor colorWithRed:0x47/255.0 green:0x4b/255.0 blue:0x57/255.0 alpha:1];
    }
    return _textViewBgView;
}

- (PLVLSSendMessageTextView *)textView {
    if (!_textView) {
        _textView = [[PLVLSSendMessageTextView alloc] init];
    }
    return _textView;
}

- (UIButton *)sendButton {
    if (!_sendButton) {
        _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _sendButton.layer.cornerRadius = 16;
        _sendButton.layer.masksToBounds = YES;
        _sendButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_sendButton setTitleColor:[UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1] forState:UIControlStateNormal];
        [_sendButton setTitle:@"发送" forState:UIControlStateNormal];
        UIImage *enableImage = [PLVColorUtil createImageWithColor:[UIColor colorWithRed:0x43/255.0 green:0x99/255.0 blue:0xff/255.0 alpha:1]];
        UIImage *disableImage = [PLVColorUtil createImageWithColor:[UIColor colorWithRed:0x73/255.0 green:0xb3/255.0 blue:0xff/255.0 alpha:1]];
        [_sendButton setBackgroundImage:enableImage forState:UIControlStateNormal];
        [_sendButton setBackgroundImage:disableImage forState:UIControlStateDisabled];
        [_sendButton addTarget:self action:@selector(sendButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendButton;
}

- (UITapGestureRecognizer *)tapGesture {
    if (!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textViewTapGestureRecognizer)];
        _tapGesture.enabled = NO;
    }
    return _tapGesture;
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)emojiButtonAction {
    self.tapGesture.enabled = !self.emojiButton.selected;
    self.emojiButton.selected = !self.emojiButton.selected;
    if (self.didTapEmojiButton) {
        self.didTapEmojiButton(self.emojiButton.selected);
    }
}

- (void)imageButtonAction {
    if (self.didTapImagePickerButton) {
        self.didTapImagePickerButton();
    }
}

- (void)sendButtonAction {
    if (self.didTapSendButton) {
        self.didTapSendButton();
    }
}

- (void)textViewTapGestureRecognizer {
    if (self.emojiButton.selected) {
        [self emojiButtonAction];
    }
}

@end
