//
//  PLVSAEmojiSelectView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVEmoticon;

typedef NS_ENUM(NSUInteger, PLVSAEmojiSelectViewEvent) {
    PLVSAEmojiSelectViewEventSend,
    PLVSAEmojiSelectViewEventDelete
};

@protocol PLVSAEmojiSelectViewDelegate <NSObject>

- (void)emojiSelectView_didSelectEmoticon:(PLVEmoticon *)emoticon;

- (void)emojiSelectView_didReceiveEvent:(PLVSAEmojiSelectViewEvent)event;

@end

@interface PLVSAEmojiSelectView : UIView

@property (nonatomic, weak) id<PLVSAEmojiSelectViewDelegate> delegate;

- (void)sendButtonEnable:(BOOL)enable;


@end

NS_ASSUME_NONNULL_END
