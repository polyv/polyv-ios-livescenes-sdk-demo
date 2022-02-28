//
//  PLVHCLinkMicPlaceholderView.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/11/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCLinkMicPlaceholderView.h"

// 工具类
#import "PLVHCUtils.h"

// 模块
#import "PLVLinkMicOnlineUser.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCLinkMicPlaceholderView()

@property (nonatomic, strong) UIImageView *placeholderImageView;
@property (nonatomic, strong) UILabel *placeholderNameLabel;

@end

@implementation PLVHCLinkMicPlaceholderView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#3C3C4C"];
        [self addSubview:self.placeholderImageView];
        [self addSubview:self.placeholderNameLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.placeholderImageView.center = CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)/2 - 8);
    self.placeholderNameLabel.frame = CGRectMake(0, CGRectGetMaxY(self.placeholderImageView.frame) + 8, CGRectGetWidth(self.bounds), 10);
}

#pragma mark - [ Public Method ]

- (void)setupNickname:(NSString *)nickname {
    if (![PLVFdUtil checkStringUseable:nickname]) {
        nickname = @"";
    }
    self.placeholderNameLabel.text = nickname;
}

- (void)setupNicknameWithUserModel:(PLVLinkMicOnlineUser *)userModel {
    BOOL isTeacher = userModel.userType == PLVSocketUserTypeTeacher;
    NSString *nickname = userModel.nickname;
    if (![PLVFdUtil checkStringUseable:nickname]) {
        nickname = @"";
    }
    nickname = isTeacher ? [NSString stringWithFormat:@"老师-%@的位置",nickname] : [NSString stringWithFormat:@"%@的位置",nickname];
    [self setupNickname:nickname];
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (UIImageView *)placeholderImageView {
    if (!_placeholderImageView) {
        _placeholderImageView = [[UIImageView alloc] init];
        _placeholderImageView.bounds = CGRectMake(0, 0, 32, 32);
        _placeholderImageView.image = [PLVHCUtils imageForLinkMicResource:@"plvhc_linkmic_teacher_placeholer_icon"];
    }
    return _placeholderImageView;
}

- (UILabel *)placeholderNameLabel {
    if (!_placeholderNameLabel) {
        _placeholderNameLabel = [[UILabel alloc] init];
        _placeholderNameLabel.textColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"];
        _placeholderNameLabel.font = [UIFont systemFontOfSize:8];
        _placeholderNameLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _placeholderNameLabel;
}

@end
