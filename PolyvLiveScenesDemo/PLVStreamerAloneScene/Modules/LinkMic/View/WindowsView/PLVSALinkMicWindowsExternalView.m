//
//  PLVSALinkMicWindowsExternalView.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2023/10/18.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVSALinkMicWindowsExternalView.h"

@interface PLVSALinkMicWindowsExternalView ()

@property (nonatomic, strong) PLVSALinkMicWindowCell *linkMicWindowCell;

@end

@implementation PLVSALinkMicWindowsExternalView

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

- (void)showExternalViewWithUserModel:(PLVLinkMicOnlineUser *)aOnlineUser delegate:(id<PLVSALinkMicWindowCellDelegate>)delegate {
    self.hidden = NO;
    self.linkMicWindowCell.delegate = delegate;
    [self.linkMicWindowCell setUserModel:aOnlineUser hideCanvasViewWhenCameraClose:NO];
//    [self.linkMicWindowCell switchToShowRtcContentView:aOnlineUser.rtcView];
}

- (void)showExternalViewWithExternalView:(UIView *)externalView {
    self.hidden = NO;
    [self.linkMicWindowCell switchToShowExternalContentView:externalView];
}

- (void)hideExternalView {
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
