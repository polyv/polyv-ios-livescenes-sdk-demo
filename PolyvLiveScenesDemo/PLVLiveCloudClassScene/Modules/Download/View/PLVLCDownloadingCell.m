//
//  PLVLCDownloadingCell.m
//  PolyvLiveScenesDemo
//
//  Created by junotang on 2022/5/26.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCDownloadingCell.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVLCUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVRoomDataManager.h"

@interface PLVLCDownloadingCell ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *sizeLabel;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *downloadButton;
@property (nonatomic, strong) UIView *separatorView;

@property (nonatomic, strong) PLVDownloadPlaybackTaskInfo * currentModel;

@end

@implementation PLVLCDownloadingCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.progressView];
        [self.contentView addSubview:self.statusLabel];
        [self.contentView addSubview:self.sizeLabel];
        [self.contentView addSubview:self.deleteButton];
        [self.contentView addSubview:self.downloadButton];
        [self.contentView addSubview:self.separatorView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self resetUI];
}

#pragma mark - [Public Method]
- (void)configModel:(PLVDownloadPlaybackTaskInfo *)model {
    self.currentModel = model;
    self.titleLabel.text = model.title;
    NSString *statusText = [self statusLabelWithDownloadState:model.state];
    self.statusLabel.text = statusText;
    self.downloadButton.selected = YES;
    self.sizeLabel.text = [NSString stringWithFormat:@"%@/%@", model.totalBytesWrittenString, model.totalBytesExpectedToWriteString];
    
    self.progressView.progress = model.progress;
    
    CGFloat cellWidth = CGRectGetWidth(self.frame);
    CGFloat titLabelWidth = [self.sizeLabel.text boundingRectWithSize:CGSizeMake(MAXFLOAT, 20) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12]} context:nil].size.width;
    self.sizeLabel.frame = CGRectMake(cellWidth - 112 - titLabelWidth, CGRectGetMaxY(self.progressView.frame) + 8, titLabelWidth, 20);
    
    [self resetDownloadButtonStatusWithDownloadState:model.state];
    
    __weak typeof(self) weakSelf = self;
    self.currentModel.downloadStateChangeBlock = ^(PLVDownloadTaskInfo * _Nullable taskInfo, PLVDownloadState state) {
        if (weakSelf && [weakSelf.currentModel.taskInfoId isEqualToString:taskInfo.taskInfoId]) {
            NSString *statusText = [weakSelf statusLabelWithDownloadState:taskInfo.state];
            weakSelf.statusLabel.text = statusText;
            [weakSelf resetDownloadButtonStatusWithDownloadState:taskInfo.state];
        }
    };
    
    self.currentModel.downloadProgressChangeBlock = ^(PLVDownloadTaskInfo * _Nullable taskInfo, unsigned long long receivedSize, unsigned long long expectedSize, float receivedPercent, float speedValue) {
        if (weakSelf && [weakSelf.currentModel.taskInfoId isEqualToString:taskInfo.taskInfoId]) {
            weakSelf.progressView.progress = taskInfo.progress;
            
            weakSelf.sizeLabel.text = [NSString stringWithFormat:@"%@/%@", taskInfo.totalBytesWrittenString, ((PLVDownloadPlaybackTaskInfo *)taskInfo).totalBytesExpectedToWriteString];
            CGFloat cellWidth = CGRectGetWidth(weakSelf.frame);
            CGFloat titLabelWidth = [weakSelf.sizeLabel.text boundingRectWithSize:CGSizeMake(MAXFLOAT, 20) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12]} context:nil].size.width;
            weakSelf.sizeLabel.frame = CGRectMake(cellWidth - 112 - titLabelWidth, CGRectGetMaxY(weakSelf.progressView.frame) + 8, titLabelWidth, 20);
        }
    };
    
    /*
    // 加密视频 外部传递token（异步方式，避免阻塞线程）
    self.currentModel.downloadGetTokenBlock = ^(void(^completion)(NSString * _Nullable token)){
        // 异步获取token，不阻塞当前线程
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *vid = [PLVRoomDataManager sharedManager].roomData.vid;
            NSString *viewerId = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerId;
            // 同步获取token（在子线程执行，不影响UI）
            [PLVTestPlaybackVodAPI getVideoToken:vid viewerId:viewerId completion:^(NSString * _Nonnull videoToken, NSError * _Nonnull error) {
                // 获取完成后回调
                if (completion) {
                    completion(videoToken);
                }
            }];
        });
    };*/
    
    
    [self resetUI];
}

+ (CGFloat)cellHeightWithModel:(NSString *)model cellWidth:(CGFloat)cellWidth {
    CGFloat titLabelHeight = [model boundingRectWithSize:CGSizeMake(cellWidth - 128, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:16]} context:nil].size.height;
    
    return titLabelHeight + 71;
}

#pragma mark - [ Private Method ]

