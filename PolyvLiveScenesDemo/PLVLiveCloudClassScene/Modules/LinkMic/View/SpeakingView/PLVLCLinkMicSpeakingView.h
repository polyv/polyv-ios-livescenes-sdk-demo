//
//  PLVLCLinkMicSpeakingView.h
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/11/25.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// ‘某某正在发言’ 示意视图
@interface PLVLCLinkMicSpeakingView : UIView

/// 当前是否显示
@property (nonatomic, assign, readonly) BOOL currentShow;

/// 当前昵称文本框的宽度
@property (nonatomic, assign, readonly) CGFloat currentWidthWithNicknamesText;

- (void)updateSpeakingInfoWithNicknames:(NSArray <NSString *>*)nicknamesArray;

@end

NS_ASSUME_NONNULL_END
