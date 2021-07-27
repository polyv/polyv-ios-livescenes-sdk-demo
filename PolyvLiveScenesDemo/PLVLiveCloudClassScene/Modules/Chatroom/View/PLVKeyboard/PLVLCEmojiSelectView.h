//
//  PLVEmojiSelectView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/27.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVEmoticon;

@protocol PLVLCEmojiSelectViewDelegate

@required

- (void)selectEmoji:(PLVEmoticon *)emojiModel;

- (void)deleteEmoji;

- (void)sendEmoji;

@end


@interface PLVLCEmojiSelectView : UIView

@property (nonatomic, weak) id<PLVLCEmojiSelectViewDelegate> delegate;

- (void)sendButtonEnable:(BOOL)enable;

@end
