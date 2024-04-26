//
//  PLVECChatroomMessageView.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/8/3.
//  Copyright © 2023 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 聊天室消息类型
typedef NS_ENUM(NSInteger, PLVECChatroomMessageViewType) {
    PLVECChatroomMessageViewTypeNormal,     // 正常聊天消息
    PLVECChatroomMessageViewTypeAskQuestion,   // 提问聊天状体啊
};

@class PLVECChatroomMessageView, PLVChatModel, PLVECChatroomPlaybackViewModel;

@protocol PLVECChatroomMessageViewDelegate <NSObject>

@optional

/// 需要回复消息的回调
/// @param replyModel 引用回复消息，可为空
- (void)chatroomMessageView:(PLVECChatroomMessageView *)messageView replyChatModel:(PLVChatModel * _Nullable)replyModel;

/// 聊天室消息视图类型改变的回调
/// @param messageView 聊天室消息视图
/// @param type 消息视图类型
- (void)chatroomMessageView:(PLVECChatroomMessageView *)messageView messageViewTypeChanged:(PLVECChatroomMessageViewType)type;

/// 在点击超过500字符的长文本消息时会执行此回调
/// @param model 需要展示完整文本的长文本消息数据模型
- (void)chatroomMessageView:(PLVECChatroomMessageView *)messageView alertLongContentMessage:(PLVChatModel *)model;

@end
/*
 直播带货场景，聊天室消息容器
 */
@interface PLVECChatroomMessageView : UIView

@property (nonatomic, weak) id<PLVECChatroomMessageViewDelegate> delegate;

/// 聊天室消息视图类型
@property (nonatomic, assign, readonly) PLVECChatroomMessageViewType messageViewType;

/// 切换聊天室消息视图类型
- (void)switchMessageViewType:(PLVECChatroomMessageViewType)type;

- (void)updatePlaybackViewModel:(PLVECChatroomPlaybackViewModel *)playbackViewModel;

@end

NS_ASSUME_NONNULL_END
