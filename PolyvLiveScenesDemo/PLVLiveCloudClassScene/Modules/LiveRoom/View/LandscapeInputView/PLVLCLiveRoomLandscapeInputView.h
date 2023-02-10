//
//  PLVLCLiveRoomLandscapeInputView.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/10/16.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVChatModel;

@protocol PLVLCLiveRoomLandscapeInputViewDelegate;

/// 直播间横屏输入视图
@interface PLVLCLiveRoomLandscapeInputView : UIView

/// delegate
@property (nonatomic, weak) id <PLVLCLiveRoomLandscapeInputViewDelegate> delegate;

- (void)showInputView:(BOOL)show;

/// 显示引用回复某条消息的输入视图
- (void)showWithReplyChatModel:(PLVChatModel *)model;

@end

@protocol PLVLCLiveRoomLandscapeInputViewDelegate <NSObject>

- (void)plvLCLiveRoomLandscapeInputView:(PLVLCLiveRoomLandscapeInputView *)inputView
       SendButtonClickedWithSendContent:(NSString *)sendContent
                             replyModel:(PLVChatModel *)replyModel;

@end


NS_ASSUME_NONNULL_END
