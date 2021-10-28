//
//  PLVHCGrantCupView.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/8/23.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCGrantCupView.h"

// 工具
#import "PLVHCUtils.h"

// 依赖库
#import <AVFoundation/AVFoundation.h>
#import <SVGAPlayer/SVGA.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCGrantCupView()<
SVGAPlayerDelegate
>

@property (nonatomic, strong) UILabel *nickNameLabel; // 昵称

@property (nonatomic, strong) AVAudioPlayer *soundPlayer; // 音效播放器

@property (nonatomic, strong) SVGAPlayer *svgaPlayer; // svga特效播放器
@property (nonatomic, strong) SVGAParser *svgaParser; // svga特效解析器

@end

@implementation PLVHCGrantCupView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.svgaPlayer];
        [self addSubview:self.nickNameLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.frame = [UIScreen mainScreen].bounds;
    
    self.svgaPlayer.frame = CGRectMake(0, 0, 250, 250);
    self.svgaPlayer.center = self.center;
    
    CGRect frame = CGRectMake(0, CGRectGetMaxY(self.svgaPlayer.frame) - 95, self.frame.size.width, 20);
    self.nickNameLabel.frame = frame;
}

#pragma mark - [ Public Method ]

- (void)showInView:(UIView *)view nickName:(nonnull NSString *)nickName{
    if (!view) {
        return;
    }
    [view addSubview:self];
    
    if ([PLVFdUtil checkStringUseable:nickName]) {
        self.nickNameLabel.text = nickName;
    }
    
    [self.svgaParser parseWithNamed:@"plvhc_liveroom_grantcup_svga" inBundle:[PLVHCUtils bundlerForLiveroom] completionBlock:^(SVGAVideoEntity * _Nonnull videoItem) {
        // 音效
        [self playSound];
        // 特效
        self.svgaPlayer.videoItem = videoItem;
        [self.svgaPlayer startAnimation];
        
    } failureBlock:^(NSError * _Nonnull error) {
        [self dismiss];
        NSLog(@"-[PLVHCGrantCupView showInView:nickName:] faileure: %@",error);
    }];
}

- (void)dismiss {
    [self removeFromSuperview];
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (UILabel *)nickNameLabel {
    if (!_nickNameLabel) {
        _nickNameLabel = [[UILabel alloc] init];
        _nickNameLabel.textColor = [UIColor whiteColor];
        _nickNameLabel.textAlignment = NSTextAlignmentCenter;
        if (@available(iOS 8.2, *)) {
            _nickNameLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
        } else {
            _nickNameLabel.font = [UIFont systemFontOfSize:18];
        }
        _nickNameLabel.alpha = 0;
    }
    return _nickNameLabel;
}

- (AVAudioPlayer *)soundPlayer {
    if (!_soundPlayer) {
        NSString *path = [[PLVHCUtils bundlerForLiveroom] pathForResource:@"plvhc_liveroom_grantcup_audio" ofType:@"mp3"];
        NSURL *url = [NSURL fileURLWithPath:path];
        NSError *error = nil;
        _soundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        _soundPlayer.volume = 1.0;
    }
    return _soundPlayer;
}

- (SVGAPlayer *)svgaPlayer {
    if (!_svgaPlayer) {
        _svgaPlayer = [[SVGAPlayer alloc] init];
        _svgaPlayer.delegate = self;
        _svgaPlayer.loops = 1;
        _svgaPlayer.clearsAfterStop = YES;
    }
    return _svgaPlayer;
}

- (SVGAParser *)svgaParser {
    if (!_svgaParser) {
        _svgaParser = [[SVGAParser alloc] init];
    }
    return _svgaParser;
}

#pragma mark soundPlayer play/stop

- (void)playSound {
    [self.soundPlayer prepareToPlay];
    [self.soundPlayer play];
}

- (void)stopSoundPlay {
    if (self.soundPlayer.isPlaying) {
        [self.soundPlayer stop];
        _soundPlayer = nil;
    }
}

#pragma mark resetNickNameLabel

- (void)resetNickNameLabel {
    self.nickNameLabel.alpha = 0;
    
    CGRect frame = CGRectMake(0, CGRectGetMaxY(self.svgaPlayer.frame) - 95, self.frame.size.width, 20);
    self.nickNameLabel.frame = frame;
    
    if (@available(iOS 8.2, *)) {
        self.nickNameLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    } else {
        self.nickNameLabel.font = [UIFont systemFontOfSize:18];
    }
}

#pragma mark - [ Delegate ]
#pragma mark SVGAPlayerDelegate

- (void)svgaPlayer:(SVGAPlayer *)player didAnimatedToPercentage:(CGFloat)percentage {
    if (percentage >= 0.77) { // 77% 已隐藏动画特效
        self.nickNameLabel.alpha = 0;
    } else if (percentage >= 0.66) { // 66% 开始隐藏动画特效
        CGFloat alpha = 1 - percentage;
        self.nickNameLabel.alpha = alpha;
        
        CGFloat fontSize = self.nickNameLabel.font.pointSize;
        fontSize -= 2 * percentage;
        if (@available(iOS 8.2, *)) {
            self.nickNameLabel.font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightSemibold];
        } else {
            self.nickNameLabel.font = [UIFont systemFontOfSize:fontSize];
        }
        
        CGRect frame = self.nickNameLabel.frame;
        frame.origin.y -= 2 * percentage;
        self.nickNameLabel.frame = frame;
    } else if (percentage >= 0.24){ // 24% 显示昵称
        self.nickNameLabel.alpha = 1;
    }
}

- (void)svgaPlayerDidFinishedAnimation:(SVGAPlayer *)player {
    [self dismiss];
    [self stopSoundPlay];
    [self resetNickNameLabel];
}

@end
