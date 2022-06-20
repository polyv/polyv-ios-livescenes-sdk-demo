//
//  PLVLCChatLandscapeView.h
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/7/31.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVLCChatroomPlaybackViewModel;

@interface PLVLCChatLandscapeView : UIView

- (void)updatePlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)playbackViewModel;

@end

NS_ASSUME_NONNULL_END
