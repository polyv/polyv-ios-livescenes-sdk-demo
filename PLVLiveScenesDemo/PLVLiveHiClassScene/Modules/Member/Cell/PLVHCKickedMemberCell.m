//
//  PLVHCKickedMemberCell.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/8/3.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCKickedMemberCell.h"
/// 数据
#import "PLVChatUser.h"
/// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCKickedMemberCell ()

/// UI
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UILabel *nicknameLabel;
@property (nonatomic, strong) UIButton *unkickButton;

/// 数据
@property (nonatomic, strong) PLVChatUser *chatUser;

@end

@implementation PLVHCKickedMemberCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#22273D"];
        self.contentView.backgroundColor = [UIColor clearColor];
        
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat selfWidth = self.bounds.size.width;
    self.bgView.frame = CGRectMake(8, 0, selfWidth - 16, self.bounds.size.height);
    self.nicknameLabel.frame = CGRectMake(24, 17, selfWidth - 24 - 56, 14);
    
    // 以下控件位置的计算都跟headerView对齐
    CGFloat headerRightViewWidth = selfWidth * (1 - 0.36);
    CGFloat headerLabelWidth = (headerRightViewWidth - 22.0) / 7.0;
    self.unkickButton.frame = CGRectMake(self.bounds.size.width - 22 - headerLabelWidth + (headerLabelWidth - 40)/2.0, 2, 40, 44);
}

#pragma mark - [ Public Method ]

- (void)setChatUser:(PLVChatUser *)user even:(BOOL)even {
    self.bgView.hidden = even;
    
    if (!user || ![user isKindOfClass:[PLVChatUser class]]) {
        self.chatUser = nil;
        self.nicknameLabel.text = @"";
        return;
    }
    
    self.chatUser = user;
    if (user.userName && [user.userName isKindOfClass:[NSString class]]) {
        self.nicknameLabel.text = [NSString stringWithFormat:@"%@(已移出)", user.userName];
    }
}

+ (CGFloat)cellHeight {
    return 48.0;
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self.contentView addSubview:self.bgView];
    [self.contentView addSubview:self.nicknameLabel];
    [self.contentView addSubview:self.unkickButton];
}

#pragma mark Getter & Setter

- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc] init];
        _bgView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
        _bgView.layer.cornerRadius = 8;
    }
    return _bgView;
}

- (UILabel *)nicknameLabel {
    if (!_nicknameLabel) {
        _nicknameLabel = [[UILabel alloc] init];
        _nicknameLabel.font = [UIFont systemFontOfSize:14];
        _nicknameLabel.textColor = [UIColor colorWithWhite:1 alpha:0.8];
    }
    return _nicknameLabel;
}

- (UIButton *)unkickButton {
    if (!_unkickButton) {
        _unkickButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_unkickButton setTitleColor:[PLVColorUtil colorFromHexString:@"#78A7ED"] forState:UIControlStateNormal];
        [_unkickButton setTitle:@"移入" forState:UIControlStateNormal];
        _unkickButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_unkickButton addTarget:self action:@selector(unkickButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _unkickButton;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)unkickButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(unkickUserInKickedMemberCell:user:)]) {
        [self.delegate unkickUserInKickedMemberCell:self user:self.chatUser];
    }
}

@end
