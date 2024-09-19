//
//  PLVECOnlineListSheetCell.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/9/6.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVECOnlineListSheetCell.h"
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"

#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVECOnlineListSheetCell ()

/// UI
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nickNameLabel;
@property (nonatomic, strong) UIImageView *actorBgView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UILabel *actorLabel;
@property (nonatomic, strong) UILabel *localUserLabel;

/// 数据
@property (nonatomic, strong) PLVChatUser *user;

@end

@implementation PLVECOnlineListSheetCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [self.contentView addSubview:self.avatarImageView];
        [self.contentView addSubview:self.actorBgView];
        [self.contentView addSubview:self.nickNameLabel];
        [self.contentView addSubview:self.localUserLabel];
        
        [self.actorBgView.layer addSublayer:self.gradientLayer];
        [self.actorBgView addSubview:self.actorLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat cellHeight = self.bounds.size.height;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat margin = isPad ? 32 : 16;
    CGFloat localNameLabelWidth = [self.localUserLabel sizeThatFits:CGSizeMake(MAXFLOAT,20)].width;
    
    // 配置头像位置
    self.avatarImageView.frame = CGRectMake(margin, (cellHeight - 34)/2.0, 34, 34);
    
    // 配置头衔（如果有的话）位置
    CGFloat originX = CGRectGetMaxX(self.avatarImageView.frame) + 12;
    if (!self.actorBgView.hidden) {
        CGFloat actorTextWidth = [self.actorLabel.text boundingRectWithSize:CGSizeMake(100, 18)
                                                                    options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                                 attributes:@{NSFontAttributeName:self.actorLabel.font}
                                                                    context:nil].size.width;
        
        CGFloat nickNameLabelWidth = [self.nickNameLabel sizeThatFits:CGSizeMake(MAXFLOAT,20)].width;
        nickNameLabelWidth = MIN(nickNameLabelWidth, self.bounds.size.width - originX - actorTextWidth - margin - 36);
        if (!self.localUserLabel.hidden) {
            nickNameLabelWidth = MIN(nickNameLabelWidth, self.bounds.size.width - originX - actorTextWidth - margin - localNameLabelWidth - 36);
            self.nickNameLabel.frame = CGRectMake(originX, (cellHeight - 20)/2.0, nickNameLabelWidth, 20);
            originX += nickNameLabelWidth;
            self.localUserLabel.frame = CGRectMake(originX, (cellHeight - 20)/2.0, localNameLabelWidth, 20);
            originX += localNameLabelWidth + 4;
        } else {
            nickNameLabelWidth = MIN(nickNameLabelWidth, self.bounds.size.width - originX - actorTextWidth - margin - 36);
            self.nickNameLabel.frame = CGRectMake(originX, (cellHeight - 20)/2.0, nickNameLabelWidth, 20);
            originX += nickNameLabelWidth + 4;
        }
        
        self.actorBgView.frame = CGRectMake(originX, (cellHeight - 18)/2.0, actorTextWidth + 2 * 8, 18);
        self.gradientLayer.frame = self.actorBgView.bounds;
        self.actorLabel.frame = self.actorBgView.bounds;
    } else {
        if (!self.localUserLabel.hidden) {
            self.nickNameLabel.frame = CGRectMake(originX, (cellHeight - 20)/2.0, self.bounds.size.width - originX - margin - localNameLabelWidth - 4, 20);
            self.localUserLabel.frame = CGRectMake(CGRectGetMaxX(self.nickNameLabel.frame), (cellHeight - 20)/2.0 , localNameLabelWidth, 20);
        } else {
            self.nickNameLabel.frame = CGRectMake(originX, (cellHeight - 20)/2.0, self.bounds.size.width - originX - margin - 4, 20);
        }
    }
}

#pragma mark - [ Public Method ]

