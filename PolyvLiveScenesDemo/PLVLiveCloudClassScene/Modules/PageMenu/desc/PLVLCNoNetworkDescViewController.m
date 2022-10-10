//
//  PLVLCNoNetworkDescViewController.m
//  PolyvLiveScenesDemo
//
//  Created by juno on 2022/8/31.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCNoNetworkDescViewController.h"
#import "PLVLCUtils.h"

@interface PLVLCNoNetworkDescViewController ()
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIView *line;
@property (nonatomic, strong) UILabel *noNetWorkLabel;

@end

@implementation PLVLCNoNetworkDescViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0x20/255.0 green:0x21/255.0 blue:0x27/255.0 alpha:1.0];
    [self.view addSubview:self.avatarImageView];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.statusLabel];
    [self.view addSubview:self.line];
    [self.view addSubview:self.noNetWorkLabel];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.avatarImageView.frame = CGRectMake(16, 15, 40, 40);
    self.statusLabel.frame = CGRectMake(self.view.bounds.size.width - 50 - 16, 16, 50, 24);
    self.titleLabel.frame = CGRectMake(66, 14, self.view.bounds.size.width - 50 - 16 - 10 - 66, 40);
    self.line.frame = CGRectMake(0, 72, self.view.bounds.size.width, 1);
    self.noNetWorkLabel.frame = CGRectMake(16, 96, self.view.bounds.size.width - 32, 20);
}

#pragma mark - Getter & Setter
- (UIImageView *)avatarImageView {
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.image = [PLVLCUtils imageForMenuResource:@"plvlc_menu_defaultUser"];
    }
    return _avatarImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:16];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.text = @"保利威直播详情";
    }
    return _titleLabel;
}

- (UILabel *)statusLabel {
    if (!_statusLabel) {
        _statusLabel = [[UILabel alloc] init];
        _statusLabel.font = [UIFont systemFontOfSize:14];
        _statusLabel.layer.cornerRadius = 2.0;
        _statusLabel.layer.borderWidth = 1.0;
        _statusLabel.textAlignment = NSTextAlignmentCenter;
        _statusLabel.text = @"已缓存";
        _statusLabel.textColor = [UIColor colorWithRed:0xAD/255.0 green:0xAD/255.0 blue:0xC0/255.0 alpha:1.0];
        _statusLabel.layer.borderColor = [UIColor colorWithRed:0xAD/255.0 green:0xAD/255.0 blue:0xC0/255.0 alpha:1.0].CGColor;
    }
    return _statusLabel;
}

- (UIView *)line {
    if (!_line) {
        _line = [[UIView alloc] init];
        _line.backgroundColor = [UIColor blackColor];
    }
    return _line;
}

- (UILabel *)noNetWorkLabel {
    if (!_noNetWorkLabel) {
        _noNetWorkLabel = [[UILabel alloc] init];
        _noNetWorkLabel.font = [UIFont systemFontOfSize:12];
        _noNetWorkLabel.textColor = [UIColor colorWithRed:0xAD/255.0 green:0xAD/255.0 blue:0xC0/255.0 alpha:1.0];
        _noNetWorkLabel.textAlignment = NSTextAlignmentCenter;
        _noNetWorkLabel.numberOfLines = 0;
        _noNetWorkLabel.text = @"正处于无网观看模式";
    }
    return _noNetWorkLabel;
}
@end
