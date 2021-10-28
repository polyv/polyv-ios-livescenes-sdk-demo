//
//  PLVHCChatroomToolView.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/28.
//  Copyright © 2021 polyv. All rights reserved.
// 聊天室 底部工具视图

#import <UIKit/UIKit.h>
#import "PLVRoomUser.h"

NS_ASSUME_NONNULL_BEGIN

@class PLVHCChatroomToolView;
@class PLVEmoticon;
@class PLVHCSendMessageTextView;

@protocol PLVHCChatroomToolViewDelegate <NSObject>

@optional

/// 点击emoji表情按钮回调
- (void)chatroomToolViewDidTapEmojiButton:(PLVHCChatroomToolView *)chatroomToolView emojiButtonSelected:(BOOL)selected;

/// 点击图片按钮回调
- (void)chatroomToolViewDidTapImageButton:(PLVHCChatroomToolView *)chatroomToolView;

/// 点击聊天按钮回调
- (void)chatroomToolViewDidTapChatButton:(PLVHCChatroomToolView *)chatroomToolView  emojiAttrStr:(NSAttributedString *)emojiAttrStr;

/// 点击关闭直播间按钮回调
/// @note 只有特殊身份登录（譬如讲师）方可使用
- (void)chatroomToolViewDidTapCloseRoomButton:(PLVHCChatroomToolView *)chatroomToolView closeRoomButtonSelected:(BOOL)selected;

@end


/// 聊天室底部工具视图
@interface PLVHCChatroomToolView : UIView

@property (nonatomic, weak)id<PLVHCChatroomToolViewDelegate> delegate;

/// 输入框
@property (nonatomic, strong) PLVHCSendMessageTextView *textView;

/// 开始直播
- (void)startClass;

/// 结束直播
- (void)finishClass;

/// 选择emoji表情
/// @param emoticon 表情模型
- (void)emojiDidSelectEmoticon:(PLVEmoticon *)emoticon;

/// 删除emoji表情
- (void)emojiDidDelete;

/// 设置关闭直播间按钮状态
/// @param selected 是否选中
- (void)setCloseRoomButtonState:(BOOL)selected;

/// 设置Emoji按钮状态
/// @param selected 是否选中
- (void)setEmojiButtonState:(BOOL)selected;

@end

NS_ASSUME_NONNULL_END
