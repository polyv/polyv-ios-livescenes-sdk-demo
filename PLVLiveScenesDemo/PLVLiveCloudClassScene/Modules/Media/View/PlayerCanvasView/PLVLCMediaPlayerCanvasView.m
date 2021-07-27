//
//  PLVLCMediaPlayerCanvasView.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/9/24.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCMediaPlayerCanvasView.h"

#import "PLVLCUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCMediaPlayerCanvasView ()

#pragma mark 状态
@property (nonatomic, assign) PLVLCMediaPlayerCanvasViewType type; // 视图类型
@property (nonatomic, assign, readonly) BOOL isMiniScreen; // 是否处于小屏中 (若“父视图宽度”小于“屏幕宽度”的一半，则认定为“小屏”；比如悬浮小窗)
@property (nonatomic, assign) PLVChannelLiveStreamState externalCurrentStreamState; // 当前外部的播放器直播流状态

#pragma mark UI
/// view hierarchy
///
/// 视频模式 时:
/// (PLVLCMediaPlayerCanvasView) self
/// ├── (UIImageView) placeholderImageView (lowest)
/// ├── (UILabel) tipsLabel
/// └── (UIView) playerSuperview (top)
///
/// 音频模式 时:
/// (PLVLCMediaPlayerCanvasView) self
/// ├── (UIImageView) placeholderImageView (lowest)
/// ├── (UIButton) playCanvasButton
/// └── (UIView) playerSuperview (top)
@property (nonatomic, strong) UIImageView * placeholderImageView; // 背景视图 (负责展示 占位图)
@property (nonatomic, strong) UILabel * tipsLabel;      // 提示文本框
@property (nonatomic, strong) UIImageView * restImageView; // 休息一会视图
@property (nonatomic, strong) UIView * playerSuperview; // 播放器父视图 (负责承载 播放器画面；决定了 播放器画面 所处在的图层层级)
@property (nonatomic, strong) UIButton * playCanvasButton; // 播放画面按钮

@end

@implementation PLVLCMediaPlayerCanvasView

#pragma mark - [ Life Period ]
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
        _externalCurrentStreamState = PLVChannelLiveStreamState_Unknown;
    }
    return self;
}

- (void)layoutSubviews{
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    
    // 屏幕适配值
    CGSize defaultImgSize = CGSizeMake(180.0f, 142.0f);
    CGSize defaultBgSize = CGSizeMake(375.0f, 211.0f);
    if (fullScreen) {
        defaultImgSize = CGSizeMake(280.0f, 222.0f);
        defaultBgSize = CGSizeMake(736.0f,414.0f);
    }
//    CGFloat scale = defaultImgSize.height / defaultBgSize.height;
    
    CGFloat placeholderImageViewHeight = viewHeight * (defaultImgSize.height / defaultBgSize.height);
    CGFloat placeholderImageViewWidth = placeholderImageViewHeight * (defaultImgSize.width / defaultImgSize.height);
    CGFloat placeholderImageViewBottomPadding = viewHeight * (16.0 / defaultBgSize.height);
    self.placeholderImageView.frame = CGRectMake((viewWidth - placeholderImageViewWidth) / 2.0,
                                                 (viewHeight - placeholderImageViewBottomPadding - placeholderImageViewHeight) / 2.0,
                                                 placeholderImageViewWidth,
                                                 placeholderImageViewHeight);
    
    CGFloat tipsLabelWidth = 150;
    CGFloat tipsLabelHeight = 17.0;
    self.tipsLabel.frame = CGRectMake((viewWidth - tipsLabelWidth) / 2.0,
                                      CGRectGetMaxY(self.placeholderImageView.frame) - 16 - tipsLabelHeight,
                                      tipsLabelWidth,
                                      tipsLabelHeight);
    
    self.restImageView.frame = self.bounds;
    
    CGFloat playCanvasButtonWidth = 96.0;
    CGFloat playCanvasButtonHeight = 30.0;
    CGFloat playCanvasButtonY = CGRectGetMaxY(self.placeholderImageView.frame) - 16 - playCanvasButtonHeight;
    if (! fullScreen) {
        playCanvasButtonY += 16;
    }
    
    self.playCanvasButton.frame = CGRectMake(CGRectGetMidX(self.placeholderImageView.frame) - playCanvasButtonWidth / 2.0, playCanvasButtonY, playCanvasButtonWidth, playCanvasButtonHeight);
    
    [self switchTypeTo:self.type];
    
    self.playerSuperview.frame = self.bounds;
    //[self refreshplayerSuperviewFrame];
}


#pragma mark - [ Public Methods ]
- (void)setVideoSize:(CGSize)videoSize{
    if (!CGSizeEqualToSize(videoSize, CGSizeZero)) {
        if (!CGSizeEqualToSize(_videoSize, videoSize)) {
            _videoSize = videoSize;
            [self refreshplayerSuperviewFrame];
        }else{
            NSLog(@"PLVLCMediaPlayerCanvasView - setVideoSize failed, videoSize is same %@",NSStringFromCGSize(videoSize));
        }
    }else{
        NSLog(@"PLVLCMediaPlayerCanvasView - setVideoSize failed, videoSize illegal %@",NSStringFromCGSize(videoSize));
    }
}

