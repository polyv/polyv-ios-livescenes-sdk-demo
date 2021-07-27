//
//  PLVLCDescTopView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/25.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCDescTopView.h"
#import "PLVLCUtils.h"
#import <PLVLiveScenesSDK/PLVLiveVideoChannelMenuInfo.h>
#import <PLVFoundationSDK/PLVFdUtil.h>

#define kLightGrayColor [UIColor colorWithRed:0xAD/255.0 green:0xAD/255.0 blue:0xC0/255.0 alpha:1.0]

@interface PLVLCDescTopView ()

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *startTimeLable;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIView *line;
@property (nonatomic, strong) UIImageView *publisherImageView;
@property (nonatomic, strong) UILabel *publisherLabel;
@property (nonatomic, strong) UIImageView *likeImageView;
@property (nonatomic, strong) UILabel *likeCountLabel;

@end

@implementation PLVLCDescTopView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.avatarImageView];
        [self addSubview:self.titleLabel];
        [self addSubview:self.startTimeLable];
        [self addSubview:self.statusLabel];
        [self addSubview:self.line];
        [self addSubview:self.publisherImageView];
        [self addSubview:self.publisherLabel];
        [self addSubview:self.likeImageView];
        [self addSubview:self.likeCountLabel];
    }
    return self;
}

- (void)layoutSubviews {
    self.avatarImageView.frame = CGRectMake(16, 15, 40, 40);
    
    CGFloat topLabelOriginX = 66.0;
    self.titleLabel.frame = CGRectMake(topLabelOriginX, 16, self.bounds.size.width - topLabelOriginX * 2 - 14, 17);
    self.startTimeLable.frame = CGRectMake(topLabelOriginX, 41, self.bounds.size.width - topLabelOriginX * 2 - 14, 13);
    
    self.line.frame = CGRectMake(0, 72, self.bounds.size.width, 1);
    
    self.publisherImageView.frame = CGRectMake(16, CGRectGetMaxY(self.line.frame) + 10, 16, 16);
    self.publisherLabel.frame = CGRectMake(36, CGRectGetMaxY(self.line.frame) + 12, self.bounds.size.width - 36 - 56 - 16, 13);
    self.likeImageView.frame = CGRectMake(self.bounds.size.width - 56 - 16, CGRectGetMaxY(self.line.frame) + 10, 16, 16);
    
    CGFloat labelOriginX = CGRectGetMaxX(self.likeImageView.frame) + 4;
    self.likeCountLabel.frame = CGRectMake(labelOriginX, CGRectGetMaxY(self.line.frame) + 12, self.bounds.size.width - labelOriginX, 12);
    
    if (self.status == PLVLCLiveStatusNone) {
        self.statusLabel.frame = CGRectMake(self.bounds.size.width - 64 - 16, 15, 64, 24);
    } else {
        self.statusLabel.frame = CGRectMake(self.bounds.size.width - 50 - 16, 15, 50, 24);
    }
}

#pragma mark - Getter & Setter

- (UIImageView *)avatarImageView {
    if (!_avatarImageView) {
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.image = [PLVLCUtils imageForMenuResource:@"plvlc_menu_defaultUser"];
    }
    return _avatarImageView;
}

- (UIImageView *)publisherImageView {
    if (!_publisherImageView) {
        _publisherImageView = [[UIImageView alloc] init];
        _publisherImageView.image = [PLVLCUtils imageForMenuResource:@"plvlc_menu_publisher"];
    }
    return _publisherImageView;
}

- (UIImageView *)likeImageView {
    if (!_likeImageView) {
        _likeImageView = [[UIImageView alloc] init];
        _likeImageView.image = [PLVLCUtils imageForMenuResource:@"plvlc_menu_like"];
    }
    return _likeImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:16];
        _titleLabel.textColor = [UIColor whiteColor];
    }
    return _titleLabel;
}

- (UILabel *)startTimeLable {
    if (!_startTimeLable) {
        _startTimeLable = [[UILabel alloc] init];
        _startTimeLable.font = [UIFont systemFontOfSize:12];
        _startTimeLable.textColor = kLightGrayColor;
    }
    return _startTimeLable;
}

