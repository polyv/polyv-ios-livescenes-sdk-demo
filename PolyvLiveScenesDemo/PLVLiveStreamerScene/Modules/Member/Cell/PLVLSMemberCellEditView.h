//
//  PLVLSMemberCellEditView.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/31.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSMemberCellEditView : UIView

@property (nonatomic, assign) BOOL banned;

/// 点击【禁言/取消禁言】按钮响应事件方法块
/// banned：YES - 禁言 NO - 取消禁言
@property (nonatomic, copy) void(^didTapBanButton)(BOOL banned);

/// 点击【移出】按钮响应事件方法块
@property (nonatomic, copy) void(^didTapKickButton)(void);

- (void)reset;

@end

NS_ASSUME_NONNULL_END