- (void)switchTypeTo:(PLVLCMediaPlayerCanvasViewType)toType{
    if (toType == PLVLCMediaPlayerCanvasViewType_Video) {
        self.placeholderImageView.image = [self getImageWithName:@"plvlc_media_video_placeholder"];
        self.playCanvasButton.hidden = YES;
        if (self.isMiniScreen) {
            // 若处于小屏中
            self.tipsLabel.hidden = YES;
        }else{
            BOOL showNoLiveTipsLabel = (self.externalCurrentStreamState == PLVChannelLiveStreamState_End);
            self.tipsLabel.hidden = !showNoLiveTipsLabel;
        }
    }else if (toType == PLVLCMediaPlayerCanvasViewType_Audio){
        self.placeholderImageView.image = [self getImageWithName:@"plvlc_media_audio_placeholder"];
        self.tipsLabel.hidden = YES;
        if (self.isMiniScreen) {
            // 若处于小屏中
            self.playCanvasButton.hidden = YES;
        }else{
            self.playCanvasButton.hidden = NO;
        }
    }
    _type = toType;
}

- (void)refreshCanvasViewWithStreamState:(PLVChannelLiveStreamState)newestStreamState{
    self.externalCurrentStreamState = newestStreamState;
    
    self.restImageView.hidden = (newestStreamState != PLVChannelLiveStreamState_Stop);

    BOOL showNoLiveTipsLabel = (newestStreamState == PLVChannelLiveStreamState_End);
    showNoLiveTipsLabel = self.isMiniScreen ? NO : showNoLiveTipsLabel;
    self.tipsLabel.hidden = !showNoLiveTipsLabel;
}


#pragma mark - [ Private Methods ]
- (void)setupUI{
    self.backgroundColor = PLV_UIColorFromRGB(@"2B3145");
    [self addSubview:self.placeholderImageView];
    [self addSubview:self.tipsLabel];
    [self addSubview:self.restImageView];
    [self addSubview:self.playCanvasButton];
    [self addSubview:self.playerSuperview];
}

- (UIImage *)getImageWithName:(NSString *)imageName{
    return [PLVLCUtils imageForMediaResource:imageName];
}

- (void)refreshplayerSuperviewFrame{
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    
    CGFloat videoScale;
    if (CGSizeEqualToSize(self.videoSize, CGSizeZero)) {
        videoScale = 0;
    }else{
        videoScale = self.videoSize.width / self.videoSize.height;
        if (isnan(videoScale)) { videoScale = 0; }
    }
    
    CGFloat playerSuperviewX;
    CGFloat playerSuperviewY;
    CGFloat playerSuperviewWidth;
    CGFloat playerSuperviewHeight;
    if (viewWidth > viewHeight) {
        /// 容器是 横向长方形
        playerSuperviewHeight = viewHeight;
        playerSuperviewWidth = videoScale * playerSuperviewHeight;
        
        playerSuperviewY = 0;
        playerSuperviewX = (viewWidth - playerSuperviewWidth) / 2.0;
    }else{
        /// 容器是 正方形 或 竖向长方形
        playerSuperviewWidth = viewWidth;
        playerSuperviewHeight = videoScale / playerSuperviewWidth;
        
        playerSuperviewX = 0;
        playerSuperviewY = (viewHeight - playerSuperviewHeight) / 2.0;
    }
    CGRect playerSuperviewRect = CGRectMake(playerSuperviewX, playerSuperviewY, playerSuperviewWidth, playerSuperviewHeight);
    self.playerSuperview.frame = CGSizeEqualToSize(self.videoSize, CGSizeZero) ? CGRectZero : playerSuperviewRect;
}

#pragma mark Getter
- (UIImageView *)placeholderImageView{
    if (!_placeholderImageView) {
        _placeholderImageView = [[UIImageView alloc]init];
        _placeholderImageView.image = [self getImageWithName:@"plvlc_media_video_placeholder"];
    }
    return _placeholderImageView;
}

- (UILabel *)tipsLabel{
    if (!_tipsLabel) {
        _tipsLabel = [[UILabel alloc] init];
        _tipsLabel.text = @"当前暂无直播";
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.textColor = PLV_UIColorFromRGB(@"E4E4E4");
        _tipsLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
        _tipsLabel.hidden = YES;
    }
    return _tipsLabel;
}

- (UIImageView *)restImageView{
    if (!_restImageView) {
        _restImageView = [UIImageView new];
        _restImageView.image = [self getImageWithName:@"plvlc_media_video_rest"];
        _restImageView.hidden = YES;
        _restImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _restImageView;
}

- (UIView *)playerSuperview{
    if (!_playerSuperview) {
        _playerSuperview = [[UIView alloc] init];
        _playerSuperview.userInteractionEnabled = NO;
    }
    return _playerSuperview;
}

- (UIButton *)playCanvasButton{
    if (!_playCanvasButton) {
        _playCanvasButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playCanvasButton setTitle:@"播放画面" forState:UIControlStateNormal];
        [_playCanvasButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _playCanvasButton.titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:14];
        _playCanvasButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
        [_playCanvasButton addTarget:self action:@selector(playCanvasButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _playCanvasButton.hidden = YES;
        
        _playCanvasButton.layer.cornerRadius = 15;
        _playCanvasButton.layer.masksToBounds = YES;
        _playCanvasButton.layer.borderColor = [UIColor whiteColor].CGColor;
        _playCanvasButton.layer.borderWidth = 1.0;
    }
    return _playCanvasButton;
}

- (BOOL)isMiniScreen{
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    return viewWidth < CGRectGetWidth([UIScreen mainScreen].bounds) / 2.0;
}


#pragma mark - [ Event ]
#pragma mark Action
- (void)playCanvasButtonAction:(UIButton *)button{
    [self switchTypeTo:PLVLCMediaPlayerCanvasViewType_Video];
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCMediaPlayerCanvasViewPlayCanvasButtonClicked:)]) {
        [self.delegate plvLCMediaPlayerCanvasViewPlayCanvasButtonClicked:self];
    }
}


@end
