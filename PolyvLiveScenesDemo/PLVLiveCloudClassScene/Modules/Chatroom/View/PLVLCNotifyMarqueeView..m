//
//  PLVLCNotifyMarqueeView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/10/13.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCNotifyMarqueeView.h"
#import "PLVMarqueeLabel.h"
#import "PLVEmoticonManager.h"

@interface PLVLCNotifyMarqueeView ()

@property (nonatomic, assign) CGFloat scrollDuration;
@property (nonatomic, strong) PLVMarqueeLabel *marqueeLabel;

@end

@implementation PLVLCNotifyMarqueeView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:57.0/255.0 green:56.0/255.0 blue:66.0/255.0 alpha:0.8];
        self.hidden = YES;
        self.scrollDuration = 8.0;
    }
    return self;
}

- (void)layoutSubviews {
    if (!_marqueeLabel) {
        [self addSubview:self.marqueeLabel];
    }
}
#pragma mark - Getter & Setter

- (PLVMarqueeLabel *)marqueeLabel {
    if (!_marqueeLabel) {
        _marqueeLabel = [[PLVMarqueeLabel alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height) duration:self.scrollDuration andFadeLength:0];
        _marqueeLabel.textColor = [UIColor whiteColor];
        _marqueeLabel.leadingBuffer = CGRectGetWidth(self.bounds);
    }
    return _marqueeLabel;
}

#pragma mark - Public Method

- (void)showNotifyhMessage:(NSString *)message {
    message = [message stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    UIFont *font = [UIFont systemFontOfSize:14];
    NSAttributedString *emoticonText = [[NSAttributedString alloc] initWithString:message attributes:@{NSFontAttributeName:font}];
    NSMutableAttributedString *muString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:emoticonText font:font];
    [self.marqueeLabel setAttributedText:muString];
    
    [self beginAnimation];
}

#pragma mark - Pravite Method

- (void)beginAnimation {
    self.hidden = NO;
    [self.marqueeLabel restartLabel];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(animationFinish) object:nil];
    [self performSelector:@selector(animationFinish) withObject:nil afterDelay:self.scrollDuration*3];
}

- (void)animationFinish {
    [self.marqueeLabel shutdownLabel];
    self.hidden = YES;
}

@end
