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

/// 主页创建/更新回放viewModel之后，通知横屏聊天室
- (void)updatePlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)playbackViewModel;

- (void)updateChatTableView;

@end

NS_ASSUME_NONNULL_END
