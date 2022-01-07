//
//  PLVSALinkMicWindowsSpeakerView.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/11/5.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSALinkMicWindowsSpeakerView.h"

#import "PLVLinkMicOnlineUser+SA.h"

@interface PLVSALinkMicWindowsSpeakerView ()

@property (nonatomic, strong) UIView *contentBackgroudView; // 内容背景视图 (负责承载 RTC画面)

@end

@implementation PLVSALinkMicWindowsSpeakerView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.contentBackgroudView.frame = self.bounds;
}

#pragma mark - [ Public Method ]

- (void)showSpeakerViewWithUserModel:(PLVLinkMicOnlineUser *)aOnlineUser {
    self.hidden = NO;
    [aOnlineUser.canvasView rtcViewShow:aOnlineUser.currentCameraShouldShow];
    aOnlineUser.cameraShouldShowChangedBlock = ^(PLVLinkMicOnlineUser * _Nonnull onlineUser) {
        [onlineUser.canvasView rtcViewShow:onlineUser.currentCameraShouldShow];
    };
    [self contentBackgroundViewDisplaySubview:aOnlineUser.canvasView];
}

- (void)hideSpeakerView {
    self.hidden = YES;
    [self removeSubviewsFromSuperview:self.contentBackgroudView];
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    self.hidden = YES;
    [self addSubview:self.contentBackgroudView];
}

- (void)removeSubviewsFromSuperview:(UIView *)superview{
    for (UIView * subview in superview.subviews) { [subview removeFromSuperview]; }
}

- (void)contentBackgroundViewDisplaySubview:(UIView *)subview {
    if (subview && [subview isKindOfClass:UIView.class]) {
        [self removeSubviewsFromSuperview:self.contentBackgroudView];
        [self.contentBackgroudView addSubview:subview];
        subview.frame = self.contentBackgroudView.bounds;
        subview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }else{
        NSLog(@"PLVSALinkMicWindowsSpeakerView - contentBackgroundViewDisplaySubview failed, subview:%@",subview);
    }
}

#pragma mark Getter

- (UIView *)contentBackgroudView {
    if (!_contentBackgroudView) {
        _contentBackgroudView = [[UIView alloc] init];
    }
    return _contentBackgroudView;
}

@end
