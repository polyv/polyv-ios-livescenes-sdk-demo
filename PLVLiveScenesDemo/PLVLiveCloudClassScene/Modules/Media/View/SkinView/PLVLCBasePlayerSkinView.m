//
//  PLVLCBasePlayerSkinView.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/10/8.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCBasePlayerSkinView.h"

#import <PLVLiveScenesSDK/PLVLiveDefine.h>
#import "PLVRoomDataManager.h"
#import <MediaPlayer/MPVolumeView.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

#import "PLVLCUtils.h"
#import "PLVLCMediaBrightnessView.h"

typedef NS_ENUM(NSInteger, PLVBasePlayerSkinViewPanType) {
    PLVBasePlayerSkinViewTypeAdjusVolume        = 1,//在屏幕左边，上下滑动调节声音
    PLVBasePlayerSkinViewTypeAdjusBrightness    = 2 //在屏幕右边，上下滑动调节亮度
};

@interface PLVLCBasePlayerSkinView ()<PLVProgressSliderDelegate>

@property (nonatomic, assign) PLVLCBasePlayerSkinViewType skinViewType;
@property (nonatomic, assign) CGPoint lastPoint;
@property (nonatomic, assign) PLVBasePlayerSkinViewPanType panType;
@property (nonatomic, strong) MPVolumeView *volumeView;

@end

@implementation PLVLCBasePlayerSkinView

#pragma mark - [ Life Period ]
- (void)dealloc{
    NSLog(@"%s",__FUNCTION__);
}

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero]) {
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        self.skinViewType = [PLVLCBasePlayerSkinView playerSkinTypeWithChannelType:roomData.channelType videoType:roomData.videoType];
        [self setupData];
        [self setupUI];
    }
    return self;
}

