//
//  PLVEmojiSelectView.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/27.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PLVEmoticon;

@protocol PLVEmojiSelectViewDelegate

@required

- (void)selectEmoji:(PLVEmoticon *)emojiModel;

- (void)deleteEmoji;

- (void)sendEmoji;

@end


@interface PLVEmojiSelectView : UIView

@property (nonatomic, weak) id<PLVEmojiSelectViewDelegate> delegate;

- (void)sendButtonEnable:(BOOL)enable;

@end
