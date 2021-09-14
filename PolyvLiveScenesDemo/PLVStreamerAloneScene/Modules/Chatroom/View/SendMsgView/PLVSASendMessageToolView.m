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
        [self.textViewBgView addSubview:self.textView];
        
        [self.textView addGestureRecognizer:self.tapGesture];
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    
    CGFloat margin = 8;
    self.imageButton.frame = CGRectMake(self.bounds.size.width -  margin - 28, margin, 28, 28);
    self.emojiButton.frame = CGRectMake(CGRectGetMinX(self.imageButton.frame) - 28 - margin, margin, 28, 28);
    
    CGFloat textViewBgWidth = self.emojiButton.frame.origin.x - margin *2 ;
    self.textViewBgView.frame = CGRectMake(margin, 6, textViewBgWidth, 32);
    self.textView.frame = CGRectMake(margin, 0, textViewBgWidth - 2 * 12, 32);
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (UIButton *)emojiButton {
    if (!_emojiButton) {
        _emojiButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _emojiButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        UIImage *image = [PLVSAUtils imageForToolbarResource:@"plvsa_toolbar_btn_emoji"];
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

- (void)textViewTapGestureRecognizer {
    if (self.emojiButton.selected) {
        [self emojiButtonAction];
    }
}

@end
