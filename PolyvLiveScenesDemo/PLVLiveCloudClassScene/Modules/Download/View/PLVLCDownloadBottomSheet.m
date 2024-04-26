//
//  PLVLCDownloadBottomSheet.m
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/5/25.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCDownloadBottomSheet.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVLCUtils.h"
#import "PLVLCDownloadProgressView.h"
#import "PLVRoomDataManager.h"
#import "PLVLCDownloadViewModel.h"
#import "PLVMultiLanguageManager.h"

@interface PLVLCDownloadBottomSheet ()

/// UI
@property (nonatomic, strong) UILabel *sheetTitleLabel; // 弹层顶部标题
@property (nonatomic, strong) UIView *splitLine; // 标题底部分割线
@property (nonatomic, strong) UIButton *closeButton;    //关闭按钮
@property (nonatomic, strong) UILabel *videoTitleLabel; // 视频标题
@property (nonatomic, strong) UILabel *videoSizeLabel; // 视频大小
@property (nonatomic, strong) UIButton *downloadListButton;    //下载列表按钮
@property (nonatomic, strong) PLVLCDownloadProgressView *progressView;

/// 数据
@property (nonatomic, strong) PLVPlaybackVideoInfoModel *videoModel;

@end

@implementation PLVLCDownloadBottomSheet

#pragma mark - [ Life Cycle ]
- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight {
    self = [super initWithSheetHeight:sheetHeight];
    if (self) {
        [self.contentView addSubview:self.sheetTitleLabel];
        [self.contentView addSubview:self.closeButton];
        [self.contentView addSubview:self.splitLine];
        [self.contentView addSubview:self.videoTitleLabel];
        [self.contentView addSubview:self.videoSizeLabel];
        [self.contentView addSubview:self.downloadListButton];
        [self.contentView addSubview:self.progressView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self resetUI];
}

- (void)resetUI {
    self.sheetTitleLabel.frame = CGRectMake(44, 0, self.contentView.bounds.size.width - 88, 48);
    self.closeButton.frame = CGRectMake(self.contentView.bounds.size.width - 28 - 16, 10, 28, 28);
    self.splitLine.frame = CGRectMake(0, 48, self.contentView.bounds.size.width, 1);
    self.videoTitleLabel.frame = CGRectMake(24, CGRectGetMaxY(self.splitLine.frame) + 32, self.contentView.bounds.size.width - 48, 0);
    CGFloat titleHeight = [self.videoTitleLabel sizeThatFits:CGSizeMake(self.videoTitleLabel.frame.size.width,MAXFLOAT)].height;
    self.videoTitleLabel.frame = CGRectMake(self.videoTitleLabel.frame.origin.x, self.videoTitleLabel.frame.origin.y, self.videoTitleLabel.frame.size.width, titleHeight);
    self.videoSizeLabel.frame = CGRectMake(self.videoTitleLabel.frame.origin.x, CGRectGetMaxY(self.videoTitleLabel.frame) + 12, self.contentView.bounds.size.width - 48, 20);
    self.downloadListButton.frame = CGRectMake(self.videoTitleLabel.frame.origin.x, self.contentView.bounds.size.height - 62 , self.contentView.bounds.size.width - 48, 20);
    self.progressView.frame = CGRectMake(self.videoTitleLabel.frame.origin.x, self.downloadListButton.frame.origin.y - 20 - 48, self.contentView.bounds.size.width - 48, 48);
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.contentView.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(8, 8)].CGPath;
    self.contentView.layer.mask = shapeLayer;
}

- (void)updateProgressView {
    PLVDownloadPlaybackTaskInfo *taskInfo = [[PLVLCDownloadViewModel sharedViewModel] checkAndGetPlaybackTaskInfoWithFileId:self.videoModel.fileId];
    
    if (taskInfo) {
        if (taskInfo.state == PLVDownloadStateSuccess) {
            // 已下载
            self.progressView.progressStyle = PLVLCProgressStyleDownloaded;
        }
        else if (taskInfo.state == PLVDownloadStateFailed ||
                 taskInfo.state == PLVDownloadStateDefault) {
            // 立即下载
            self.progressView.progressStyle = PLVLCProgressStyleDownload;
        }
        else {
            if (taskInfo.state == PLVDownloadStateStopped) {
                // 已暂停
                self.progressView.progressStyle = PLVLCProgressStyleDownloadStop;
            }else {
                // 下载中
                self.progressView.progressStyle = PLVLCProgressStyleDownloading;
            }
            
            self.progressView.downloadProgress = taskInfo.progress;
            
            __weak typeof(self) weakSelf = self;
            [taskInfo setDownloadProgressChangeBlock:^(PLVDownloadTaskInfo * _Nullable taskInfo, unsigned long long receivedSize, unsigned long long expectedSize, float progress, float speedValue) {
                weakSelf.progressView.downloadProgress = progress;
            }];
            
            [taskInfo setDownloadStateChangeBlock:^(PLVDownloadTaskInfo * _Nullable taskInfo, PLVDownloadState state) {
                [weakSelf updateProgressView];
            }];
        }
    } else {
        // 立即下载
        self.progressView.progressStyle = PLVLCProgressStyleDownload;
    }
}

