//
//  PLVHCNewMessgaeTipView.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/28.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCNewMessgaeTipView.h"

// Utils
#import "PLVHCUtils.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCNewMessgaeTipView()

// UI
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIImageView *imageView;

// Data
@property (nonatomic, assign) NSUInteger messageCount;

@end

@implementation PLVHCNewMessgaeTipView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#00B16C"];
        self.layer.cornerRadius = 14;
        self.layer.masksToBounds = YES;
        
        [self addSubview:self.label];
        [self addSubview:self.imageView];
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
        [self addGestureRecognizer:gesture];
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    self.label.frame = CGRectMake(20, 8, 72, 12);
    self.imageView.frame = CGRectMake(CGRectGetMaxX(self.label.frame) + 6, 6, 8, 16);
}

#pragma mark - [ Public Method ]

- (void)updateMeesageCount:(NSUInteger)count {
    self.messageCount = count;
    self.hidden = (count <= 0);
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.textColor = [UIColor whiteColor];
        _label.font = [UIFont systemFontOfSize:14];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.text = @"有更多消息";
    }
    return _label;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.image = [PLVHCUtils imageForChatroomResource:@"plvhc_chatroom_icon_newmsgtip"];
    }
    return _imageView;
}

#pragma mark - Event

#pragma mark Gesture
- (void)tapAction {
    [self updateMeesageCount:0];
    if (self.didTapNewMessageView) {
        self.didTapNewMessageView();
    }
}

@end
