//
//  PLVStickerAudioSet.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/8/26.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVStickerAudioSet.h"
// 工具
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVStickerAudioSet ()

#pragma mark UI
@property (nonatomic, strong) UILabel *titleLabel; // 标题
@property (nonatomic, strong) UILabel *videoVolumeLabel; // 视频声音标签
@property (nonatomic, strong) UISlider *videoVolumeSlider; // 视频声音滑块
@property (nonatomic, strong) UILabel *videoVolumePercentLabel; // 视频声音百分比标签
@property (nonatomic, strong) UILabel *microphoneVolumeLabel; // 麦克风声音标签
@property (nonatomic, strong) UISlider *microphoneVolumeSlider; // 麦克风声音滑块
@property (nonatomic, strong) UILabel *microphoneVolumePercentLabel; // 麦克风声音百分比标签
@property (nonatomic, strong) UILabel *volumeTipLabel; // 音量提示标签

@end

@implementation PLVStickerAudioSet

#pragma mark - Life Cycle

- (instancetype)init {
    // 设置弹出框高度为 220
    self = [super initWithSheetHeight:220];
    if (self) {
        [self setupUI];
        [self setupInitialValues];
    }
    return self;
}

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth {
    self = [super initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
    if (self) {
        [self setupUI];
        [self setupInitialValues];
    }
    return self;
}

#pragma mark - UI Setup

- (void)setupUI {
    // 添加手势识别器防止触摸事件透传
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentViewTapped:)];
    tapGesture.cancelsTouchesInView = YES;
    [self.contentView addGestureRecognizer:tapGesture];
    
    [self setupTitleLabel];
    [self setupVideoVolumeControls];
    [self setupMicrophoneVolumeControls];
    [self setupVolumeTipLabel];
}

- (void)setupTitleLabel {
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = PLVLocalizedString(@"声音");
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.titleLabel];
}

- (void)setupVideoVolumeControls {
    // 视频声音标签
    self.videoVolumeLabel = [[UILabel alloc] init];
    self.videoVolumeLabel.text = PLVLocalizedString(@"推流音量");
    self.videoVolumeLabel.textColor = [UIColor whiteColor];
    self.videoVolumeLabel.font = [UIFont systemFontOfSize:14];
    [self.contentView addSubview:self.videoVolumeLabel];
    
    // 视频声音滑块
    self.videoVolumeSlider = [[UISlider alloc] init];
    self.videoVolumeSlider.minimumValue = 0.0;
    self.videoVolumeSlider.maximumValue = 1.0;
    self.videoVolumeSlider.value = 1.0; // 默认100%
    self.videoVolumeSlider.minimumTrackTintColor = [UIColor whiteColor];
    self.videoVolumeSlider.maximumTrackTintColor = [UIColor colorWithWhite:1.0 alpha:0.3];
    self.videoVolumeSlider.thumbTintColor = [UIColor whiteColor];
    [self.videoVolumeSlider addTarget:self action:@selector(videoVolumeSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.videoVolumeSlider];
    
    // 视频声音百分比标签
    self.videoVolumePercentLabel = [[UILabel alloc] init];
    self.videoVolumePercentLabel.text = @"100%";
    self.videoVolumePercentLabel.textColor = [UIColor whiteColor];
    self.videoVolumePercentLabel.font = [UIFont systemFontOfSize:14];
    self.videoVolumePercentLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:self.videoVolumePercentLabel];
}

- (void)setupMicrophoneVolumeControls {
    // 麦克风声音标签
    self.microphoneVolumeLabel = [[UILabel alloc] init];
    self.microphoneVolumeLabel.text = PLVLocalizedString(@"本地音量");
    self.microphoneVolumeLabel.textColor = [UIColor whiteColor];
    self.microphoneVolumeLabel.font = [UIFont systemFontOfSize:14];
    [self.contentView addSubview:self.microphoneVolumeLabel];
    
    // 麦克风声音滑块
    self.microphoneVolumeSlider = [[UISlider alloc] init];
    self.microphoneVolumeSlider.minimumValue = 0.0;
    self.microphoneVolumeSlider.maximumValue = 1.0;
    self.microphoneVolumeSlider.value = 0.0; // 默认0%
    self.microphoneVolumeSlider.minimumTrackTintColor = [UIColor whiteColor];
    self.microphoneVolumeSlider.maximumTrackTintColor = [UIColor colorWithWhite:1.0 alpha:0.3];
    self.microphoneVolumeSlider.thumbTintColor = [UIColor whiteColor];
    [self.microphoneVolumeSlider addTarget:self action:@selector(microphoneVolumeSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.microphoneVolumeSlider];
    
    // 麦克风声音百分比标签
    self.microphoneVolumePercentLabel = [[UILabel alloc] init];
    self.microphoneVolumePercentLabel.text = @"0%";
    self.microphoneVolumePercentLabel.textColor = [UIColor whiteColor];
    self.microphoneVolumePercentLabel.font = [UIFont systemFontOfSize:14];
    self.microphoneVolumePercentLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:self.microphoneVolumePercentLabel];
}

