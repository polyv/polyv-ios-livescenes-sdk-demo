//
//  PLVLSSipMemberBaseCell.m
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2022/3/24.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSSipMemberBaseCell.h"

@implementation PLVLSSipMemberBaseCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self.contentView addSubview:self.nameLabel];
        [self.contentView addSubview:self.telephoneNumberLabel];
        [self.contentView addSubview:self.seperatorLine];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.nameLabel.frame = CGRectMake(16, CGRectGetMidY(self.contentView.frame) - 14, 28, 28);
    self.telephoneNumberLabel.frame = CGRectMake(CGRectGetMaxX(self.nameLabel.frame) + 8, CGRectGetMidY(self.nameLabel.frame) - 9, 100, 18);
    self.seperatorLine.frame = CGRectMake(CGRectGetMinX(self.nameLabel.frame), self.bounds.size.height - 1, self.bounds.size.width, 1);
}

#pragma mark - [ Private Method ]

#pragma mark Setter & Setter


#pragma mark - [ Public Method ]

+ (CGFloat)cellHeight {
    return 48.0;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.text = @"名";
        _nameLabel.font = [UIFont systemFontOfSize:12];
        _nameLabel.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _nameLabel.backgroundColor = PLV_UIColorFromRGB(@"#2977D3");
        _nameLabel.layer.cornerRadius = 14;
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.layer.masksToBounds = YES;
    }
    return _nameLabel;
}

- (UILabel *)telephoneNumberLabel {
    if (!_telephoneNumberLabel) {
        _telephoneNumberLabel = [[UILabel alloc] init];
        _telephoneNumberLabel.text = @"电话号码";
        _telephoneNumberLabel.font = [UIFont systemFontOfSize:12];
        _telephoneNumberLabel.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _telephoneNumberLabel.backgroundColor = [UIColor clearColor];
    }
    return _telephoneNumberLabel;
}

- (UIView *)seperatorLine {
    if (!_seperatorLine) {
        _seperatorLine = [[UIView alloc] init];
        _seperatorLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#f0f1f5" alpha:0.1];
    }
    return _seperatorLine;
}

- (void)setModel:(PLVSipLinkMicUser *)user {
    self.nameLabel.text = user.userName;
    self.telephoneNumberLabel.text = user.phone;
}

@end
