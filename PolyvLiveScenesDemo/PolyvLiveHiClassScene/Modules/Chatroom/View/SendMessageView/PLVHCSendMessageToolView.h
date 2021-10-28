//
//  PLVHCSendMessageToolView.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/28.
//  Copyright © 2021 polyv. All rights reserved.
//  发送消息视图 - 工具栏

#import <UIKit/UIKit.h>
#import "PLVRoomUser.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVHCSendMessageTextView;

@interface PLVHCSendMessageToolView : UIView

#pragma mark UI
/// view hierarchy
///
/// (UIView) superview
///  └── (PLVHCSendMessageToolView) self (lowest)
///    └── (UIView) leftView
///         ├── (UIButton) emojiButton
///         ├── (UIButton) imageButton
///         └── (UIView) textViewBgView
///                └── (PLVHCSendMessageTextView) textView

@property (nonatomic, strong) UIButton *emojiButton;
@property (nonatomic, strong) UIButton *imageButton;
@property (nonatomic, strong) UIView *textViewBgView;
@property (nonatomic, strong) PLVHCSendMessageTextView *textView;

#pragma mark 回调
@property (nonatomic, copy) void(^didTapEmojiButton)(BOOL selected);
@property (nonatomic, copy) void(^didTapImagePickerButton)(void);

@end

NS_ASSUME_NONNULL_END