- (void)updateUser:(PLVChatUser *)user {
    if (!user || ![user isKindOfClass:[PLVChatUser class]]) {
        return;
    }
    
    self.user = user;
    
    // 配置头像
    [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:self.user.avatarUrl]];
    BOOL specialType = [PLVRoomUser isSpecialIdentityWithUserType:user.userType];
    
    // 配置头衔标志
    self.actorBgView.hidden = !specialType;
    self.actorLabel.hidden = !specialType;
    self.actorLabel.text = user.actor;
    
    // 配置头衔背景渐变
    if (specialType) {
        UIColor *startColor = nil;
        UIColor *endColor = nil;
        [self getActorBgColorWithUserType:user.userType startColor:&startColor endColor:&endColor];
        if (startColor && endColor) {
            self.gradientLayer.colors = @[(__bridge id)startColor.CGColor, (__bridge id)endColor.CGColor];
        }
    }
    
    // 配置昵称文本
    self.nickNameLabel.text = self.user.userName;
    NSString *localUserViewerId = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerId;
    self.localUserLabel.hidden = !([PLVFdUtil checkStringUseable:localUserViewerId] && [self.user.userId isEqualToString:localUserViewerId]);
}

#pragma mark Getter & Setter

- (UIImageView *)avatarImageView {
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.layer.cornerRadius = 17;
        _avatarImageView.layer.masksToBounds = YES;
    }
    return _avatarImageView;
}

- (UIImageView *)actorBgView {
    if (!_actorBgView) {
        _actorBgView = [[UIImageView alloc] init];
        _actorBgView.layer.cornerRadius = 8;
        _actorBgView.layer.masksToBounds = YES;
        _actorBgView.hidden = YES;
    }
    return _actorBgView;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.locations = @[@(0), @(1.0)];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
    }
    return _gradientLayer;
}

- (UILabel *)actorLabel {
    if (!_actorLabel) {
        _actorLabel = [[UILabel alloc] init];
        _actorLabel.font = [UIFont systemFontOfSize:10];
        _actorLabel.textColor = [UIColor whiteColor];
        _actorLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _actorLabel;
}

- (UILabel *)nickNameLabel {
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
        _nickNameLabel.font = [UIFont fontWithName:@"PingFangSC-Regula" size:14];
        _nickNameLabel.textColor = [PLVColorUtil colorFromHexString:@"#000000" alpha:0.8];
    }
    return _nickNameLabel;
}

- (UILabel *)localUserLabel {
    if (!_localUserLabel) {
        _localUserLabel = [[UILabel alloc] init];
        _localUserLabel.font = [UIFont fontWithName:@"PingFangSC-Regula" size:14];
        _localUserLabel.textColor = [PLVColorUtil colorFromHexString:@"#000000" alpha:0.8];
        _localUserLabel.text = PLVLocalizedString(@"（我）");
        _localUserLabel.hidden = YES;
    }
    return _localUserLabel;
}

#pragma mark - [ Private Method ]

#pragma mark UI

/// 通过参数获取头衔渐变色首尾颜色
- (void)getActorBgColorWithUserType:(PLVRoomUserType)userType
                         startColor:(UIColor **)startColor
                           endColor:(UIColor **)endColor {
    NSString *startColorHexString = nil;
    NSString *endColorHexString = nil;
    switch (userType) {
        case PLVRoomUserTypeGuest:
            startColorHexString = @"#FF2851";
            endColorHexString = @"#FE3182";
            break;
        case PLVRoomUserTypeTeacher:
            startColorHexString = @"#FFB95A";
            endColorHexString = @"#FFA336";
            break;
        case PLVRoomUserTypeAssistant:
            startColorHexString = @"#3B7DFE";
            endColorHexString = @"#75A2FE";
            break;
        case PLVRoomUserTypeManager:
            startColorHexString = @"#32B6BF";
            endColorHexString = @"#35C4CF";
            break;
        default:
            break;
    }
    *startColor = PLV_UIColorFromRGB(startColorHexString);
    *endColor = PLV_UIColorFromRGB(endColorHexString);
}

@end