+ (PLVLCBasePlayerSkinViewType)playerSkinTypeWithChannelType:(PLVChannelType)channelType
                                                   videoType:(PLVChannelVideoType)videoType {
    PLVLCBasePlayerSkinViewType skinViewType = PLVLCBasePlayerSkinViewType_AloneLive;
    if (videoType == PLVChannelVideoType_Live) {
        if (channelType == PLVChannelTypeAlone) {
            skinViewType = PLVLCBasePlayerSkinViewType_AloneLive;
        } else if (channelType == PLVChannelTypePPT) {
            skinViewType = PLVLCBasePlayerSkinViewType_PPTLive;
        }
    } else if (videoType == PLVChannelVideoType_Playback) {
        if (channelType == PLVChannelTypeAlone) {
            skinViewType = PLVLCBasePlayerSkinViewType_AlonePlayback;
        } else if (channelType == PLVChannelTypePPT) {
            skinViewType = PLVLCBasePlayerSkinViewType_PPTPlayback;
        }
    }
    return skinViewType;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event{
    for (UIView * subview in self.subviews) {
        if (subview.hidden != YES && subview.alpha > 0 && subview.userInteractionEnabled && CGRectContainsPoint(subview.frame, point)) {
            return YES;
        }
    }
    
    BOOL otherViewHandler = NO;
    if (self.baseDelegate && [self.baseDelegate respondsToSelector:@selector(plvLCBasePlayerSkinView:askHandlerForTouchPointOnSkinView:)]) {
        otherViewHandler = [self.baseDelegate plvLCBasePlayerSkinView:self askHandlerForTouchPointOnSkinView:point];
    }
    return !otherViewHandler;
}

- (void)layoutSubviews{
    // 布局逻辑，由子类去实现(因不同子类的布局逻辑存在较大差异)
}


#pragma mark - [ Public Methods ]
- (CGFloat)getLabelTextWidth:(UILabel *)label {
    CGFloat minWidth = 38;
    CGFloat resultWidth = minWidth;
    if (label) {
        resultWidth = [label.text boundingRectWithSize:CGSizeMake(MAXFLOAT, 1)
                                               options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                            attributes:@{NSFontAttributeName:label.font}
                                               context:nil].size.width + 5;
        
        if (resultWidth < minWidth) {
            resultWidth = minWidth;
        }
    }
    
    return resultWidth;
}

- (void)switchSkinViewLiveStatusTo:(PLVLCBasePlayerSkinViewLiveStatus)skinViewLiveStatus{
    if (_skinViewLiveStatus == skinViewLiveStatus) { return; }

    _skinViewLiveStatus = skinViewLiveStatus;
        
    if (self.skinViewType < PLVLCBasePlayerSkinViewType_AlonePlayback) { // 直播场景
        if (skinViewLiveStatus == PLVLCBasePlayerSkinViewLiveStatus_None) {
            self.moreButton.hidden = YES;
            self.playButton.hidden = YES;
            self.refreshButton.hidden = YES;
            self.floatViewShowButton.hidden = YES;
        } else if (skinViewLiveStatus == PLVLCBasePlayerSkinViewLiveStatus_Living_CDN) {
            self.moreButton.hidden = NO;
            self.playButton.hidden = NO;
            self.refreshButton.hidden = NO;
            self.floatViewShowButton.hidden = NO;
        } else if (skinViewLiveStatus == PLVLCBasePlayerSkinViewLiveStatus_Living_NODelay){
            self.moreButton.hidden = YES;
            self.playButton.hidden = YES;
            self.refreshButton.hidden = YES;
            self.floatViewShowButton.hidden = NO;
            self.floatViewShowButton.selected = NO; /// 无延迟场景，默认显示‘开’
        } else if (skinViewLiveStatus == PLVLCBasePlayerSkinViewLiveStatus_InLinkMic_PartRTC) {
            self.moreButton.hidden = YES;
            self.playButton.hidden = YES;
            self.refreshButton.hidden = NO;
            self.floatViewShowButton.hidden = NO;
            self.floatViewShowButton.selected = NO;
        } else if (skinViewLiveStatus == PLVLCBasePlayerSkinViewLiveStatus_InLinkMic_PureRTC) {
            self.moreButton.hidden = YES;
            self.playButton.hidden = YES;
            self.refreshButton.hidden = YES;
            self.floatViewShowButton.hidden = NO;
            self.floatViewShowButton.selected = NO; /// 连麦中场景，默认显示‘开’
        } else {
            NSLog(@"PLVLCBasePlayerSkinView[%@] - skinViewLiveStatusSwitchTo failed, unsupported live status:%ld",NSStringFromClass(self.class),skinViewLiveStatus);
        }
    }else{
        NSLog(@"PLVLCBasePlayerSkinView[%@] - skinViewLiveStatusSwitchTo failed, skin view type illegal:%ld",NSStringFromClass(self.class),self.skinViewType);
    }
}

- (void)setTitleLabelWithText:(NSString *)titleText{
    if ([PLVFdUtil checkStringUseable:titleText]) {
        if (titleText.length > 12) {
            titleText = [NSString stringWithFormat:@"%@...", [titleText substringToIndex:12]];
        }
        self.titleLabel.text = titleText;
    }else{
        NSLog(@"PLVLCBasePlayerSkinView[%@] - setTitleLabelWithText failed, titleText:%@",NSStringFromClass(self.class),titleText);
    }
}

- (void)setPlayTimesLabelWithTimes:(NSInteger)times{
    NSString * timesString = (times > 10000) ? [NSString stringWithFormat:@"%0.1fw", times / 10000.0] : [NSString stringWithFormat:@"%ld",times];
    self.playTimesLabel.text = [NSString stringWithFormat:@"%@次播放",timesString];
    [self refreshPlayTimesLabelFrame];
}

- (void)setFloatViewButtonWithShowStatus:(BOOL)showFloatView{
    self.floatViewShowButton.selected = !showFloatView;
}

- (void)setPlayButtonWithPlaying:(BOOL)playing{
    self.playButton.selected = playing;
    if (self.playButton.selected) {
        [self.playButton setImage:[self getImageWithName:@"plvlc_media_skin_pause"] forState:UIControlStateSelected | UIControlStateHighlighted];
    }else{
        [self.playButton setImage:[self getImageWithName:@"plvlc_media_skin_play"] forState:UIControlStateHighlighted];
    }
}

- (void)setCountdownTime:(NSTimeInterval)time{
    BOOL isShowCountdownTimeView = ((NSInteger)time) > 0;
    
    self.titleLabel.alpha = isShowCountdownTimeView > 0 ? 0 : 1;
    self.playTimesLabel.alpha = isShowCountdownTimeView > 0 ? 0 : 1;
    self.countdownTimeView.alpha = isShowCountdownTimeView > 0 ? 1 : 0;
    self.countdownTimeView.time = time;
}

- (void)showFloatViewShowButtonTipsLabelAnimation:(BOOL)showTips{
    NSLog(@"PLVLCBasePlayerSkinView[%@] - showFloatViewShowButtonTipsLabelAnimation failed, the method was not overridden by subclass",NSStringFromClass(self.class));
}

- (void)synchOtherSkinViewState:(PLVLCBasePlayerSkinView *)otherSkinView{
    if (otherSkinView && otherSkinView != self && [otherSkinView isKindOfClass:PLVLCBasePlayerSkinView.class]) {
        [self switchSkinViewLiveStatusTo:otherSkinView.skinViewLiveStatus];
        self.playButton.selected = otherSkinView.playButton.selected;
        self.floatViewShowButton.selected = otherSkinView.floatViewShowButton.selected;
    }else{
        NSLog(@"PLVLCBasePlayerSkinView[%@] - synchOtherSkinViewState failed, other skin view:%@",NSStringFromClass(self.class),otherSkinView);
    }
}

- (void)setProgressWithCachedProgress:(CGFloat)cachedProgress playedProgress:(CGFloat)playedProgress durationTime:(NSTimeInterval)durationTime currentTimeString:(NSString *)currentTimeString durationString:(NSString *)durationString{
    [self.progressSlider setProgressWithCachedProgress:cachedProgress playedProgress:playedProgress];
    self.progressSlider.userInteractionEnabled = (durationTime > 0 ? YES : NO);
    if (self.currentTimeLabel.text.length !=  currentTimeString.length) {
        [self setNeedsLayout];
    }
    
    self.currentTimeLabel.text = [PLVFdUtil checkStringUseable:currentTimeString] ? currentTimeString : @"00:00";
    if (! [self.durationLabel.text isEqualToString:durationString]) {
        self.durationLabel.text = [PLVFdUtil checkStringUseable:durationString] ? durationString : @"00:00";
        [self setNeedsLayout];
    }
}

- (void)setupUI{
    // 添加 手势
    self.tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
    [self addGestureRecognizer:self.tapGR];
    
    self.panGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
    [self addGestureRecognizer:self.panGR];

    // 添加 视图
    // 注意：懒加载过程中(即Getter)已增加判断，若场景不匹配，将创建失败并返回nil
    UIView * controlsSuperview = self;
    [controlsSuperview.layer addSublayer:self.topShadowLayer];
    [controlsSuperview addSubview:self.backButton];
    [controlsSuperview addSubview:self.titleLabel];
    [controlsSuperview addSubview:self.moreButton];

    [controlsSuperview.layer addSublayer:self.bottomShadowLayer];
    [controlsSuperview addSubview:self.playButton];
    [controlsSuperview addSubview:self.fullScreenButton];
    
    if (self.skinViewType == PLVLCBasePlayerSkinViewType_PPTLive ||
        self.skinViewType == PLVLCBasePlayerSkinViewType_PPTPlayback) {
        [controlsSuperview addSubview:self.floatViewShowButtonTipsLabel];
        [controlsSuperview addSubview:self.floatViewShowButton];
    }
    
    if (self.skinViewType < PLVLCBasePlayerSkinViewType_AlonePlayback) { // 视频类型为 直播
        /// 顶部UI
        [controlsSuperview addSubview:self.playTimesLabel];
        [controlsSuperview addSubview:self.countdownTimeView];

        /// 底部UI
        [controlsSuperview addSubview:self.refreshButton];
    } else { // 视频类型为 直播回放
        /// 底部UI
        [controlsSuperview addSubview:self.currentTimeLabel];
        [controlsSuperview addSubview:self.diagonalsLabel];
        [controlsSuperview addSubview:self.durationLabel];
        [controlsSuperview addSubview:self.progressSlider];
    }
    
    [controlsSuperview bringSubviewToFront:self.backButton];
}

- (void)refreshPlayTimesLabelFrame{
    NSLog(@"PLVLCBasePlayerSkinView[%@] - refreshPlayTimesLabelFrame failed, the method was not overridden by subclass",NSStringFromClass(self.class));
}

+ (BOOL)checkView:(UIView *)otherView canBeHandlerForTouchPoint:(CGPoint)point onSkinView:(PLVLCBasePlayerSkinView *)skinView{
    BOOL otherViewCanBeHandler = NO;
    if (otherView.hidden != YES && otherView.alpha > 0 && otherView.userInteractionEnabled) {
        CGPoint convertPoint = [skinView convertPoint:point toView:otherView.superview];
        otherViewCanBeHandler = CGRectContainsPoint(otherView.frame, convertPoint);
    }
    return otherViewCanBeHandler;
}

#pragma mark Animation
- (void)controlsSwitchShowStatusWithAnimation:(BOOL)showStatus{
    if (self.skinShow == showStatus) {
        NSLog(@"PLVLCBasePlayerSkinView[%@] - controlsSwitchShowAnimationWithShow failed , state is same",NSStringFromClass(self.class));
        return;
    }
    
    self.skinShow = showStatus;
    CGFloat alpha = self.skinShow ? 1.0 : 0.0;
    __weak typeof(self) weakSelf = self;
    void (^animationBlock)(void) = ^{
        weakSelf.topShadowLayer.opacity = alpha;
        weakSelf.bottomShadowLayer.opacity = alpha;
        for (UIView * subview in weakSelf.subviews) {
            if ([subview isKindOfClass:PLVLCMediaCountdownTimeView.class]) {
                continue;
            }
            subview.alpha = alpha;
        }
    };
    [UIView animateWithDuration:0.3 animations:animationBlock];
}

#pragma mark Setter
- (void)setSkinShow:(BOOL)skinShow{
    BOOL didChanged = (_skinShow != skinShow);
    _skinShow = skinShow;
    if (didChanged) {
        if ([self.baseDelegate respondsToSelector:@selector(plvLCBasePlayerSkinView:didChangedSkinShowStatus:)]) {
            [self.baseDelegate plvLCBasePlayerSkinView:self didChangedSkinShowStatus:_skinShow];
        }
    }
}

#pragma mark Getter
- (CAGradientLayer *)topShadowLayer{
    if (!_topShadowLayer) {
        _topShadowLayer = [CAGradientLayer layer];
        _topShadowLayer.startPoint = CGPointMake(0.5, 1);
        _topShadowLayer.endPoint = CGPointMake(0.5, 0);
        _topShadowLayer.colors = @[(__bridge id)[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.0].CGColor, (__bridge id)[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.6].CGColor];
        _topShadowLayer.locations = @[@(0.0), @(1.0f)];
    }
    return _topShadowLayer;
}

- (UIButton *)backButton{
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setImage:[self getImageWithName:@"plvlc_media_skin_back"] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"房间标题";
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:14];
    }
    return _titleLabel;
}

