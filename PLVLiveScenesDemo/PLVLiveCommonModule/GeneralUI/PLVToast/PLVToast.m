//
//  PLVToast.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/1.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVToast.h"

static CGFloat kToastLabelFontSize = 14.0;
static CGFloat kToastHideDelay = 2.0;

static CGFloat kToastMaxWidth = 196.0;
static CGFloat kToastMaxHeight = 80.0;

@interface PLVToast ()

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, weak) NSTimer *hideDelayTimer;

@end

@implementation PLVToast

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0x1b/255.0 green:0x20/255.0 blue:0x2d/255.0 alpha:0.6];
        
        [self addSubview:self.label];
    }
    return self;
}

#pragma mark - Getter

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.font = [UIFont systemFontOfSize:kToastLabelFontSize];
        _label.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1.0];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.numberOfLines = 4;
        _label.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _label;
}

#pragma mark - Show & Hide

+ (void)showToastWithMessage:(NSString *)message inView:(UIView *)view {
    if (!message || ![message isKindOfClass:[NSString class]] || message.length == 0 ||
        !view) {
        return;
    }
    
    PLVToast *toast = [[PLVToast alloc] init];
    [toast showMessage:message];
    [view addSubview:toast];
    
    CGPoint superViewCenter = CGPointMake(view.bounds.size.width / 2.0, view.bounds.size.height / 2.0);
    toast.center = superViewCenter;
    [toast hideAfterDelay:kToastHideDelay];
}

- (void)showMessage:(NSString *)message {
    CGSize messageSize = [message boundingRectWithSize:CGSizeMake(kToastMaxWidth, kToastMaxHeight)
                                               options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                            attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:kToastLabelFontSize]}
                                               context:nil].size;
    self.label.text = message;
    
    if (messageSize.height > 20) {
        self.layer.cornerRadius = 8.0;
        self.label.textAlignment = NSTextAlignmentLeft;
        self.label.frame = CGRectMake(16, 10, messageSize.width, messageSize.height);
        self.frame = CGRectMake(0, 0, messageSize.width + 16 * 2, messageSize.height + 10 * 2);
    } else { // 
        self.layer.cornerRadius = 20;
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.frame = CGRectMake(0, 10, messageSize.width + 24 * 2, 20);
        self.frame = CGRectMake(0, 0, messageSize.width + 24 * 2, 40);
    }
}

- (void)hideAfterDelay:(NSTimeInterval)delay {
    [self.hideDelayTimer invalidate];

    NSTimer *timer = [NSTimer timerWithTimeInterval:delay target:self selector:@selector(handleHideTimer) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.hideDelayTimer = timer;
}

- (void)handleHideTimer {
    [self removeFromSuperview];
    [self.hideDelayTimer invalidate];
    self.hideDelayTimer = nil;
}

@end
