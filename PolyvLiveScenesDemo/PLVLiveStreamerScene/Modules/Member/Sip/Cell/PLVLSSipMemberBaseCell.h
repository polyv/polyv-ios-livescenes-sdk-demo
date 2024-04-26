//
//  PLVLSSipMemberBaseCell.h
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2022/3/24.
//  Copyright © 2022 PLV. All rights reserved.
//  sip列表Cell父类

#import <UIKit/UIKit.h>

/// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

/// 工具
#import "PLVLSUtils.h"

#import "PLVSipLinkMicUser.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSSipMemberBaseCell : UITableViewCell

@property (nonatomic, strong) UILabel *nameLabel;

@property (nonatomic, strong) UILabel *telephoneNumberLabel;

@property (nonatomic, strong) UIView *seperatorLine;

+ (CGFloat)cellHeight;

- (void)setModel:(PLVSipLinkMicUser *)user;

@end

NS_ASSUME_NONNULL_END
