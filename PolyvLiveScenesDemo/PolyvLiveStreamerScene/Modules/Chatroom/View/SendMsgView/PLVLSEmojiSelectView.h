//
//  PLVLSEmojiSelectView.h
//  PolyvLiveStreamerDemo
//
//  Created by ftao on 2019/11/13.
//  Copyright © 2019 easefun. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVEmoticon;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, PLVLSEmojiSelectViewEvent) {
    PLVLSEmojiSelectViewEventSend,
    PLVLSEmojiSelectViewEventDelete
};

@protocol PLVLSEmojiSelectViewProtocol <NSObject>

- (void)emojiSelectView_didSelectEmoticon:(PLVEmoticon *)emoticon;

- (void)emojiSelectView_didReceiveEvent:(PLVLSEmojiSelectViewEvent)event;

@end

@interface PLVLSEmojiSelectView : UIView

@property (nonatomic, weak) id<PLVLSEmojiSelectViewProtocol> delegate;

- (void)sendButtonEnable:(BOOL)enable;

@end

NS_ASSUME_NONNULL_END
