//
//  PLVECLiveRoomInfoView.m
//  PLVLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECLiveRoomInfoView.h"
#import "PLVECUtils.h"

@interface PLVECLiveRoomInfoView ()

@property (nonatomic, strong) UIImageView *watchImageView;

@end

@implementation PLVECLiveRoomInfoView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4f];
        self.layer.cornerRadius = 18;
        self.layer.masksToBounds = YES;
        
        [self addSubview:self.coverImageView];
        [self addSubview:self.publisherLB];
        [self addSubview:self.watchImageView];
        [self addSubview:self.pageViewLB];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    self.coverImageView.frame = CGRectMake(4, 4, 28, 28);
    self.publisherLB.frame = CGRectMake(CGRectGetMaxX(self.coverImageView.frame)+4, 4, CGRectGetWidth(bounds)-CGRectGetMaxX(self.coverImageView.frame)-8, 14);
    self.watchImageView.frame = CGRectMake(CGRectGetMinX(self.publisherLB.frame), CGRectGetMaxY(self.publisherLB.frame)+2, 12, 12);
    self.pageViewLB.frame = CGRectMake(CGRectGetMaxX(self.watchImageView.frame)+2, CGRectGetMinY(self.watchImageView.frame), CGRectGetWidth(bounds)-CGRectGetMaxX(self.watchImageView.frame)-6, 10);
}

- (UIImageView *)coverImageView {
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] init];
        _coverImageView.layer.cornerRadius = 14;
        _coverImageView.layer.masksToBounds = YES;
    }
    return _coverImageView;
}

- (UILabel *)publisherLB {
    if (!_publisherLB) {
        _publisherLB = [[UILabel alloc] init];
        _publisherLB.textColor = UIColor.whiteColor;
        _publisherLB.font = [UIFont systemFontOfSize:14];
        _publisherLB.textAlignment = NSTextAlignmentLeft;
    }
    return _publisherLB;
}

- (UIImageView *)watchImageView {
    if (!_watchImageView) {
        UIImage *watchImage = [PLVECUtils imageForWatchResource:@"plv_watch_img"];
        _watchImageView = [[UIImageView alloc] initWithImage:watchImage];
    }
    return _watchImageView;
}

- (UILabel *)pageViewLB {
    if (!_pageViewLB) {
        _pageViewLB = [[UILabel alloc] init];
        _pageViewLB.textColor = UIColor.whiteColor;
        _pageViewLB.font = [UIFont systemFontOfSize:10];
        _pageViewLB.textAlignment = NSTextAlignmentLeft;
    }
    return _pageViewLB;
}

@end
