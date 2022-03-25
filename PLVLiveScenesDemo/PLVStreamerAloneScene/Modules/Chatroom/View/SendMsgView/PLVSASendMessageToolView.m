//
//  PLVSASendMessageToolView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSASendMessageToolView.h"

// UI
#import "PLVSASendMessageTextView.h"

// Utils
#import "PLVSAUtils.h"

// SDK
#import <PLVFoundationSDK/PLVFdUtil.h>
#import <PLVFoundationSDK/PLVColorUtil.h>

@implementation PLVSASendMessageToolView

#pragma mark - [ Life Cycle ]

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

#pragma mark - [ Override ]

- (void)layoutSubviews {
    
    CGFloat margin = 8;
    CGFloat safeLeft = [PLVSAUtils sharedUtils].areaInsets.left;
    CGFloat safeRight = [PLVSAUtils sharedUtils].areaInsets.right;
    CGFloat otherViewWith = 28 * 2 + margin *3 + safeRight;
    CGFloat textViewBgViewLeft = safeLeft + margin;
    CGFloat textViewBgWidth = self.bounds.size.width - textViewBgViewLeft - otherViewWith;
    CGFloat emojiButtonLeft = textViewBgViewLeft + textViewBgWidth + margin;
    
    if ([PLVSAUtils sharedUtils].isLandscape) {
        otherViewWith = 28 * 2 + margin *3 + 64;
        textViewBgViewLeft = safeLeft + 131;
        emojiButtonLeft = safeLeft + 57;
        textViewBgWidth = self.bounds.size.width - emojiButtonLeft - otherViewWith - safeRight - 60;
    }
    
    self.emojiButton.frame = CGRectMake(emojiButtonLeft, margin, 28, 28);
    self.imageButton.frame = CGRectMake(CGRectGetMaxX(self.emojiButton.frame) + margin, margin, 28, 28);
    
    self.textViewBgView.frame = CGRectMake(textViewBgViewLeft, 6, textViewBgWidth, 32);
    self.textView.frame = CGRectMake(margin, 0, textViewBgWidth - 2 * 12, 32);
    
    self.sendButton.hidden = ![PLVSAUtils sharedUtils].isLandscape;
    self.sendButton.frame = CGRectMake(CGRectGetMaxX(self.textViewBgView.frame) + margin, 6, 64, 32);
    self.sendButtonLayer.frame = self.sendButton.bounds;
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (UIButton *)emojiButton {
    if (!_emojiButton) {
        _emojiButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _emojiButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        UIImage *image = [PLVSAUtils imageForChatroomResource:@"plvsa_chatroom_btn_emoji"];
        [_emojiButton setImage:image forState:UIControlStateNormal];
        [_emojiButton addTarget:self action:@selector(emojiButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _emojiButton;
}

- (UIButton *)imageButton {
    if (!_imageButton) {
        _imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _imageButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        UIImage *image = [PLVSAUtils imageForToolbarResource:@"plvsa_toolbar_btn_image"];
        [_imageButton setImage:image forState:UIControlStateNormal];
        [_imageButton addTarget:self action:@selector(imageButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _imageButton;
}

- (UIButton *)sendButton {
    if (!_sendButton) {
        _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _sendButton.layer.cornerRadius = 16;
        _sendButton.layer.masksToBounds = YES;
        _sendButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_sendButton setTitleColor:PLV_UIColorFromRGB(@"#F0F1F5") forState:UIControlStateNormal];
        [_sendButton setTitle:@"发送" forState:UIControlStateNormal];
        [_sendButton.layer insertSublayer:self.sendButtonLayer atIndex:0];
        [_sendButton addTarget:self action:@selector(sendButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendButton;
}

- (CAGradientLayer *)sendButtonLayer {
    if (!_sendButtonLayer) {
        _sendButtonLayer = [CAGradientLayer layer];
        _sendButtonLayer.colors = @[(__bridge id)PLV_UIColorFromRGB(@"#0080FF").CGColor, (__bridge id)PLV_UIColorFromRGB(@"#3399FF").CGColor];
        _sendButtonLayer.locations = @[@0.5, @1.0];
        _sendButtonLayer.startPoint = CGPointMake(0, 0);
        _sendButtonLayer.endPoint = CGPointMake(1.0, 0);
    }
    return _sendButtonLayer;
}

- (UIView *)textViewBgView {
    if (!_textViewBgView) {
        _textViewBgView = [[UIView alloc] init];
        _textViewBgView.layer.masksToBounds = YES;
        _textViewBgView.layer.cornerRadius = 4;
        _textViewBgView.backgroundColor = [UIColor colorWithRed:70/255.0 green:70/255.0 blue:70/255.0 alpha:0.5/1.0];
    }
    return _textViewBgView;
}

- (PLVSASendMessageTextView *)textView {
    if (!_textView) {
        _textView = [[PLVSASendMessageTextView alloc] init];
    }
    return _textView;
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
