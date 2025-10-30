//
//  PLVCastDeviceCell.m
//  PLVCloudClassDemo
//
//  Created by MissYasiky on 2020/7/31.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVCastDeviceCell.h"
#import <PLVFoundationSDK/PLVColorUtil.h>
#import "PLVLCUtils.h"

@interface PLVCastDeviceCell ()

@property (nonatomic, strong) UIView *selectedBgView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIImageView *selectedImageView;
@property (nonatomic, strong) UILabel *deviceLabel;

@end

@implementation PLVCastDeviceCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self.contentView addSubview:self.selectedBgView];
        [self.contentView addSubview:self.iconImageView];
        [self.contentView addSubview:self.deviceLabel];
        [self.contentView addSubview:self.selectedImageView];
    }
    return self;
}

- (void)layoutSubviews {
    self.selectedBgView.frame = CGRectMake(15, 7.5, CGRectGetWidth(self.frame) - 30, CGRectGetHeight(self.frame) - 7.5);
    self.iconImageView.frame = CGRectMake(31.5, (CGRectGetHeight(self.frame) - 13.5) / 2 + 5, 15, 13.5);
    self.deviceLabel.frame = CGRectMake(61.5, (CGRectGetHeight(self.frame) - 15) / 2 + 5, CGRectGetWidth(self.frame) - 61.5 - 50, 15);
    self.selectedImageView.frame = CGRectMake(CGRectGetWidth(self.frame) - 33.5 - 11.5, (CGRectGetHeight(self.frame) - 9.5) / 2 + 5, 11.5, 9.5);
    self.gradientLayer.frame = self.selectedBgView.bounds;
}

#pragma mark - Getter & Setter

- (UIView *)selectedBgView {
    if (!_selectedBgView) {
        _selectedBgView = [[UIView alloc] init];
        _selectedBgView.layer.cornerRadius = 3;
        _selectedBgView.backgroundColor = [PLVColorUtil colorFromHexString:@"#56ACE9"];
        _selectedBgView.hidden = YES;
        [_selectedBgView.layer addSublayer:self.gradientLayer];
        _selectedBgView.layer.masksToBounds = YES;
    }
    return _selectedBgView;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)[PLVColorUtil colorFromHexString:@"#56ACE9"].CGColor, (__bridge id)[PLVColorUtil colorFromHexString:@"#8FD6F6"].CGColor];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1, 0);
    }
    return _gradientLayer;
}

- (UIImageView *)iconImageView {
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] init];
        _iconImageView.image = [PLVLCUtils imageForCastResource:@"plv_cast_tv_black_icon"];
    }
    return _iconImageView;
}

- (UIImageView *)selectedImageView {
    if (!_selectedImageView) {
        _selectedImageView = [[UIImageView alloc] init];
        _selectedImageView.image = [PLVLCUtils imageForCastResource:@"plv_cast_choose"];
        _selectedImageView.hidden = YES;
    }
    return _selectedImageView;
}

- (UILabel *)deviceLabel {
    if (!_deviceLabel) {
        _deviceLabel = [[UILabel alloc] init];
        _deviceLabel.font = [UIFont systemFontOfSize:14];
        _deviceLabel.textColor = [PLVColorUtil colorFromHexString:@"#333333"];
    }
    return _deviceLabel;
}

#pragma mark - Public

+ (CGFloat)cellHeight {
    return 57.5;
}

- (void)setDevice:(NSString *)device connected:(BOOL)connected {
    self.selectedBgView.hidden = !connected;
    self.selectedImageView.hidden = !connected;
    self.iconImageView.image = connected ? [PLVLCUtils imageForCastResource:@"plv_cast_tv_icon"] : [PLVLCUtils imageForCastResource:@"plv_cast_tv_black_icon"];
    self.deviceLabel.textColor = connected ? [UIColor whiteColor] : [PLVColorUtil colorFromHexString:@"#333333"];
    self.deviceLabel.text = device;
}

@end
