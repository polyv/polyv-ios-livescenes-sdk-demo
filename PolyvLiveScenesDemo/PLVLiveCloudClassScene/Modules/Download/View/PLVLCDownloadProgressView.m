//
//  PLVLCDownloadProgressView.m
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/5/25.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCDownloadProgressView.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCDownloadProgressView ()

/// UI
@property (nonatomic, strong) UILabel *progressForegroundLabel; /// 前景色进度label
@property (nonatomic, strong) UILabel *progressBackgroundLabel; /// 背景色进度label
@property (nonatomic, strong) UIView *progressView;


@end

@implementation PLVLCDownloadProgressView

#pragma mark - Life Cycle
- (instancetype)init {
    if (self = [super init]) {
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 1;
        self.layer.borderColor = [PLVColorUtil colorFromHexString:@"#3082FE"].CGColor;
        [self addSubview:self.progressBackgroundLabel];
        [self addSubview:self.progressView];
        [self.progressView addSubview:self.progressForegroundLabel];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickDownloadAction)];
        [self addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self resetUI];
}

- (void)resetUI {
    self.layer.cornerRadius = self.bounds.size.height * 0.5;
    self.progressBackgroundLabel.frame = self.bounds;
    self.progressForegroundLabel.frame = self.bounds;
    
    if (self.progressStyle == PLVLCProgressStyleDownload) {
        // 立即下载
        self.progressForegroundLabel.text = @"立即下载";
        self.progressBackgroundLabel.text = @"";
        self.progressView.frame = self.bounds;
        self.progressView.backgroundColor = [PLVColorUtil colorFromHexString:@"#3082FE"];
        self.layer.borderWidth = 0;
    }else if (self.progressStyle == PLVLCProgressStyleDownloaded) {
        // 已下载
        self.progressForegroundLabel.text = @"已下载";
        self.progressBackgroundLabel.text = @"";
        self.progressView.frame = self.bounds;
        self.progressView.backgroundColor = [PLVColorUtil colorFromHexString:@"#3082FE" alpha:0.5];
        self.layer.borderWidth = 0;
    }else if (self.progressStyle == PLVLCProgressStyleDownloadStop) {
        // 已暂停
        self.progressForegroundLabel.text = @"已暂停";
        self.progressBackgroundLabel.text = @"已暂停";
        self.progressView.frame = CGRectMake(0, 0, self.bounds.size.width * self.downloadProgress, self.bounds.size.height);
        self.progressView.backgroundColor = [PLVColorUtil colorFromHexString:@"#3082FE"];
        self.layer.borderWidth = 1;
    }else {
        // 下载中
        self.progressForegroundLabel.text = [NSString stringWithFormat:@"下载中 %.0f%%", self.downloadProgress * 100];
        self.progressBackgroundLabel.text = [NSString stringWithFormat:@"下载中 %.0f%%", self.downloadProgress * 100];
        self.progressView.frame = CGRectMake(0, 0, self.bounds.size.width * self.downloadProgress, self.bounds.size.height);
        self.progressView.backgroundColor = [PLVColorUtil colorFromHexString:@"#3082FE"];
        self.layer.borderWidth = 1;
    }
}

#pragma mark - Setter

- (void)setDownloadProgress:(CGFloat)downloadProgress {
    if (downloadProgress < 0) {
        _downloadProgress = 0;
    }else if (downloadProgress > 1) {
        _downloadProgress = 1;
    }else {
        _downloadProgress = downloadProgress;
    }
    
    [self resetUI];
}

-(void)setProgressStyle:(PLVLCProgressStyle)progressStyle {
    _progressStyle = progressStyle;
    [self resetUI];
}

#pragma mark - Action
- (void)clickDownloadAction {
    if (self.progressStyle == PLVLCProgressStyleDownload ||
        self.progressStyle == PLVLCProgressStyleDownloadStop) {
        if (self.clickDownloadButtonBlock) {
            self.clickDownloadButtonBlock();
        }
    }
}

#pragma mark - loadLazy
- (UILabel *)progressBackgroundLabel {
    if (!_progressBackgroundLabel) {
        _progressBackgroundLabel = [[UILabel alloc]init];
        _progressBackgroundLabel.textAlignment = NSTextAlignmentCenter;
        _progressBackgroundLabel.font = [UIFont fontWithName:@"PingFangSC" size:16];
        _progressBackgroundLabel.textColor = [PLVColorUtil colorFromHexString:@"#3082FE"];
    }
    return _progressBackgroundLabel;
}

- (UILabel *)progressForegroundLabel {
    if (!_progressForegroundLabel) {
        _progressForegroundLabel = [[UILabel alloc]init];
        _progressForegroundLabel.textAlignment = NSTextAlignmentCenter;
        _progressForegroundLabel.font = [UIFont fontWithName:@"PingFangSC" size:16];
        _progressForegroundLabel.textColor = [UIColor whiteColor];
    }
    return _progressForegroundLabel;
}

- (UIView *)progressView {
    if (!_progressView) {
        _progressView = [[UIView alloc]init];
        _progressView.backgroundColor = [PLVColorUtil colorFromHexString:@"#3082FE"];
        _progressView.clipsToBounds = YES;
    }
    return _progressView;
}

@end
