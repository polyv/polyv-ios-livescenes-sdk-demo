//
//  PLVLSMemberCellEditView.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/31.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSMemberCellEditView.h"
#import <PLVFoundationSDK/PLVColorUtil.h>

typedef NS_ENUM(NSInteger, PLVLSMemberCellState) {
    PLVLSMemberCellStateNormal,
    PLVLSMemberCellStateBanSelected,
    PLVLSMemberCellStateKickSelected
};

@interface PLVLSMemberCellEditView ()

@property (nonatomic, strong) UIButton *banButton;

@property (nonatomic, strong) UIButton *kickButton;

@property (nonatomic, assign) PLVLSMemberCellState state;

@end

@implementation PLVLSMemberCellEditView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.clipsToBounds = YES;
        
        [self addSubview:self.banButton];
        [self addSubview:self.kickButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.state == PLVLSMemberCellStateBanSelected) {
        self.banButton.frame = CGRectMake(0, 0, 160, 48);
        self.kickButton.frame = CGRectMake(160, 0, 80, 48);
    } else if (self.state == PLVLSMemberCellStateKickSelected) {
        self.banButton.frame = CGRectMake(-80, 0, 80, 48);
        self.kickButton.frame = CGRectMake(0, 0, 160, 48);
    } else {
        self.banButton.frame = CGRectMake(0, 0, 80, 48);
        self.kickButton.frame = CGRectMake(80, 0, 80, 48);
    }
}

#pragma mark - Getter

- (void)setBanned:(BOOL)banned {
    _banned = banned;
    NSString *buttonTitle = banned ? @"取消禁言" : @"禁言";
    [self.banButton setTitle:buttonTitle forState:UIControlStateNormal];
    [self reset];
}

- (UIButton *)banButton {
    if (!_banButton) {
        _banButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _banButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#474b57"];
        [_banButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_banButton setTitle:@"禁言" forState:UIControlStateNormal];
        [_banButton setTitle:@"确定禁言" forState:UIControlStateSelected];
        _banButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_banButton addTarget:self action:@selector(banButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _banButton;
}

- (UIButton *)kickButton {
    if (!_kickButton) {
        _kickButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _kickButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#ff6363"];
        [_kickButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_kickButton setTitle:@"踢出" forState:UIControlStateNormal];
        [_kickButton setTitle:@"确定踢出" forState:UIControlStateSelected];
        _kickButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_kickButton addTarget:self action:@selector(kickButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _kickButton;
}

#pragma mark - Action

- (void)banButtonAction {
    if (self.banned) { // 取消禁言
        self.banned = NO;
        if (self.didTapBanButton) {
            self.didTapBanButton(NO);
        }
    } else {
        if (self.banButton.selected) { // 确定禁言
            self.banButton.selected = NO;
            self.banned = YES;
            if (self.didTapBanButton) {
                self.didTapBanButton(YES);
            }
        } else { // 禁言
            self.banButton.selected = YES;
            self.state = self.banButton.selected ? PLVLSMemberCellStateBanSelected : PLVLSMemberCellStateNormal;
            [self updateUI];
        }
    }
}

- (void)kickButtonAction {
    if (self.kickButton.selected) { // 确定踢出
        self.kickButton.selected = NO;
        if (self.didTapKickButton) {
            self.didTapKickButton();
        }
    } else { // 踢出
        self.kickButton.selected = YES;
        self.state = self.kickButton.selected ? PLVLSMemberCellStateKickSelected : PLVLSMemberCellStateNormal;
        [self updateUI];
    }
}

#pragma mark - Public

- (void)reset {
    self.banButton.selected = self.kickButton.selected = NO;
    self.state =  PLVLSMemberCellStateNormal;
    [self updateUI];
}

#pragma mark - Private

- (void)updateUI {
    if (self.state == PLVLSMemberCellStateBanSelected) {
        [UIView animateWithDuration:0.3 animations:^{
            self.banButton.frame = CGRectMake(0, 0, 160, 48);
            self.kickButton.frame = CGRectMake(160, 0, 80, 48);
        }];
    } else if (self.state == PLVLSMemberCellStateKickSelected) {
        [UIView animateWithDuration:0.3 animations:^{
            self.banButton.frame = CGRectMake(-80, 0, 80, 48);
            self.kickButton.frame = CGRectMake(0, 0, 160, 48);
        }];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            self.banButton.frame = CGRectMake(0, 0, 80, 48);
            self.kickButton.frame = CGRectMake(80, 0, 80, 48);
        }];
    }
}

@end
