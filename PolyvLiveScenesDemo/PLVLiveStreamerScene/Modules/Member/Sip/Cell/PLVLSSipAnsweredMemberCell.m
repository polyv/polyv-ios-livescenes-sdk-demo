//
//  PLVLSSipAnsweredMemberCell.m
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2022/3/25.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSSipAnsweredMemberCell.h"

@interface PLVLSSipAnsweredMemberCell()

@property (nonatomic, strong) UIImageView *microPhoneImage;

@end

@implementation PLVLSSipAnsweredMemberCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.microPhoneImage.frame = CGRectMake(CGRectGetMaxX(self.contentView.frame) - 28, CGRectGetMidY(self.contentView.frame) - 14, 28, 28);
}

#pragma mark - [ Private Method ]

- (void)initUI {
    [self.contentView addSubview:self.microPhoneImage];
}

#pragma mark Getter & Setter

- (UIImageView *)microPhoneImage {
    if (!_microPhoneImage) {
        _microPhoneImage = [[UIImageView alloc] init];
        _microPhoneImage.image = [PLVLSUtils imageForMemberResource:@"plvls_member_volume_0_icon"];
    }
    return _microPhoneImage;
}

#pragma mark - [ Public Method ]

- (void)setModel:(PLVSipLinkMicUser *)user {
    self.nameLabel.text = user.userName;
    self.telephoneNumberLabel.text = user.phone;
    BOOL enable = (user.muteStatus == 1);
    [self setMicroPhoneImageWithMicroPhoneEnable:enable];
}

- (void)setMicroPhoneImageWithMicroPhoneEnable:(BOOL)enable{
    self.microPhoneImage.hidden = !enable;
    if (enable) {
        [self.microPhoneImage setImage:[PLVLSUtils imageForMemberResource:@"plvls_member_mic_close_btn"]];
    }
}

@end