#pragma mark - [ Public Method ]
- (void)updatePlaybackInfoWithData:(PLVRoomData *)roomData {
    self.videoModel = roomData.playbackVideoInfo;
    
    self.videoTitleLabel.text = self.videoModel.title;
    if ([self.videoModel isKindOfClass:[PLVPlaybackLocalVideoInfoModel class]]) {
        // 来源于本地数据
        PLVPlaybackLocalVideoInfoModel *localModel = (PLVPlaybackLocalVideoInfoModel *)self.videoModel;
        NSString *sizeString = [NSByteCountFormatter stringFromByteCount:localModel.totalBytesExpectedToWrite countStyle:NSByteCountFormatterCountStyleFile];
        self.videoSizeLabel.text = [NSString stringWithFormat:PLVLocalizedString(@"视频大小：%@"), sizeString];
    }else {
        // 来源于在线数据
        if (![self.videoModel.liveType isEqualToString:@"ppt"]) {
            // 纯视频
            NSString *sizeString = [NSByteCountFormatter stringFromByteCount:self.videoModel.videoSize countStyle:NSByteCountFormatterCountStyleFile];
            self.videoSizeLabel.text = [NSString stringWithFormat:PLVLocalizedString(@"视频大小：%@"), sizeString];
        }else {
            // 带ppt的三分屏视频
            NSInteger totalSize = self.videoModel.zipSize + self.videoModel.videoSize;
            NSString *sizeString = [NSByteCountFormatter stringFromByteCount:totalSize countStyle:NSByteCountFormatterCountStyleFile];
            self.videoSizeLabel.text = [NSString stringWithFormat:PLVLocalizedString(@"视频大小：%@"), sizeString];
        }
    }
    
    [self updateProgressView];
    [self resetUI];
}

#pragma mark - Super
- (void)showInView:(UIView *)parentView {
    [super showInView:parentView];
    [self updateProgressView];
    [self resetUI];
}

#pragma mark - Action
- (void)clickDownloadListButtonAction {
    [self dismiss];
    if (self.clickDownloadListBlock) {
        self.clickDownloadListBlock();
    }
}

- (void)clickDownloadVideoButton {
    if (self.videoModel.playbackCacheEnabled) {
        PLVDownloadPlaybackTaskInfo *taskInfo = [[PLVLCDownloadViewModel sharedViewModel] checkAndGetPlaybackTaskInfoWithFileId:self.videoModel.fileId];
        if (taskInfo) {
            // 已经存在下载任务，直接开始下载
            [[PLVLCDownloadViewModel sharedViewModel] startDownloadWith:taskInfo];
            [self updateProgressView];
            [self resetUI];
        }
        else {
            // 不存在下载任务，添加到下载队列然后开始下载
            [[PLVLCDownloadViewModel sharedViewModel] enqueueDownloadQueueWithPlaybackPlayerModel:self.videoModel completion:^(NSError * _Nonnull error) {
                if (!error) {
                    [self updateProgressView];
                    [self resetUI];
                }
            }];
        }
    }else {
        [PLVFdUtil showHUDWithTitle:PLVLocalizedString(@"该账号暂不支持下载视频") detail:PLVLocalizedString(@"请联系管理员开启") view:self];
    }
}

#pragma mark - loadLazy
- (UILabel *)sheetTitleLabel {
    if (!_sheetTitleLabel) {
        _sheetTitleLabel = [[UILabel alloc] init];
        _sheetTitleLabel.text = PLVLocalizedString(@"下载视频");
        _sheetTitleLabel.textAlignment = NSTextAlignmentCenter;
        _sheetTitleLabel.font = [UIFont fontWithName:@"PingFangSC" size:16];
        _sheetTitleLabel.textColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1/1.0];
    }
    return _sheetTitleLabel;
}

- (UIView *)splitLine {
    if (!_splitLine) {
        _splitLine = [[UIView alloc] init];
        _splitLine.backgroundColor = [PLVColorUtil colorFromHexString:@"#EDEDEF"];
    }
    return _splitLine;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:[PLVLCUtils imageForMediaResource:@"plvlc_media_close_btn"] forState:0];
        _closeButton.backgroundColor = [UIColor whiteColor];
        [_closeButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UILabel *)videoTitleLabel {
    if (!_videoTitleLabel) {
        _videoTitleLabel = [[UILabel alloc]init];
        _videoTitleLabel.font = [UIFont fontWithName:@"PingFangSC" size:16];
        _videoTitleLabel.textColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1/1.0];
        _videoTitleLabel.numberOfLines = 2;
    }
    return _videoTitleLabel;
}

- (UILabel *)videoSizeLabel {
    if (!_videoSizeLabel) {
        _videoSizeLabel = [[UILabel alloc]init];
        _videoSizeLabel.font = [UIFont fontWithName:@"PingFangSC" size:12];
        _videoSizeLabel.textColor = [UIColor colorWithRed:170/255.0 green:170/255.0 blue:170/255.0 alpha:1/1.0];
    }
    return _videoSizeLabel;
}

- (UIButton *)downloadListButton {
    if (!_downloadListButton) {
        _downloadListButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_downloadListButton setTitle:PLVLocalizedString(@"查看下载列表 >") forState:0];
        [_downloadListButton setTitleColor:[PLVColorUtil colorFromHexString:@"#3082FE"] forState:0];
        _downloadListButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC" size:14];
        [_downloadListButton addTarget:self action:@selector(clickDownloadListButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _downloadListButton;
}

- (PLVLCDownloadProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[PLVLCDownloadProgressView alloc]init];
        __weak typeof(self) weakSelf = self;
        [_progressView setClickDownloadButtonBlock:^{
            [weakSelf clickDownloadVideoButton];
        }];
    }
    return _progressView;
}


@end
