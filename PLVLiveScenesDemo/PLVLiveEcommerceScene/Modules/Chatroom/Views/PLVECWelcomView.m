//
//  PLVECWelcomView.m
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/6/16.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECWelcomView.h"
#import "PLVECUtils.h"

@implementation PLVECWelcomView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIImage *welcomeImage = [PLVECUtils imageForWatchResource:@"plv_img_back_welcome"];
        self.welcomImgView = [[UIImageView alloc] initWithImage:welcomeImage];
        [self addSubview:self.welcomImgView];
        
        self.messageLB = [[UILabel alloc] init];
        self.messageLB.textColor = UIColor.whiteColor;
        self.messageLB.textAlignment = NSTextAlignmentLeft;
        self.messageLB.font = [UIFont systemFontOfSize:14];
        [self addSubview:self.messageLB];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    self.welcomImgView.frame = self.bounds;
    self.messageLB.frame = CGRectMake(15, 0, CGRectGetWidth(self.bounds)-15, CGRectGetHeight(self.bounds));
}

@end
