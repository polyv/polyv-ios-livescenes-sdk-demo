//
//  PLVLCChatLandscapeView.h
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/7/31.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVChatModel, PLVLCChatroomPlaybackViewModel;

@protocol PLVLCChatLandscapeViewDelegate;

@interface PLVLCChatLandscapeView : UIView

@property (nonatomic, weak) id<PLVLCChatLandscapeViewDelegate> delegate;

/// 主页创建/更新回放viewModel之后，通知横屏聊天室
- (void)updatePlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)playbackViewModel;

- (void)updateChatTableView;

@end

@protocol PLVLCChatLandscapeViewDelegate <NSObject>

/// 在点击超过500字符的长文本消息时会执行此回调
/// @param model 需要展示完整文本的长文本消息数据模型
- (void)chatLandscapeView:(PLVLCChatLandscapeView *)chatView alertLongContentMessage:(PLVChatModel *)model;

@end

NS_ASSUME_NONNULL_END
