//
//  PLVLCLinkMicSpeakingView.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/11/25.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCLinkMicSpeakingView.h"

#import <PolyvFoundationSDK/PolyvFoundationSDK.h>

@interface PLVLCLinkMicSpeakingView ()

#pragma mark 功能对象
@property (nonatomic, strong) NSTimer * timer; /// 文本回收定时器 (因对回收文本的时间准确度要求不高，因此Timer对回收文本的时间范围在 1~2秒之间)

#pragma mark 数据
@property (nonatomic, assign) NSTimeInterval lastShowTimestamp;

#pragma mark UI
@property (nonatomic, strong) UILabel * nickNamesLabel; /// 多个昵称 文本框
@property (nonatomic, strong) UILabel * speakingLabel;  /// ‘正在发言’文本框

@end

@implementation PLVLCLinkMicSpeakingView

#pragma mark - [ Life Period ]
- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
    [_timer invalidate];
    _timer = nil;
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupData];
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews{
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (fullScreen) {
        CGFloat leftRightPadding = 8.0;
        CGFloat topPadding = 4.0;
        CGFloat fitTextWidth = [self.nickNamesLabel sizeThatFits:CGSizeMake(150, 17)].width;
        self.nickNamesLabel.frame = CGRectMake(leftRightPadding, topPadding, fitTextWidth, 17);
        
        self.speakingLabel.frame = CGRectMake(CGRectGetMaxX(self.nickNamesLabel.frame) + 4, topPadding, 48.0, 17);
    }
}


#pragma mark - [ Public Methods ]
- (void)updateSpeakingInfoWithNicknames:(NSArray<NSString *> *)nicknamesArray{
    // 设置限制
    NSInteger maxNicknameLength = 6; /// 昵称最大字数限制
    NSInteger maxNicknameCount = 2;  /// 最多昵称个数
    
    // 拼接字符串
    NSString * fullNicknames = @"";
    NSInteger legalNicknameCount = 0;
    for (int i = 0; i < nicknamesArray.count; i++) {
        if (legalNicknameCount >= maxNicknameCount) { break; }
        
        NSString * nickname = nicknamesArray[i];
        NSString * showNickname = nickname;
        if ([PLVFdUtil checkStringUseable:nickname]) {
            if ([nickname hasSuffix:@"(我)"] && nickname.length > (maxNicknameLength + 3)) {
                showNickname = [NSString stringWithFormat:@"%@...(我)",[nickname substringToIndex:maxNicknameLength]];
            }else if (nickname.length > maxNicknameLength){
                showNickname = [NSString stringWithFormat:@"%@...",[nickname substringToIndex:maxNicknameLength]];
            }
            legalNicknameCount++;
        }else{
            continue;
        }
        if (i > 0) {
            fullNicknames = [fullNicknames stringByAppendingFormat:@"、%@",showNickname];
        }else{
            fullNicknames = showNickname;
        }
    }
    if (legalNicknameCount > 1) { [fullNicknames stringByAppendingString:@"等"]; }
    self.nickNamesLabel.text = fullNicknames;
    [self changeHiddenStatus];
}

#pragma mark Getter
- (BOOL)currentShow{
    return !self.hidden;
}

- (CGFloat)currentWidthWithNicknamesText{
    CGFloat fitTextWidth = [self.nickNamesLabel sizeThatFits:CGSizeMake(150, 17)].width;
    CGFloat fitTotalWidth = fitTextWidth + 4 + 48 + 8 * 2;
    return fitTotalWidth;
}


#pragma mark - [ Private Methods ]
- (void)setupData{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(timerEvent:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)setupUI{
    self.hidden = YES;
    self.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.5];
    self.layer.cornerRadius = 12.5;
    self.userInteractionEnabled = NO;
    
    [self addSubview:self.nickNamesLabel];
    [self addSubview:self.speakingLabel];
}

- (void)changeHiddenStatus{
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (fullScreen) {
        if ([PLVFdUtil checkStringUseable:self.nickNamesLabel.text]) {
            self.hidden = NO;
            self.lastShowTimestamp = [[NSDate date]timeIntervalSince1970];
        }else{
            self.hidden = YES;
        }
    }else{
        self.hidden = YES;
    }
}

#pragma mark Getter
- (UILabel *)nickNamesLabel{
    if (!_nickNamesLabel) {
        _nickNamesLabel = [[UILabel alloc] init];
        _nickNamesLabel.textAlignment = NSTextAlignmentCenter;
        _nickNamesLabel.textColor = [UIColor whiteColor];
        _nickNamesLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    }
    return _nickNamesLabel;
}

- (UILabel *)speakingLabel{
    if (!_speakingLabel) {
        _speakingLabel = [[UILabel alloc] init];
        _speakingLabel.text = @"正在发言";
        _speakingLabel.textAlignment = NSTextAlignmentCenter;
        _speakingLabel.textColor = [UIColor colorWithRed:208/255.0 green:208/255.0 blue:208/255.0 alpha:1.0];
        _speakingLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    }
    return _speakingLabel;
}


#pragma mark - [ Event ]
- (void)timerEvent:(NSTimer *)timer{
    if (self.currentShow && self.lastShowTimestamp > 0 &&
        ([[NSDate date] timeIntervalSince1970] - self.lastShowTimestamp) > 1) {
        self.nickNamesLabel.text = @"";
        [self changeHiddenStatus];
    }
}

@end