- (void)resetUI {
    CGFloat padding = 16;
    CGFloat cellWidth = CGRectGetWidth(self.frame);
    
    self.titleLabel.frame = CGRectMake(padding, padding, cellWidth - padding - 112, 20);
    CGFloat titleHeight = [self.titleLabel sizeThatFits:CGSizeMake(self.titleLabel.frame.size.width,MAXFLOAT)].height;
    self.titleLabel.frame = CGRectMake(padding, padding, self.titleLabel.frame.size.width, titleHeight);
    
    CGFloat cellHeight = titleHeight + 71;
    
    self.progressView.frame = CGRectMake(padding, CGRectGetMaxY(self.titleLabel.frame) + 8, CGRectGetWidth(self.titleLabel.frame), 3);
    self.statusLabel.frame = CGRectMake(padding, CGRectGetMaxY(self.progressView.frame) + 8, 60, 20);
    
    CGFloat titLabelWidth = [self.sizeLabel.text boundingRectWithSize:CGSizeMake(MAXFLOAT, 20) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12]} context:nil].size.width;
    self.sizeLabel.frame = CGRectMake(cellWidth - 112 - titLabelWidth, CGRectGetMaxY(self.progressView.frame) + 8, titLabelWidth, 20);
    
    
    self.downloadButton.frame = CGRectMake(cellWidth - padding - 32, (cellHeight - 32) * 0.5, 32, 32);
    self.deleteButton.frame = CGRectMake(self.downloadButton.frame.origin.x - padding - 32, self.downloadButton.frame.origin.y, 32, 32);
    
    self.separatorView.frame = CGRectMake(0, cellHeight - 1, cellWidth, 1);
}

- (NSString *)statusLabelWithDownloadState:(PLVDownloadState)state {
    NSString *content = @"";
    if (state == PLVDownloadStateDownloading ||
        state == PLVDownloadStateUnzipping ||
        state == PLVDownloadStateUnzipped) {
        content = PLVLocalizedString(@"下载中");
    }
    else if (state == PLVDownloadStateDefault ||
             state == PLVDownloadStatePreparing ||
             state == PLVDownloadStatePrepared ||
             state == PLVDownloadStateWaiting) {
        content = PLVLocalizedString(@"等待中");
    }else if (state == PLVDownloadStateStopped) {
        content = PLVLocalizedString(@"已暂停");
    }else if (state == PLVDownloadStateFailed) {
        content = PLVLocalizedString(@"下载失败");
    }
    return content;
}

- (void)resetDownloadButtonStatusWithDownloadState:(PLVDownloadState)state {
    if (state == PLVDownloadStateDownloading ||
        state == PLVDownloadStateUnzipping ||
        state == PLVDownloadStateUnzipped) {
        [self.downloadButton setSelected:NO];
    }
    else if (state == PLVDownloadStatePreparing ||
             state == PLVDownloadStatePrepared ||
             state == PLVDownloadStateWaiting) {
        [self.downloadButton setSelected:NO];
    }else if (state == PLVDownloadStateDefault ||
              state == PLVDownloadStateStopped ||
              state == PLVDownloadStateFailed) {
        [self.downloadButton setSelected:YES];
    }
}

#pragma mark - [ Action ]

- (void)clickDeleteAction {
    if (self.clickButtonBlock) {
        self.clickButtonBlock(0);
    }
}

- (void)clickDownloadOrPauseAction {
    if (self.clickButtonBlock) {
        self.clickButtonBlock(self.downloadButton.isSelected ? 1 : 2);
        [self.downloadButton setSelected:!self.downloadButton.isSelected];
    }
}

#pragma mark - [ Loadlazy ]
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]init];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:16];
        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}

- (UILabel *)sizeLabel {
    if (!_sizeLabel) {
        _sizeLabel = [[UILabel alloc]init];
        _sizeLabel.textColor = [PLVColorUtil colorFromHexString:@"#ADADC0"];
        _sizeLabel.font = [UIFont systemFontOfSize:12];
    }
    return _sizeLabel;
}

- (UILabel *)statusLabel {
    if (!_statusLabel) {
        _statusLabel = [[UILabel alloc]init];
        _statusLabel.textColor = [PLVColorUtil colorFromHexString:@"#ADADC0"];
        _statusLabel.font = [UIFont systemFontOfSize:12];
    }
    return _statusLabel;
}

- (UIProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.progressTintColor = [PLVColorUtil colorFromHexString:@"#3082FE"];
        _progressView.trackTintColor = [PLVColorUtil colorFromHexString:@"#3E3E4E"];
    }
    return _progressView;
}

- (UIButton *)deleteButton {
    if (!_deleteButton) {
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _deleteButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#D8D8D8" alpha:0.1];
        [_deleteButton setImage:[PLVLCUtils imageForMediaResource:@"plvlc_media_delete_btn"] forState:0];
        _deleteButton.layer.cornerRadius = 16;
        _deleteButton.layer.masksToBounds = YES;
        [_deleteButton addTarget:self action:@selector(clickDeleteAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteButton;
}

- (UIButton *)downloadButton {
    if (!_downloadButton) {
        _downloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _downloadButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#D8D8D8" alpha:0.1];
        [_downloadButton setImage:[PLVLCUtils imageForMediaResource:@"plvlc_media_download_pause_btn"] forState:0];
        [_downloadButton setImage:[PLVLCUtils imageForMediaResource:@"plvlc_media_download_btn"] forState:UIControlStateSelected];
        _downloadButton.layer.cornerRadius = 16;
        _downloadButton.layer.masksToBounds = YES;
        [_downloadButton addTarget:self action:@selector(clickDownloadOrPauseAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _downloadButton;
}

- (UIView *)separatorView {
    if (!_separatorView) {
        _separatorView = [[UIView alloc]init];
        _separatorView.backgroundColor = [UIColor blackColor];
    }
    return _separatorView;
}

@end
