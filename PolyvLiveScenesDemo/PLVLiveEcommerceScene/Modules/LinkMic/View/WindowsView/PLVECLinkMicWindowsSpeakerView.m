//
//  PLVECLinkMicWindowsSpeakerView.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/11/5.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVECLinkMicWindowsSpeakerView.h"

@interface PLVECLinkMicWindowsSpeakerView ()

@property (nonatomic, strong) PLVECLinkMicWindowCell *linkMicWindowCell;

@end

@implementation PLVECLinkMicWindowsSpeakerView

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

- (void)showSpeakerViewWithUserModel:(PLVLinkMicOnlineUser *)aOnlineUser {
    self.hidden = NO;
    [self.linkMicWindowCell setUserModel:aOnlineUser hideCanvasViewWhenCameraClose:NO];
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

- (PLVECLinkMicWindowCell *)linkMicWindowCell {
    if (!_linkMicWindowCell) {
        _linkMicWindowCell = [[PLVECLinkMicWindowCell alloc] init];
    }
    return _linkMicWindowCell;
}

@end
