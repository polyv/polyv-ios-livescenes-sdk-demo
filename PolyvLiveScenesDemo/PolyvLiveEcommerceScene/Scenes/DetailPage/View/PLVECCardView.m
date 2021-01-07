//
//  PLVECCardView.m
//  PolyvLiveEcommerceDemo
//
//  Created by ftao on 2020/5/25.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECCardView.h"

@implementation PLVECCardView

#pragma mark - Override

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = YES;
        self.backgroundColor = [UIColor colorWithWhite:243/255.f alpha:0.8f];
        
        self.iconImgView = [[UIImageView alloc] initWithFrame:CGRectMake(15, 15, 16, 16)];
        [self addSubview:self.iconImgView];
        
        self.titleLB = [[UILabel alloc] initWithFrame:CGRectMake(39, 15, 120, 16)];
        self.titleLB.textColor = [UIColor colorWithWhite:51/255.f alpha:1];
        self.titleLB.textAlignment = NSTextAlignmentLeft;
        self.titleLB.font = [UIFont systemFontOfSize:16];
        [self addSubview:self.titleLB];
    }
    return self;
}

@end
