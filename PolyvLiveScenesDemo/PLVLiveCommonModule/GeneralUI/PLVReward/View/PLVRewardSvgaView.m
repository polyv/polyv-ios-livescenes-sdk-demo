//
//  PLVRewardSVGAView.m
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/8/30.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVRewardSvgaView.h"
#import <SVGAPlayer/SVGAPlayer.h>
#import <SVGAPlayer/SVGAParser.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>


@interface PLVRewardSvgaView()<SVGAPlayerDelegate>

@property (nonatomic, strong) SVGAPlayer *svgaPlayer;

@property (nonatomic, strong) SVGAParser *svgaParser;

@end

@implementation PLVRewardSvgaView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.svgaPlayer.frame = self.bounds;
}

- (void)dealloc {
    self.willRemoveBlock();
}

#pragma mark - [ Private Method ]

- (NSString *)svgaNamedWithRewardItemName:(NSString *)name {
    NSString *svgaNamed = nil;
    if ([PLVFdUtil checkStringUseable:name]) {
        return svgaNamed;
    }
    return nil;
}


#pragma mark Initialize

- (void)setupUI {
    [self addSubview:self.svgaPlayer];
}

#pragma mark getter & setter

- (SVGAPlayer *)svgaPlayer {
    if (!_svgaPlayer) {
        _svgaPlayer = [[SVGAPlayer alloc] init];
        _svgaPlayer.loops = 1;
        _svgaPlayer.clearsAfterStop = YES;
        _svgaPlayer.delegate = self;
    }
    return _svgaPlayer;
}

- (SVGAParser *)svgaParser {
    if (!_svgaParser) {
        _svgaParser = [[SVGAParser alloc] init];
    }
    return _svgaParser;
}

#pragma mark - [ Public Method ]
 
- (void)parseWithRewardItemName:(NSString *)name
                     completion:(void(^)(void))completion {
    if (![PLVFdUtil checkStringUseable:name]) {
        return;
    }
    
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"PLVReward" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    
    __weak typeof(self)weakSelf = self;
    [self.svgaParser parseWithNamed:name inBundle:bundle completionBlock:^(SVGAVideoEntity * _Nonnull videoItem) {
        if (completion) {
            completion();
        }
        weakSelf.svgaPlayer.videoItem = videoItem;
        [weakSelf.svgaPlayer startAnimation];
    } failureBlock:^(NSError * _Nonnull error) {
        PLV_LOG_DEBUG(PLVConsoleLogModuleTypeInteract, @"PLVGiveRewardSvgaView error %@",error.localizedDescription);
    }];
}

#pragma mark - Delegate

#pragma mark SVGAPlayerDelegate

- (void)svgaPlayerDidFinishedAnimation:(SVGAPlayer *)player {
    [self removeFromSuperview];
}


@end
