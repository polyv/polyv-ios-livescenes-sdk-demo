//
//  PLVLCSubtitleSettingCell.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/5/9.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVLCSubtitleSettingCell.h"
#import "PLVLCSubtitleSettingsView.h"

@interface PLVLCSubtitleSettingCell () <PLVLCSubtitleSettingsViewDelegate>

@property (nonatomic, strong) NSArray<NSDictionary *> *subtitleList;
@property (nonatomic, strong) PLVLCSubtitleSettingsView *subtitleSettingsView;

@end

@implementation PLVLCSubtitleSettingCell

#pragma mark - [ Life Period ]
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.subtitleSettingsView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.subtitleSettingsView.frame = self.contentView.bounds;
}

#pragma mark - [ Public Methods ]

- (void)setupWithSubtitleList:(NSArray<NSDictionary *> *)subtitleList {
    self.subtitleList = subtitleList;
    [self.subtitleSettingsView setupWithSubtitleList:subtitleList];
}

#pragma mark - [ Private Methods ]

- (PLVLCSubtitleSettingsView *)subtitleSettingsView {
    if (!_subtitleSettingsView) {
        _subtitleSettingsView = [[PLVLCSubtitleSettingsView alloc] init];
        _subtitleSettingsView.delegate = self;
    }
    return _subtitleSettingsView;
}

#pragma mark - [ Delegate ]

- (void)PLVLCSubtitleSettingsView:(PLVLCSubtitleSettingsView *)settingsView
        didUpdateSubtitleState:(PLVPlaybackSubtitleModel *)originalSubtitle
                translateSubtitle:(PLVPlaybackSubtitleModel *)translateSubtitle {
    
    if ([self.delegate respondsToSelector:@selector(PLVLCSubtitleSettingCell:didUpdateSubtitleState:translateSubtitle:)]) {
        [self.delegate PLVLCSubtitleSettingCell:self didUpdateSubtitleState:originalSubtitle translateSubtitle:translateSubtitle];
    }
}

@end