- (void)setupVolumeTipLabel {
    // 音量提示标签
    self.volumeTipLabel = [[UILabel alloc] init];
    self.volumeTipLabel.text = PLVLocalizedString(@"本地音量默认为 0，调大可能引发直播回音，建议戴耳机监听。");
    self.volumeTipLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.6];
    self.volumeTipLabel.font = [UIFont systemFontOfSize:12];
    self.volumeTipLabel.numberOfLines = 0;
    [self.contentView addSubview:self.volumeTipLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat contentWidth = self.contentView.bounds.size.width;
    
    // 布局参数
    CGFloat leftMargin = 40;
    CGFloat rightMargin = 40;
    CGFloat titleTopMargin = 20;
    CGFloat controlSpacing = 24;
    CGFloat controlHeight = 20;
    CGFloat percentLabelWidth = 40;
    CGFloat sliderSpacing = 16;
    
    // 标题布局
    self.titleLabel.frame = CGRectMake(0, titleTopMargin, contentWidth, 20);
    
    // 视频声音控制第一行
    CGFloat videoControlY = titleTopMargin + 20 + controlSpacing;
    
    // 视频声音标签
    [self.videoVolumeLabel sizeToFit];
    CGFloat videoLabelWidth = self.videoVolumeLabel.bounds.size.width;
    self.videoVolumeLabel.frame = CGRectMake(leftMargin, videoControlY, videoLabelWidth, controlHeight);
    
    // 视频声音百分比标签
    self.videoVolumePercentLabel.frame = CGRectMake(contentWidth - rightMargin - percentLabelWidth, videoControlY, percentLabelWidth, controlHeight);
    
    // 视频声音滑块
    CGFloat videoSliderX = leftMargin + videoLabelWidth + sliderSpacing;
    CGFloat videoSliderWidth = contentWidth - rightMargin - percentLabelWidth - sliderSpacing - videoSliderX;
    self.videoVolumeSlider.frame = CGRectMake(videoSliderX, videoControlY, videoSliderWidth, controlHeight);
    
    // 麦克风声音控制第二行
    CGFloat micControlY = videoControlY + controlHeight + controlSpacing;
    
    // 麦克风声音标签
    [self.microphoneVolumeLabel sizeToFit];
    CGFloat micLabelWidth = self.microphoneVolumeLabel.bounds.size.width;
    self.microphoneVolumeLabel.frame = CGRectMake(leftMargin, micControlY, micLabelWidth, controlHeight);
    
    // 麦克风声音百分比标签
    self.microphoneVolumePercentLabel.frame = CGRectMake(contentWidth - rightMargin - percentLabelWidth, micControlY, percentLabelWidth, controlHeight);
    
    // 麦克风声音滑块
    CGFloat micSliderX = leftMargin + micLabelWidth + sliderSpacing;
    CGFloat micSliderWidth = contentWidth - rightMargin - percentLabelWidth - sliderSpacing - micSliderX;
    self.microphoneVolumeSlider.frame = CGRectMake(micSliderX, micControlY, micSliderWidth, controlHeight);
    
    // 音量提示标签
    CGFloat tipLabelY = micControlY + controlHeight + 12;
    CGFloat tipLabelWidth = contentWidth - leftMargin - rightMargin;
    CGSize tipLabelSize = [self.volumeTipLabel sizeThatFits:CGSizeMake(tipLabelWidth, CGFLOAT_MAX)];
    self.volumeTipLabel.frame = CGRectMake(leftMargin, tipLabelY, tipLabelWidth, tipLabelSize.height);
}

- (void)setupInitialValues {
    _videoVolume = 1.0;
    _microphoneVolume = 0.0;
}

#pragma mark - Gesture Actions

- (void)contentViewTapped:(UITapGestureRecognizer *)gesture {
    // 拦截触摸事件，防止透传到其他 UIView
    // 空实现即可，手势识别器会消费掉事件
}

#pragma mark - Slider Actions

- (void)videoVolumeSliderChanged:(UISlider *)slider {
    self.videoVolume = slider.value;
    self.videoVolumePercentLabel.text = [NSString stringWithFormat:@"%.0f%%", self.videoVolume * 100];
    
    if ([self.delegate respondsToSelector:@selector(stickerAudioSet:didChangeVideoVolume:)]) {
        [self.delegate stickerAudioSet:self didChangeVideoVolume:self.videoVolume];
    }
}

- (void)microphoneVolumeSliderChanged:(UISlider *)slider {
    self.microphoneVolume = slider.value;
    self.microphoneVolumePercentLabel.text = [NSString stringWithFormat:@"%.0f%%", self.microphoneVolume * 100];
    
    if ([self.delegate respondsToSelector:@selector(stickerAudioSet:didChangeMicrophoneVolume:)]) {
        [self.delegate stickerAudioSet:self didChangeMicrophoneVolume:self.microphoneVolume];
    }
}

#pragma mark - Setter

- (void)setVideoVolume:(CGFloat)videoVolume {
    _videoVolume = MAX(0.0, MIN(1.0, videoVolume));
    self.videoVolumeSlider.value = _videoVolume;
    self.videoVolumePercentLabel.text = [NSString stringWithFormat:@"%.0f%%", _videoVolume * 100];
}

- (void)setMicrophoneVolume:(CGFloat)microphoneVolume {
    _microphoneVolume = MAX(0.0, MIN(1.0, microphoneVolume));
    self.microphoneVolumeSlider.value = _microphoneVolume;
    self.microphoneVolumePercentLabel.text = [NSString stringWithFormat:@"%.0f%%", _microphoneVolume * 100];
}

@end
