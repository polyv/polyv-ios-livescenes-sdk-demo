//
//  PLVHCMemberSheetEmptyView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2021/7/30.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCMemberSheetEmptyView.h"
#import "PLVHCUtils.h"

@interface PLVHCMemberSheetEmptyView ()

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;

@end

@implementation PLVHCMemberSheetEmptyView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.contentView];
        [self.contentView addSubview:self.imageView];
        [self.contentView addSubview:self.label];
    }
    return self;
}

- (void)layoutSubviews {
    self.contentView.frame = CGRectMake(0, 0, 89, 51+12+12);
    self.contentView.center = CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
    
    self.imageView.frame = CGRectMake(6, 0, 77, 51);
    self.label.frame = CGRectMake(0, 51+12, 89, 12);
}

#pragma mark - [ Private Method ]

#pragma mark Getter & Setter

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
    }
    return _contentView;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.image = [PLVHCUtils imageForMemberResource:@"plvhc_member_empty_icon"];
    }
    return _imageView;
}

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.textColor = [UIColor colorWithWhite:1 alpha:0.5];
        _label.font = [UIFont systemFontOfSize:12];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.text = @"教室空空如也～";
    }
    return _label;
}

@end
