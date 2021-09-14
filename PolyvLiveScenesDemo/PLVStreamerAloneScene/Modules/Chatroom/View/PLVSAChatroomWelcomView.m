//
//  PLVSAChatroomWelcomView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/4.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAChatroomWelcomView.h"

// 工具
#import "PLVSAUtils.h"

@implementation PLVSAChatroomWelcomView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIImage *welcomeImage = [PLVSAUtils imageForChatroomResource:@"plvsa_chatroom_bg_welcome"];
        self.welcomImgView = [[UIImageView alloc] initWithImage:welcomeImage];
        [self addSubview:self.welcomImgView];
        
        self.messageLabel = [[UILabel alloc] init];
        self.messageLabel.textColor = UIColor.whiteColor;
        self.messageLabel.textAlignment = NSTextAlignmentLeft;
        self.messageLabel.font = [UIFont systemFontOfSize:14];
        [self addSubview:self.messageLabel];
    }
    return self;
}

#pragma mark - [ Override ]

-(void)layoutSubviews {
    [super layoutSubviews];
    
    self.welcomImgView.frame = self.bounds;
    self.messageLabel.frame = CGRectMake(15, 0, CGRectGetWidth(self.bounds)-15, CGRectGetHeight(self.bounds));
}

@end
