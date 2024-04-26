//
//  PLVLSSipCallingMemberCell.m
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2022/3/25.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSSipCallingMemberCell.h"

@interface PLVLSSipCallingMemberCell()

/// 接听状态
@property (nonatomic, strong) UILabel *statusLabel;
/// 取消按钮
@property (nonatomic, strong) UIButton *cancelButton;

@end

@implementation PLVLSSipCallingMemberCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
//        [self initUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.statusLabel.frame = CGRectMake(CGRectGetMaxX(self.telephoneNumberLabel.frame) + 8, CGRectGetMinY(self.telephoneNumberLabel.frame), 38, 17);
    self.cancelButton.frame = CGRectMake(CGRectGetMaxX(self.contentView.frame) - 28, CGRectGetMidY(self.contentView.frame) - 14, 28, 28);
}

#pragma mark - [ Private Method ]

- (void)initUI {
    [self.contentView addSubview:self.statusLabel];
}

#pragma mark Getter & Setter

- (UILabel *)statusLabel {
    if (!_statusLabel) {
        _statusLabel = [[UILabel alloc] init];
        _statusLabel.text = @"未响应";
        _statusLabel.font = [UIFont systemFontOfSize:12];
        _statusLabel.textColor = PLV_UIColorFromRGB(@"#FF6363");
    }
    return _statusLabel;
}

@end
