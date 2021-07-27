//
//  PLVSANewMessgaeTipView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/27.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSANewMessgaeTipView.h"

// Utils
#import "PLVSAUtils.h"

@interface PLVSANewMessgaeTipView ()

// Data
@property (nonatomic, assign) NSUInteger messageCount;
// UI
@property (nonatomic, strong) UILabel *label;

@end

@implementation PLVSANewMessgaeTipView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 12;
        self.layer.masksToBounds = YES;
        
        [self addSubview:self.label];
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
        [self addGestureRecognizer:gesture];
    }
    return self;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    self.label.frame = self.bounds;
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
        _label.textColor = [UIColor colorWithRed:3/255.0 green:130/255.0 blue:255/255.0 alpha:1/1.0];
        _label.font = [UIFont systemFontOfSize:14];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.text = @"查看新消息";
    }
    return _label;
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
