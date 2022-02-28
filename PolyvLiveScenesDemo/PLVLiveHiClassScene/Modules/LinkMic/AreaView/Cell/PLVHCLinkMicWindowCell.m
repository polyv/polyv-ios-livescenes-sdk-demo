//
//  PLVHCLinkMicWindowCell.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/8/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCLinkMicWindowCell.h"

// 工具
#import "PLVHCUtils.h"

// UI
#import "PLVHCLinkMicItemView.h"
#import "PLVHCLinkMicWindowCupView.h"
#import "PLVHCLinkMicPlaceholderView.h"

// 模型
#import "PLVLinkMicOnlineUser+HC.h"

/// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCLinkMicWindowCell ()

#pragma mark UI
/// view hierarchy
///
/// (PLVLCLinkMicWindowCell) self
/// └── (UIView) contentView
///      ├── (PLVHCLinkMicItemView) itemView (lowest)
///      └── (PLVHCLinkMicPlaceholderView) placeholderView (top)

@property (nonatomic, strong) PLVHCLinkMicItemView *itemView;
@property (nonatomic, strong) PLVHCLinkMicPlaceholderView *placeholderView;

#pragma mark 数据
@property (nonatomic, weak) PLVLinkMicOnlineUser *userModel;

@end

@implementation PLVHCLinkMicWindowCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.userModel.inLinkMicZoom) {
        self.itemView.frame = self.contentView.bounds;
    }
    self.placeholderView.frame = self.bounds;
}

#pragma mark Getter & Setter

- (PLVHCLinkMicItemView *)itemView {
    if (!_itemView) {
        _itemView = [[PLVHCLinkMicItemView alloc] init];
    }
    return _itemView;
}

- (PLVHCLinkMicPlaceholderView *)placeholderView {
    if (!_placeholderView) {
        _placeholderView = [[PLVHCLinkMicPlaceholderView alloc] init];
        _placeholderView.hidden = YES;
    }
    return _placeholderView;
}

#pragma mark - [ Public Method ]

- (void)updateOnlineUser:(PLVLinkMicOnlineUser *)userModel {
    self.userModel = userModel;
    [self.itemView updateOnlineUser:userModel];
    // 占位图
    [self.placeholderView setupNicknameWithUserModel:userModel];
    if (userModel.inLinkMicZoom) { // 放大区域时显示占位图
        self.placeholderView.hidden = NO;
    } else {
        self.placeholderView.hidden = YES;
        [self.contentView addSubview:self.itemView];
    }
}

- (void)showZoomPlaceholder:(BOOL)show {
    self.placeholderView.hidden = !show;
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self.contentView addSubview:self.itemView];
    [self addSubview:self.placeholderView];
}

@end

@implementation PLVHCLinkMicWindowSixCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.itemView.brushImageView.frame = CGRectMake(0, 0, 14, 14);
        self.itemView.cupView.frame = CGRectMake(0, 0, 25, 14);
        self.itemView.maxNicknameLabel.frame = CGRectMake(0, 0, 60, 34);
        self.itemView.maxNicknameLabel.font = [UIFont systemFontOfSize:14];
        self.itemView.minNicknameLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:8];
        self.itemView.micImageView.frame = CGRectMake(0, 0,  10, 10);
        self.itemView.handUpImageView.frame = CGRectMake(0, 0, 22, 24);
        self.itemView.bottomShadowLayer.frame = CGRectMake(0, 0, 0, 22);
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
}

@end

@implementation PLVHCLinkMicWindowSixteenCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.itemView.brushImageView.frame = CGRectMake(0, 0, 10, 10);
        self.itemView.cupView.frame = CGRectMake(0, 0, 22, 10);
        self.itemView.maxNicknameLabel.frame = CGRectMake(0, 0, 38, 30);
        self.itemView.maxNicknameLabel.font = [UIFont systemFontOfSize:12];
        self.itemView.minNicknameLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:7];
        self.itemView.micImageView.frame = CGRectMake(0, 0, 10, 10);
        self.itemView.handUpImageView.frame = CGRectMake(0, 0, 20, 22);
        self.itemView.bottomShadowLayer.frame = CGRectMake(0, 0, 0, 18);
        self.placeholderView.placeholderImageView.frame = CGRectMake(0, 0, 20, 20);
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
}

@end

@implementation PLVHCLinkMicWindowSixteenTeacherCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.itemView.maxNicknameLabel.frame = CGRectMake(0, 0, 94, 40);
        self.itemView.maxNicknameLabel.font = [UIFont systemFontOfSize:14];
        self.itemView.minNicknameLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:8];
        self.itemView.micImageView.frame = CGRectMake(0, 0,  10, 10);
        self.itemView.bottomShadowLayer.frame = CGRectMake(0, 0, 0, 22);
    }
    return self;
}
#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
}

@end
