//
//  PLVHCSendMessageToolView.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/28.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCSendMessageToolView.h"

// 工具
#import "PLVHCUtils.h"

// UI
#import "PLVHCSendMessageTextView.h"

// 依赖库
#import <PLVFoundationSDK/PLVFdUtil.h>
#import <PLVFoundationSDK/PLVColorUtil.h>

@interface PLVHCSendMessageToolView()

@end

@implementation PLVHCSendMessageToolView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#242A40"];
        
        [self addSubview:self.emojiButton];
        [self addSubview:self.imageButton];
        [self addSubview:self.textViewBgView];
        
        [self.textViewBgView addSubview:self.textView];
    }
    return self;
}

- (void)layoutSubviews {
    CGFloat horizontalSafePad = [PLVHCUtils sharedUtils].areaInsets.left + 57;
    
    self.emojiButton.frame = CGRectMake(horizontalSafePad - 8, 6, 32, 32);
    self.imageButton.frame = CGRectMake(CGRectGetMaxX(self.emojiButton.frame), 6, 32, 32);
    
    CGFloat textViewBgOriginX = CGRectGetMaxX(self.imageButton.frame) + 8;
    CGFloat textViewBgWidth = self.bounds.size.width - textViewBgOriginX - 53;
    self.textViewBgView.frame = CGRectMake(textViewBgOriginX, 6, textViewBgWidth, 32);
    self.textView.frame = CGRectMake(12, 0, textViewBgWidth - 2 * 12, 32);
    
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (UIButton *)emojiButton {
    if (!_emojiButton) {
        _emojiButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _emojiButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_emojiButton setImage:[PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_btn_emoji"] forState:UIControlStateNormal];
        [_emojiButton setImage:[PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_btn_emoji_focused"] forState:UIControlStateHighlighted];
        [_emojiButton addTarget:self action:@selector(emojiButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _emojiButton;
}

- (UIButton *)imageButton {
    if (!_imageButton) {
        _imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _imageButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_imageButton setImage:[PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_btn_image"] forState:UIControlStateNormal];
        [_imageButton setImage:[PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_btn_image_focused"] forState:UIControlStateHighlighted];
        [_imageButton addTarget:self action:@selector(imageButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _imageButton;
}

- (UIView *)textViewBgView {
    if (!_textViewBgView) {
        _textViewBgView = [[UIView alloc] init];
        _textViewBgView.layer.masksToBounds = YES;
        _textViewBgView.layer.cornerRadius = 16;
        _textViewBgView.backgroundColor = [PLVColorUtil colorFromHexString:@"#2D3452"];
    }
    return _textViewBgView;
}

- (PLVHCSendMessageTextView *)textView {
    if (!_textView) {
        _textView = [[PLVHCSendMessageTextView alloc] init];
        _textView.backgroundColor = [PLVColorUtil colorFromHexString:@"#2D3452"];
    }
    return _textView;
}

#pragma mark Action

- (void)emojiButtonAction {
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

@end