- (UILabel *)playTimesLabel{
    if (!_playTimesLabel && self.skinViewType < PLVLCBasePlayerSkinViewType_AlonePlayback) {
        _playTimesLabel = [[UILabel alloc] init];
        _playTimesLabel.text = @"播放量";
        _playTimesLabel.textAlignment = NSTextAlignmentCenter;
        _playTimesLabel.textColor = PLV_UIColorFromRGB(@"D0D0D0");
        _playTimesLabel.font = [UIFont fontWithName:@"PingFang SC" size:10];
        _playTimesLabel.layer.cornerRadius = 9.0;
        _playTimesLabel.backgroundColor = PLV_UIColorFromRGBA(@"000000", 0.5);
        _playTimesLabel.clipsToBounds = YES;
    }
    return _playTimesLabel;
}

- (UIButton *)moreButton{
    if (!_moreButton) {
        _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_moreButton setImage:[self getImageWithName:@"plvlc_media_skin_more"] forState:UIControlStateNormal];
        [_moreButton addTarget:self action:@selector(moreButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _moreButton.hidden = (self.skinViewType < PLVLCBasePlayerSkinViewType_AlonePlayback ? YES : NO);
    }
    return _moreButton;
}

- (PLVLCMediaCountdownTimeView *)countdownTimeView {
    if (! _countdownTimeView && self.skinViewType < PLVLCBasePlayerSkinViewType_AlonePlayback) {
        _countdownTimeView = [PLVLCMediaCountdownTimeView new];
        _countdownTimeView.alpha = 0;
    }
    return _countdownTimeView;
}

- (CAGradientLayer *)bottomShadowLayer{
    if (!_bottomShadowLayer) {
        _bottomShadowLayer = [CAGradientLayer layer];
        _bottomShadowLayer.startPoint = CGPointMake(0.5, 0);
        _bottomShadowLayer.endPoint = CGPointMake(0.5, 1);
        _bottomShadowLayer.colors = @[(__bridge id)[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.0].CGColor, (__bridge id)[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.6].CGColor];
        _bottomShadowLayer.locations = @[@(0), @(1.0f)];
    }
    return _bottomShadowLayer;
}

- (UIButton *)playButton{
    if (!_playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setImage:[self getImageWithName:@"plvlc_media_skin_play"] forState:UIControlStateNormal];
        [_playButton setImage:[self getImageWithName:@"plvlc_media_skin_pause"] forState:UIControlStateSelected];
        [_playButton addTarget:self action:@selector(playButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _playButton.hidden = (self.skinViewType < PLVLCBasePlayerSkinViewType_AlonePlayback ? YES : NO);
    }
    return _playButton;
}

- (UIButton *)refreshButton{
    if (!_refreshButton && self.skinViewType < PLVLCBasePlayerSkinViewType_AlonePlayback) {
        _refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_refreshButton setImage:[self getImageWithName:@"plvlc_media_skin_refresh"] forState:UIControlStateNormal];
        [_refreshButton addTarget:self action:@selector(refreshButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _refreshButton.hidden = YES;
    }
    return _refreshButton;
}

- (UILabel *)floatViewShowButtonTipsLabel{
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (!_floatViewShowButtonTipsLabel && roomData.channelType != PLVChannelTypeAlone) {
        _floatViewShowButtonTipsLabel = [[UILabel alloc] init];
        _floatViewShowButtonTipsLabel.text = @"可从此处重新打开浮窗";
        _floatViewShowButtonTipsLabel.textAlignment = NSTextAlignmentCenter;
        _floatViewShowButtonTipsLabel.textColor = PLV_UIColorFromRGB(@"FFFFFF");
        _floatViewShowButtonTipsLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
        _floatViewShowButtonTipsLabel.layer.cornerRadius = 12.5;
        _floatViewShowButtonTipsLabel.backgroundColor = PLV_UIColorFromRGBA(@"000000", 0.5);
        _floatViewShowButtonTipsLabel.clipsToBounds = YES;
        _floatViewShowButtonTipsLabel.hidden = YES;
    }
    return _floatViewShowButtonTipsLabel;
}

- (UIButton *)floatViewShowButton{
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (!_floatViewShowButton && roomData.channelType != PLVChannelTypeAlone) {
        _floatViewShowButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_floatViewShowButton setImage:[self getImageWithName:@"plvlc_media_skin_floatview_open"] forState:UIControlStateNormal];
        [_floatViewShowButton setImage:[self getImageWithName:@"plvlc_media_skin_floatview_close"] forState:UIControlStateSelected];
        [_floatViewShowButton addTarget:self action:@selector(floatViewOpenButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _floatViewShowButton.hidden = (self.skinViewType < PLVLCBasePlayerSkinViewType_AlonePlayback ? YES : NO);
    }
    return _floatViewShowButton;
}

- (UIButton *)fullScreenButton{
    if (!_fullScreenButton) {
        _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fullScreenButton setImage:[self getImageWithName:@"plvlc_media_skin_fullscreen"] forState:UIControlStateNormal];
        [_fullScreenButton setImage:[self getImageWithName:@"plvlc_media_skin_fullscreen"] forState:UIControlStateSelected];
        [_fullScreenButton addTarget:self action:@selector(fullScreenButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fullScreenButton;
}


- (UILabel *)currentTimeLabel{
    if (!_currentTimeLabel && self.skinViewType >= PLVLCBasePlayerSkinViewType_AlonePlayback) {
        _currentTimeLabel = [[UILabel alloc] init];
        _currentTimeLabel.text = @"00:00";
        _currentTimeLabel.textAlignment = NSTextAlignmentCenter;
        _currentTimeLabel.textColor = [UIColor whiteColor];
        _currentTimeLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    }
    return _currentTimeLabel;
}

- (UILabel *)diagonalsLabel{
    if (!_diagonalsLabel && self.skinViewType >= PLVLCBasePlayerSkinViewType_AlonePlayback) {
        _diagonalsLabel = [[UILabel alloc] init];
        _diagonalsLabel.text = @"/";
        _diagonalsLabel.textAlignment = NSTextAlignmentCenter;
        _diagonalsLabel.textColor = [UIColor whiteColor];
        _diagonalsLabel.font = [UIFont fontWithName:@"PingFang SC" size:10];
    }
    return _diagonalsLabel;
}

- (UILabel *)durationLabel{
    if (!_durationLabel && self.skinViewType >= PLVLCBasePlayerSkinViewType_AlonePlayback) {
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.text = @"00:00";
        _durationLabel.textAlignment = NSTextAlignmentCenter;
        _durationLabel.textColor = [UIColor whiteColor];
        _durationLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    }
    return _durationLabel;
}

- (PLVProgressSlider *)progressSlider{
    if (!_progressSlider && self.skinViewType >= PLVLCBasePlayerSkinViewType_AlonePlayback) {
        _progressSlider = [[PLVProgressSlider alloc] init];
        _progressSlider.delegate = self;
        _progressSlider.userInteractionEnabled = NO;
        _progressSlider.slider.minimumTrackTintColor = PLV_UIColorFromRGB(@"6DA7FF");
        [_progressSlider.slider setThumbImage:[self getImageWithName:@"plvlc_media_skin_slider_thumbimage"] forState:UIControlStateNormal];
    }
    return _progressSlider;
}


#pragma mark - [ Private Methods ]
- (void)setupData{
    self.skinShow = YES;
}

- (UIImage *)getImageWithName:(NSString *)imageName{
    return [PLVLCUtils imageForMediaResource:imageName];
}

- (void)controlMedia:(UIPanGestureRecognizer *)gestureRecognizer {
    CGPoint p = [gestureRecognizer locationInView:self];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.lastPoint = p;
        CGPoint velocty = [gestureRecognizer velocityInView:self];
        if (fabs(velocty.x) <= fabs(velocty.y)) { //在屏幕右边，上下滑动调整声音
            if (self.lastPoint.x > self.bounds.size.width * 0.5) {
                self.panType = PLVBasePlayerSkinViewTypeAdjusVolume;
            } else {//在屏幕左边，上下滑动调整亮度
                self.panType = PLVBasePlayerSkinViewTypeAdjusBrightness;
                [PLVLCMediaBrightnessView sharedBrightnessView];
            }
        }
    } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged
               || gestureRecognizer.state == UIGestureRecognizerStateEnded
               || gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
        switch (self.panType) {
            case PLVBasePlayerSkinViewTypeAdjusVolume: {
                CGFloat dy = self.lastPoint.y - p.y;
                [self changeVolume:dy];
                break;
            }
            case PLVBasePlayerSkinViewTypeAdjusBrightness: {
                CGFloat dy = self.lastPoint.y - p.y;
                [UIScreen mainScreen].brightness = [self valueOfDistance:dy baseValue:[UIScreen mainScreen].brightness];
                break;
            }
            default:
                break;
        }
        self.lastPoint = p;
    }
}

- (CGFloat)valueOfDistance:(CGFloat)distance baseValue:(CGFloat)baseValue {
    CGFloat value = baseValue + distance / 300.0f;
    if (value < 0.0) {
        value = 0.0;
    } else if (value > 1.0) {
        value = 1.0;
    }
    return value;
}

- (void)changeVolume:(CGFloat)distance {
    if (self.volumeView == nil) {
        self.volumeView = [[MPVolumeView alloc] init];
        self.volumeView.showsVolumeSlider = YES;
        [self addSubview:self.volumeView];
        [self.volumeView sizeToFit];
        self.volumeView.hidden = YES;
    }
    for (UIView *v in self.volumeView.subviews) {
        if ([v.class.description isEqualToString:@"MPVolumeSlider"]) {
            UISlider *volumeSlider = (UISlider *)v;
            [volumeSlider setValue:[self valueOfDistance:distance baseValue:volumeSlider.value] animated:NO];
            [volumeSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
            break;
        }
    }
}


#pragma mark - [ Event ]
#pragma mark Action
- (void)tapGestureAction:(UITapGestureRecognizer *)tapGR {
    [self controlsSwitchShowStatusWithAnimation:!self.skinShow];
}

- (void)panGestureAction:(UIPanGestureRecognizer *)panGR {
    [self controlMedia:panGR];
}

- (void)backButtonAction:(UIButton *)button{
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (self.baseDelegate && [self.baseDelegate respondsToSelector:@selector(plvLCBasePlayerSkinViewBackButtonClicked:currentFullScreen:)]) {
        [self.baseDelegate plvLCBasePlayerSkinViewBackButtonClicked:self currentFullScreen:fullScreen];
    }
}

- (void)moreButtonAction:(UIButton *)button{
    if (self.baseDelegate && [self.baseDelegate respondsToSelector:@selector(plvLCBasePlayerSkinViewMoreButtonClicked:)]) {
        [self.baseDelegate plvLCBasePlayerSkinViewMoreButtonClicked:self];
    }
}

- (void)playButtonAction:(UIButton *)button{
    BOOL wannaPlay = !button.selected;
    if (self.baseDelegate && [self.baseDelegate respondsToSelector:@selector(plvLCBasePlayerSkinViewPlayButtonClicked:wannaPlay:)]) {
        [self.baseDelegate plvLCBasePlayerSkinViewPlayButtonClicked:self wannaPlay:wannaPlay];
    }
}

- (void)refreshButtonAction:(UIButton *)button{
    if (self.baseDelegate && [self.baseDelegate respondsToSelector:@selector(plvLCBasePlayerSkinViewRefreshButtonClicked:)]) {
        [self.baseDelegate plvLCBasePlayerSkinViewRefreshButtonClicked:self];
    }
}

- (void)floatViewOpenButtonAction:(UIButton *)button{
    [self showFloatViewShowButtonTipsLabelAnimation:NO];
    if (self.baseDelegate && [self.baseDelegate respondsToSelector:@selector(plvLCBasePlayerSkinViewFloatViewShowButtonClicked:userWannaShowFloatView:)]) {
        BOOL wannaShow = self.floatViewShowButton.selected;
        [self.baseDelegate plvLCBasePlayerSkinViewFloatViewShowButtonClicked:self userWannaShowFloatView:wannaShow];
    }
}

- (void)fullScreenButtonAction:(UIButton *)button{
    if (self.baseDelegate && [self.baseDelegate respondsToSelector:@selector(plvLCBasePlayerSkinViewFullScreenOpenButtonClicked:)]) {
        [self.baseDelegate plvLCBasePlayerSkinViewFullScreenOpenButtonClicked:self];
    }
}


#pragma mark - [ Delegate ]
- (void)plvProgressSlider:(PLVProgressSlider *)progressSlider sliderDragEnd:(CGFloat)currentSliderProgress{
    if([self.baseDelegate respondsToSelector:@selector(plvLCBasePlayerSkinView:sliderDragEnd:)]){
        [self.baseDelegate plvLCBasePlayerSkinView:self sliderDragEnd:currentSliderProgress];
    }
}

- (void)plvProgressSlider:(PLVProgressSlider *)progressSlider sliderDragingProgressChange:(CGFloat)currentSliderProgress{
    
}

@end
