//
//  PLVSALinkMicWindowsSpeakerView.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/11/5.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSALinkMicWindowsSpeakerView.h"

@interface PLVSALinkMicWindowsSpeakerView ()

@property (nonatomic, strong) PLVSALinkMicWindowCell *linkMicWindowCell;

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
    
    self.linkMicWindowCell.frame = self.bounds;
}

#pragma mark - [ Public Method ]

- (void)showSpeakerViewWithUserModel:(PLVLinkMicOnlineUser *)aOnlineUser delegate:(id<PLVSALinkMicWindowCellDelegate>)delegate {
    self.hidden = NO;
    self.linkMicWindowCell.delegate = delegate;
    [self.linkMicWindowCell setUserModel:aOnlineUser hideCanvasViewWhenCameraClose:NO];
//    [self.linkMicWindowCell switchToShowRtcContentView:aOnlineUser.rtcView];
}

- (void)showSpeakerViewWithExternalView:(UIView *)externalView {
    self.hidden = NO;
    [self.linkMicWindowCell switchToShowExternalContentView:externalView];
}

- (void)hideSpeakerView {
    self.hidden = YES;
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    self.hidden = YES;
    [self addSubview:self.linkMicWindowCell];
}

#pragma mark Getter

- (PLVSALinkMicWindowCell *)linkMicWindowCell {
    if (!_linkMicWindowCell) {
        _linkMicWindowCell = [[PLVSALinkMicWindowCell alloc] init];
    }
    return _linkMicWindowCell;
}

@end
