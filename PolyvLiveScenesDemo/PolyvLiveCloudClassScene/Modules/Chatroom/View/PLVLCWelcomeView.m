//
//  PLVLCWelcomeView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/10/12.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCWelcomeView.h"

@interface PLVLCWelcomeView ()

@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *highlightColor;
@property (nonatomic, strong) UILabel *marqueeLabel;

@end

@implementation PLVLCWelcomeView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.textColor = [UIColor blackColor];
        self.highlightColor = [UIColor colorWithRed:130.0/255.0 green:179.0/255.0 blue:201.0/255.0 alpha:1.0];
        UIColor *backgroudColor = [UIColor colorWithRed:253.0 / 255.0 green:248.0 / 255.0 blue:203.0 / 255.0 alpha:1.0];
        UIColor *borderColor = [UIColor lightGrayColor];
        
        self.clipsToBounds = YES;
        self.backgroundColor = backgroudColor;
        self.layer.borderColor = borderColor.CGColor;
        self.layer.borderWidth = 0.5;
        self.layer.cornerRadius = 5.0;
        self.hidden = YES;
        
        [self addSubview:self.marqueeLabel];
    }
    return self;
}

#pragma mark - Getter & Setter

- (UILabel *)marqueeLabel {
    if (!_marqueeLabel) {
        _marqueeLabel = [[UILabel alloc] init];
        _marqueeLabel.textAlignment = NSTextAlignmentCenter;
        _marqueeLabel.textColor = self.textColor;
    }
    return _marqueeLabel;
}

#pragma mark - Public Method

- (void)showWelcomeWithNickNmame:(NSString *)nickName {
    if (!nickName || ![nickName isKindOfClass:[NSString class]] || nickName.length == 0) {
        return;
    }
    
    NSString *welcomeMessage = [NSString stringWithFormat:@"欢迎%@加入", nickName];
    NSMutableAttributedString *muString = [[NSMutableAttributedString alloc] initWithString:welcomeMessage];
    [muString setAttributes:@{NSForegroundColorAttributeName: self.highlightColor} range:NSMakeRange(2, nickName.length)];
        
    UIFont *font_12 = [UIFont systemFontOfSize:12];
    UIFont *font_10 = [UIFont systemFontOfSize:10];
    CGSize textSize = [muString.string sizeWithAttributes:@{NSFontAttributeName:font_12}];
    if (textSize.width + 6.0 > self.bounds.size.width) {
        self.marqueeLabel.font = font_10;
    } else {
        self.marqueeLabel.font = font_12;
    }
    [self.marqueeLabel setAttributedText:muString];
    
    [self beginAnimation];
}

#pragma mark - Pravite Method

- (void)beginAnimation {
    self.hidden = NO;
    
    CGRect marqueeRect = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    marqueeRect.origin.x += marqueeRect.size.width;
    self.marqueeLabel.frame = marqueeRect;
    
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:2.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.marqueeLabel.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    } completion:nil];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(animationFinish) object:nil];
    [self performSelector:@selector(animationFinish) withObject:nil afterDelay:4.0];
}

- (void)animationFinish {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:2.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect marqueeRect = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
        marqueeRect.origin.x -= marqueeRect.size.width;
        weakSelf.marqueeLabel.frame = marqueeRect;
    } completion:^(BOOL finished) {
        weakSelf.hidden = YES;
    }];
}

@end
