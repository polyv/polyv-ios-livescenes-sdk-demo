//
//  PLVHCEmojiSelectSheet.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/29.
//  Copyright © 2021 polyv. All rights reserved.
// 聊天室 emoji表情弹层

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVEmoticon;
@class PLVHCEmojiSelectSheet;

typedef NS_ENUM(NSUInteger, PLVHCEmojiSelectSheetEvent) {
    PLVHCEmojiSelectSheetEventSend,
    PLVHCEmojiSelectSheetEventDelete
};

@protocol PLVHCEmojiSelectSheetDelegate <NSObject>

@optional

- (void)emojiSelectSheet:(PLVHCEmojiSelectSheet *)sheet didSelectEmoticon:(PLVEmoticon *)emoticon;

- (void)emojiSelectSheet:(PLVHCEmojiSelectSheet *)sheet didReceiveEvent:(PLVHCEmojiSelectSheetEvent)event;

@end

/// emoji表情弹层
@interface PLVHCEmojiSelectSheet : UIView

@property (nonatomic, weak) id<PLVHCEmojiSelectSheetDelegate> delegate;

- (void)sendButtonEnable:(BOOL)enable;

@end

NS_ASSUME_NONNULL_END
