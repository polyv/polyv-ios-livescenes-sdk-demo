//
//  PLVHCMemberSheetSelectView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/8/2.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCMemberSheetSelectView.h"
// 模块
#import "PLVRoomDataManager.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSInteger kButtonTagConst = 100;

@interface PLVHCMemberSheetSelectView ()

/// UI
@property (nonatomic, strong) UILabel *onlineMemberLabel; // 在线学生Label
@property (nonatomic, strong) UILabel *kickedMemberLabel; // 移出学生Label
@property (nonatomic, strong) UIButton *onlineMemberButton; // 在线学生按钮
@property (nonatomic, strong) UIButton *kickedMemberButton; // 移出学生按钮

/// 数据
@property (nonatomic, assign, getter=isTeacher) BOOL teacher; // 是否为讲师

@end

@implementation PLVHCMemberSheetSelectView

#pragma mark - [ Life Cycle ]

#pragma mark - [ Public Method ]

- (instancetype)initWithOnlineUserCount:(NSInteger)userCount kickedUserCount:(NSInteger)kickedUserCount {
    self = [super init];
    if (self) {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#2D3452"];
        self.layer.cornerRadius = 8;
        
        [self setupUI];
        [self updateWithOnlineUserCount:userCount kickedUserCount:kickedUserCount];
        
    }
    return self;
}

- (void)updateWithOnlineUserCount:(NSInteger)userCount kickedUserCount:(NSInteger)kickedUserCount {
    self.onlineMemberLabel.text = [NSString stringWithFormat:@"在线学生（%zd）", userCount];
    self.kickedMemberLabel.text = [NSString stringWithFormat:@"移出学生（%zd）", kickedUserCount];
}

- (void)showInView:(UIView *)superView {
    [superView addSubview:self];
}

- (void)dismiss {
    [self removeFromSuperview];
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self addSubview:self.onlineMemberButton];
    [self.onlineMemberButton addSubview:self.onlineMemberLabel];
    
    if (self.isTeacher) { // 讲师才有 移出学生 列表
        self.frame = CGRectMake(8, 64 + 7.5, 144, 96);
        
        [self addSubview:self.kickedMemberButton];
        [self.kickedMemberButton addSubview:self.kickedMemberLabel];
        
        self.kickedMemberButton.frame = CGRectMake(8, 48, 128, 40);
        self.kickedMemberLabel.frame = CGRectMake(8, 13, 112, 14);
    } else { 
        self.frame = CGRectMake(8, 64 + 7.5, 144, 56);
    }
    
    self.onlineMemberButton.frame = CGRectMake(8, 8, 128, 40);
    self.onlineMemberLabel.frame = CGRectMake(8, 13, 112, 14);
}

#pragma mark - Getter & Setter

- (UILabel *)onlineMemberLabel {
    if (!_onlineMemberLabel) {
        _onlineMemberLabel = [[UILabel alloc] init];
        _onlineMemberLabel.textColor = [UIColor whiteColor];
        _onlineMemberLabel.font = [UIFont systemFontOfSize:14];
    }
    return _onlineMemberLabel;
}

- (UILabel *)kickedMemberLabel {
    if (!_kickedMemberLabel) {
        _kickedMemberLabel = [[UILabel alloc] init];
        _kickedMemberLabel.textColor = [UIColor whiteColor];
        _kickedMemberLabel.font = [UIFont systemFontOfSize:14];
    }
    return _kickedMemberLabel;
}

- (UIButton *)onlineMemberButton {
    if (!_onlineMemberButton) {
        _onlineMemberButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _onlineMemberButton.layer.cornerRadius = 8;
        _onlineMemberButton.layer.masksToBounds = YES;
        UIImage *selectedImage = [PLVColorUtil createImageWithColor:[PLVColorUtil colorFromHexString:@"#00B16C"]];
        [_onlineMemberButton setBackgroundImage:selectedImage forState:UIControlStateSelected];
        [_onlineMemberButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        _onlineMemberButton.tag = kButtonTagConst;
        _onlineMemberButton.selected = YES;
    }
    return _onlineMemberButton;
}

- (UIButton *)kickedMemberButton {
    if (!_kickedMemberButton) {
        _kickedMemberButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _kickedMemberButton.layer.cornerRadius = 8;
        _kickedMemberButton.layer.masksToBounds = YES;
        UIImage *selectedImage = [PLVColorUtil createImageWithColor:[PLVColorUtil colorFromHexString:@"#00B16C"]];
        [_kickedMemberButton setBackgroundImage:selectedImage forState:UIControlStateSelected];
        [_kickedMemberButton addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        _kickedMemberButton.tag = kButtonTagConst + 1;
    }
    return _kickedMemberButton;
}

- (BOOL)isTeacher {
    return [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)buttonAction:(id)sender {
    UIButton *button = (UIButton *)sender;
    NSInteger index = button.tag - kButtonTagConst;
    if (index == 0) {
        self.onlineMemberButton.selected = YES;
        self.kickedMemberButton.selected = NO;
    } else {
        self.onlineMemberButton.selected = NO;
        self.kickedMemberButton.selected = YES;
    }
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(selectButtonInSelectView:atIndex:)]) {
        [self.delegate selectButtonInSelectView:self atIndex:index];
    }
}

@end
