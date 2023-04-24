//
//  PLVLCPlaybackNotifyView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/6/14.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCPlaybackNotifyView.h"

static CGFloat kShowDuration = 5.0;

@interface PLVLCPlaybackNotifyView ()

@property (nonatomic, strong) UILabel *label;

@end

@implementation PLVLCPlaybackNotifyView

#pragma mark - [ Override ]

- (void)layoutSubviews {
    self.label.frame = CGRectMake(15, (self.bounds.size.height - 20) / 2.0, self.bounds.size.width - 15 * 2, 20);
}

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:154.0/255.0 green:68.0/255.0 blue:70.0/255.0 alpha:1];
        self.hidden = YES;
        
        [self addSubview:self.label];
    }
    return self;
}

#pragma mark - [ Public Method ]

- (void)showNotifyhMessage:(NSString *)message {
    if (message && [message isKindOfClass:[NSString class]] && message.length > 0) {
        self.label.text = message;
        self.hidden = NO;
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(notifyHidden) object:nil];
        [self performSelector:@selector(notifyHidden) withObject:nil afterDelay:kShowDuration];
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

#pragma mark - [ Private Method ]

- (void)notifyHidden {
    self.hidden = YES;
}

@end
