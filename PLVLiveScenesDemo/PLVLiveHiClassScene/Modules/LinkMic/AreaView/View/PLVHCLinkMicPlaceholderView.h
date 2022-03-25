//
//  PLVHCLinkMicPlaceholderView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/11/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class PLVLinkMicOnlineUser;

@interface PLVHCLinkMicPlaceholderView : UIView

@property (nonatomic, strong, readonly) UIImageView *placeholderImageView;
@property (nonatomic, strong, readonly) UILabel *placeholderNameLabel;

/// 设置昵称
/// @param nickName 昵称
- (void)setupNickname:(NSString *)nickName;

/// 设置昵称，内部根据身份类型显示【xxx的位置】
/// @param userModel 用户模型
- (void)setupNicknameWithUserModel:(PLVLinkMicOnlineUser *)userModel;

@end

NS_ASSUME_NONNULL_END
