//
//  PLVHCChatroomPlaceholderView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/7/23.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCChatroomPlaceholderView.h"

// 工具
#import "PLVHCUtils.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCChatroomPlaceholderView()

#pragma mark UI

@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIImageView *topImageView;
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation PLVHCChatroomPlaceholderView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#22273D"];
        [self addSubview:self.bgView];
        [self.bgView addSubview:self.topImageView];
        [self.bgView addSubview:self.titleLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize imageSize = CGSizeMake(61, 51);
    CGFloat titleHeight = 12;
    CGFloat padding = titleHeight;
    CGFloat bgWidth = self.bounds.size.width;
    CGFloat bgHeight = imageSize.height + padding + titleHeight;
    
    self.bgView.frame = CGRectMake(0, (self.bounds.size.height - bgHeight) / 2, bgWidth, bgHeight);
    self.topImageView.frame = CGRectMake((bgWidth - imageSize.width) / 2, 0, imageSize.width, imageSize.height);
    self.titleLabel.frame = CGRectMake(0, CGRectGetMaxY(self.topImageView.frame) + padding, bgWidth, titleHeight);
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc] init];
    }
    return _bgView;
}

- (UIImageView *)topImageView {
    if (!_topImageView) {
        _topImageView = [[UIImageView alloc] init];
        _topImageView.image = [PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_img_unStartClass"];
    }
    return _topImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:12];
        _titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.5];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = @"暂无聊天消息";
    }
    return _titleLabel;
}

@end
