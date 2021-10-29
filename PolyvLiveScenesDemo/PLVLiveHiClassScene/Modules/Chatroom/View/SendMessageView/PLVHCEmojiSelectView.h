//
//  PLVHCEmojiSelectView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/28.
//  Copyright © 2021 PLV. All rights reserved.
// 发送消息视图 - 表情视图

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVEmoticon;
@class PLVHCEmojiSelectView;

typedef NS_ENUM(NSUInteger, PLVHCEmojiSelectViewEvent) {
    PLVHCEmojiSelectViewEventSend,
    PLVHCEmojiSelectViewEventDelete
};

@protocol PLVHCEmojiSelectViewDelegate <NSObject>

- (void)emojiSelectView:(PLVHCEmojiSelectView *)emojiSelectView didSelectEmoticon:(PLVEmoticon *)emoticon;

- (void)emojiSelectView:(PLVHCEmojiSelectView *)emojiSelectView didReceiveEvent:(PLVHCEmojiSelectViewEvent)event;

@end

@interface PLVHCEmojiSelectView : UIView

@property (nonatomic, weak) id<PLVHCEmojiSelectViewDelegate> delegate;

- (void)sendButtonEnable:(BOOL)enable;

@end

NS_ASSUME_NONNULL_END
