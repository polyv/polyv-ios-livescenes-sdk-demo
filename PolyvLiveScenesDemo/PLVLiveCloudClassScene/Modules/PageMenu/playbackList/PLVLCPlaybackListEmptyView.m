//
//  PLVLCPlaybackListEmptyView.m
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2021/12/14.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLCPlaybackListEmptyView.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCPlaybackListEmptyView ()

@property(nonatomic ,strong) UILabel *titleLabel;

@end

@implementation PLVLCPlaybackListEmptyView

#pragma mark - Life Cycle

- (instancetype) initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.titleLabel];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.titleLabel.frame = CGRectMake(0, 36, CGRectGetWidth(self.bounds), 12);
}

#pragma mark Getter
- (UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = PLVLocalizedString(@"内容加载失败，请下拉刷新重试");
        _titleLabel.textColor = PLV_UIColorFromRGB(@"#ADADC0");
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}


@end
