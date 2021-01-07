//
//  PLVECLiveRoomInfoView.m
//  PolyvLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECLiveRoomInfoView.h"
#import "PLVECUtils.h"

@interface PLVECLiveRoomInfoView ()

@property (nonatomic, strong) UIImageView *watchImageView;

@end

@implementation PLVECLiveRoomInfoView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4f];
        self.layer.cornerRadius = 18;
        self.layer.masksToBounds = YES;
        
        self.coverImageView = [[UIImageView alloc] initWithFrame:CGRectMake(4, 4, 28, 28)];
        self.coverImageView.layer.cornerRadius = 14;
        self.coverImageView.layer.masksToBounds = YES;
        [self addSubview:self.coverImageView];
        
        self.publisherLB = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.coverImageView.frame)+4, 4, CGRectGetWidth(frame)-CGRectGetMaxX(self.coverImageView.frame)-8, 14)];
        self.publisherLB.textColor = UIColor.whiteColor;
        self.publisherLB.font = [UIFont systemFontOfSize:14];
        self.publisherLB.textAlignment = NSTextAlignmentLeft;
        [self addSubview:self.publisherLB];
        
        UIImage *watchImage = [PLVECUtils imageForWatchResource:@"plv_watch_img"];
        self.watchImageView = [[UIImageView alloc] initWithImage:watchImage];
        self.watchImageView.frame = CGRectMake(CGRectGetMinX(self.publisherLB.frame), CGRectGetMaxY(self.publisherLB.frame)+2, 12, 12);
        [self addSubview:self.watchImageView];
        
        self.pageViewLB = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.watchImageView.frame)+2, CGRectGetMinY(self.watchImageView.frame), CGRectGetWidth(frame)-CGRectGetMaxX(self.watchImageView.frame)-6, 10)];
        self.pageViewLB.textColor = UIColor.whiteColor;
        self.pageViewLB.font = [UIFont systemFontOfSize:10];
        self.pageViewLB.textAlignment = NSTextAlignmentLeft;
        [self addSubview:self.pageViewLB];
    }
    return self;
}

@end