- (UILabel *)statusLabel {
    if (!_statusLabel) {
        _statusLabel = [[UILabel alloc] init];
        _statusLabel.font = [UIFont systemFontOfSize:14];
        _statusLabel.layer.cornerRadius = 2.0;
        _statusLabel.layer.borderWidth = 1.0;
        _statusLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _statusLabel;
}

- (UIView *)line {
    if (!_line) {
        _line = [[UIView alloc] init];
        _line.backgroundColor = [UIColor blackColor];
    }
    return _line;
}

- (UILabel *)publisherLabel {
    if (!_publisherLabel) {
        _publisherLabel = [[UILabel alloc] init];
        _publisherLabel.font = [UIFont systemFontOfSize:12];
        _publisherLabel.textColor = kLightGrayColor;
    }
    return _publisherLabel;
}

- (UILabel *)likeCountLabel {
    if (!_likeCountLabel) {
        _likeCountLabel = [[UILabel alloc] init];
        _likeCountLabel.font = [UIFont systemFontOfSize:12];
        _likeCountLabel.textColor = kLightGrayColor;
    }
    return _likeCountLabel;
}

- (void)setChannelInfo:(PLVLiveVideoChannelMenuInfo *)channelInfo {
    if (channelInfo == nil) {
        return;
    }
    
    _channelInfo = channelInfo;
    
    if (channelInfo.coverImage && [channelInfo.coverImage isKindOfClass:[NSString class]] && channelInfo.coverImage.length > 0) {
        [PLVFdUtil setImageWithURL:[NSURL URLWithString:channelInfo.coverImage] inImageView:self.avatarImageView completed:nil];
    }
    
    if (channelInfo.name && [channelInfo.name isKindOfClass:[NSString class]] && channelInfo.name.length > 0) {
        NSString *name = channelInfo.name;
        if (name.length > 12) {
            name = [NSString stringWithFormat:@"%@...", [channelInfo.name substringToIndex:12]];
        }
        
        self.titleLabel.text = name;
    }
        
    if (channelInfo.startTime && [channelInfo.startTime isKindOfClass:[NSString class]] && channelInfo.startTime.length > 0) {
        self.startTimeLable.text = [NSString stringWithFormat:@"直播时间：%@", channelInfo.startTime];
    } else {
        self.startTimeLable.text = @"直播时间:无";
    }
    
    self.status = [self liveStatusWithString:channelInfo.watchStatus];
    
    if (channelInfo.publisher && [channelInfo.publisher isKindOfClass:[NSString class]] && channelInfo.publisher.length > 0) {
        self.publisherLabel.text = channelInfo.publisher;
    }
    
    NSInteger likeCount = [self.channelInfo.likes integerValue];
    if (likeCount >= 100000) {
        self.likeCountLabel.text = [NSString stringWithFormat:@"%.1fW", likeCount/10000.0];
    } else {
        self.likeCountLabel.text = [NSString stringWithFormat:@"%zd", MAX(likeCount, 0)];
    }
}

- (void)setStatus:(PLVLCLiveStatus)status {
    _status = status;
    
    UIColor *statusLabelColor = kLightGrayColor;
    if (status == PLVLCLiveStatusPlayback) {
        self.statusLabel.frame = CGRectMake(self.bounds.size.width - 50 - 16, 15, 50, 24);
        self.statusLabel.text = @"回放中";
        statusLabelColor = [UIColor colorWithRed:0x78/255.0 green:0xa7/255.0 blue:0xed/255.0 alpha:1];;
    } else if (status == PLVLCLiveStatusLiving) {
        self.statusLabel.frame = CGRectMake(self.bounds.size.width - 50 - 16, 15, 50, 24);
        self.statusLabel.text = @"进行中";
        statusLabelColor = [UIColor colorWithRed:0xe9/255.0 green:0x60/255.0 blue:0x64/255.0 alpha:1];
    } else if (status == PLVLCLiveStatusWaiting) {
        self.statusLabel.frame = CGRectMake(self.bounds.size.width - 50 - 16, 15, 50, 24);
        self.statusLabel.text = @"等待中";
        statusLabelColor = [UIColor colorWithRed:0x78/255.0 green:0xa7/255.0 blue:0xed/255.0 alpha:1];
    } else {
        self.statusLabel.frame = CGRectMake(self.bounds.size.width - 64 - 16, 15, 64, 24);
        self.statusLabel.text = @"暂无直播";
        statusLabelColor = kLightGrayColor;
    }
    self.statusLabel.textColor = statusLabelColor;
    self.statusLabel.layer.borderColor = statusLabelColor.CGColor;
}

#pragma mark - Private Method

- (PLVLCLiveStatus)liveStatusWithString:(NSString *)statusString {
    if (!statusString || ![statusString isKindOfClass:[NSString class]] || statusString.length == 0) {
        return PLVLCLiveStatusNone;
    }
    
    if ([statusString isEqualToString:@"live"]) {
        return PLVLCLiveStatusLiving;
    } else if ([statusString isEqualToString:@"waiting"]) {
        return PLVLCLiveStatusWaiting;
    } else {
        return PLVLCLiveStatusNone;
    }
}

@end
