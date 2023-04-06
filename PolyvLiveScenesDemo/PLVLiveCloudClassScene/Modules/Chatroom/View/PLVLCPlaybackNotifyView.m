//
//  PLVLCPlaybackNotifyView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/6/14.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCPlaybackNotifyView.h"
#import "PLVLCUtils.h"

static CGFloat kShowDuration = 5.0;

@interface PLVLCPlaybackNotifyView ()

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIButton *closeButton;

@end

@implementation PLVLCPlaybackNotifyView

#pragma mark - [ Override ]

- (void)layoutSubviews {
    self.label.frame = CGRectMake(15, (self.bounds.size.height - 20) / 2.0, self.bounds.size.width - 15 * 2, 20);
    self.closeButton.frame = CGRectMake(self.bounds.size.width - 32, 0, 32, self.bounds.size.height);
}

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:154.0/255.0 green:68.0/255.0 blue:70.0/255.0 alpha:1];
        self.hidden = YES;
        
        [self addSubview:self.label];
        [self addSubview:self.closeButton];
    }
    return self;
}

#pragma mark - [ Public Method ]

- (void)showNotifyhMessage:(NSString *)message {
    if (message && [message isKindOfClass:[NSString class]] && message.length > 0) {
        self.label.text = message;
        self.hidden = NO;
        
//        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(notifyHidden) object:nil];
//        [self performSelector:@selector(notifyHidden) withObject:nil afterDelay:kShowDuration];
    }
}

#pragma mark Getter & Setter

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.textColor = [UIColor whiteColor];
        _label.font = [UIFont systemFontOfSize:14];
    }
    return _label;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [PLVLCUtils imageForChatroomResource:@"plvlc_chatroom_notify_close_icon"];
        [_closeButton setImage:image forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

#pragma mark - [ Private Method ]

- (void)notifyHidden {
    self.hidden = YES;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)closeAction {
    self.hidden = YES;
}

@end
