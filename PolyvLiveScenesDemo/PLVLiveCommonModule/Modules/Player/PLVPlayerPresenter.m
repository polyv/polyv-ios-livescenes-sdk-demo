//
//  PLVPlayerPresenter.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/12/11.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVPlayerPresenter.h"

#import "PLVRoomDataManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVAdvView.h"

@interface PLVPlayerPresenterBackgroundView : UIView /// 仅 PLVPlayerPresenter 内部使用的背景视图类

/// 子视图布局时机回调
@property (nonatomic, strong) void (^layoutSubviewsBlock) (BOOL sizeAvailable);

@end

@interface PLVPlayerPresenter ()<
PLVPlayerDelegate,
PLVLivePlayerDelegate,
PLVLivePlaybackPlayerDelegate,
PLVAdvViewDelegate
>

#pragma mark 状态
@property (nonatomic, assign) PLVChannelVideoType currentVideoType;
@property (nonatomic, assign) BOOL needShowLoading;
@property (nonatomic, assign) BOOL keepShowAdv;
@property (nonatomic, assign) BOOL currentNoDelayLiveStart;

#pragma mark UI
/// view hierarchy
///
/// (UIView) displayView (外部通过 [setupPlayerWithDisplayView:] 方法传入)
///  └── (PLVPlayerPresenterBackgroundView) backgroundView
///      ├── (UIView) playerBackgroundView
///      ├── (UIImageView) warmUpImageView
///      ├── (UIActivityIndicatorView) activityView
///      └── (UILabel) loadSpeedLabel
@property (nonatomic, weak) UIView * displayView;
@property (nonatomic, strong) PLVPlayerPresenterBackgroundView * backgroundView;
@property (nonatomic, strong) UIView * playerBackgroundView;
@property (nonatomic, strong) UIImageView * warmUpImageView;
@property (nonatomic, strong) UIActivityIndicatorView * activityView;
@property (nonatomic, strong) UILabel * loadSpeedLabel;

#pragma mark 功能对象
@property (nonatomic, strong) PLVLivePlayer * livePlayer;
@property (nonatomic, strong) PLVLivePlaybackPlayer * livePlaybackPlayer;
@property (nonatomic, strong) PLVAdvView * advView;
@property (nonatomic, strong) NSTimer * timer;

@end

@implementation PLVPlayerPresenter

#pragma mark - [ Life Period ]
- (void)dealloc{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    
    if (self.advView) {
        [self.advView distroy];
        self.advView = nil;
    }

    NSLog(@"%s",__FUNCTION__);
}


#pragma mark - [ Public Methods ]
#pragma mark Getter
- (NSInteger)lineNum{
    return self.livePlayer.channelInfo.lineNum;
}

- (NSInteger)currentLineIndex{
    return self.livePlayer.channelInfo.currentLineIndex;
}

- (NSArray<NSString *> *)codeRateNamesOptions{
    return self.livePlayer.channelInfo.definitionNamesOptions;
}

- (NSString *)currentCodeRate{
    return self.livePlayer.channelInfo.currentDefinition;
}

- (NSTimeInterval)currentPlaybackTime{
    return self.livePlaybackPlayer.currentPlaybackTime;
}

- (NSTimeInterval)duration{
    return self.livePlaybackPlayer.duration;
}

- (BOOL)advPlaying {
    return self.advView.playing;
}

- (NSString *)advLinkUrl {
    return [PLVRoomDataManager sharedManager].roomData.channelInfo.advertHref;
}

- (BOOL)channelInLive{
    BOOL channelInLive = (self.currentStreamState == PLVChannelLiveStreamState_Live);
    return channelInLive;
}

- (PLVChannelLiveStreamState)currentStreamState{
    return self.livePlayer.currentStreamState;
}

- (BOOL)channelWatchNoDelay{
    return [PLVRoomDataManager sharedManager].roomData.menuInfo.watchNoDelay;
}

#pragma mark 通用
- (instancetype)initWithVideoType:(PLVChannelVideoType)videoType{
    self = [super init];
    if (self) {
        self.currentVideoType = videoType;
        
        [self setup];
        [self setupPlayer];
    }
    return self;
}

- (void)setupPlayerWithDisplayView:(UIView *)displayView {
    if (!displayView || ![displayView isKindOfClass:UIView.class]) {
        NSLog(@"PLVPlayerPresenter - %s failed, displayView illegal:%@",__FUNCTION__,displayView);
        return;
    }
    
    if (!self.livePlayer && !self.livePlaybackPlayer) {
        NSLog(@"PLVPlayerPresenter - %s failed, no player exsit",__FUNCTION__);
        return;
    }
    
    self.displayView = displayView;
    [self setupUI];
    
    [self.livePlayer setupDisplaySuperview:self.playerBackgroundView];
    [self.livePlaybackPlayer setupDisplaySuperview:self.playerBackgroundView];
}

- (void)cleanPlayer{
    [self.livePlayer clearAllPlayer];
    [self.livePlaybackPlayer clearAllPlayer];
}

- (BOOL)resumePlay{
    if (self.advView.playing) { // 片头广告显示中
        return NO;
    }
    
    if (self.currentVideoType == PLVChannelVideoType_Live) {
        [self.livePlayer reloadLivePlayer];
    } else if (self.currentVideoType == PLVChannelVideoType_Playback){
        [self.livePlaybackPlayer play];
    }
    return YES;
}

- (BOOL)pausePlay{
    if (self.advView.playing) { // 片头广告显示中
        return NO;
    }
    
    if (self.currentVideoType == PLVChannelVideoType_Live) {
        [self.livePlayer pause];
    } else if (self.currentVideoType == PLVChannelVideoType_Playback){
        [self.livePlaybackPlayer pause];
    }
    return YES;
}

- (void)mute{
    [self.livePlayer mute];
    [self.livePlaybackPlayer mute];
}

- (void)cancelMute{
    [self.livePlayer cancelMute];
    [self.livePlaybackPlayer cancelMute];
}

#pragma mark 直播相关
- (void)switchLiveToAudioMode:(BOOL)audioMode{
    [self.livePlayer switchToAudioMode:audioMode];
}

- (void)switchLiveToCodeRate:(NSString *)codeRate{
    [self.livePlayer switchToLineIndex:self.currentLineIndex codeRate:codeRate];
}

- (void)switchLiveToLineIndex:(NSInteger)lineIndex{
    [self.livePlayer switchToLineIndex:lineIndex codeRate:self.currentCodeRate];
}

#pragma mark 非直播相关
- (void)seekLivePlaybackToTime:(NSTimeInterval)toTime{
    if (self.advView.playing) { // 片头广告显示中
        return;
    }
    
    [self.livePlaybackPlayer seekLivePlaybackToTime:toTime];
}

- (void)switchLivePlaybackSpeedRate:(CGFloat)toSpeed{
    if (self.advView.playing) { // 片头广告显示中
        return;
    }
    
    [self.livePlaybackPlayer switchLivePlaybackSpeedRate:toSpeed];
}

#pragma mark - [ Private Methods ]
- (void)setup{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(timerEvent:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    
    _keepShowAdv = YES;
}

- (void)setupPlayer{
    PLVRoomData * roomData = [PLVRoomDataManager sharedManager].roomData;
    NSString * userIdForAccount = [PLVLiveVideoConfig sharedInstance].userId;
    if (self.currentVideoType == PLVChannelVideoType_Live) { /// 直播
        self.livePlayer = [[PLVLivePlayer alloc] initWithPLVAccountUserId:userIdForAccount channelId:roomData.channelId];
        self.livePlayer.delegate = self;
        self.livePlayer.liveDelegate = self;
        self.livePlayer.channelWatchNoDelay = roomData.menuInfo.watchNoDelay;
        [self.livePlayer setupDisplaySuperview:self.playerBackgroundView];
        
        self.livePlayer.videoToolBox = NO;
        self.livePlayer.chaseFrame = NO;
        self.livePlayer.customParam = roomData.customParam;
    }else if (self.currentVideoType == PLVChannelVideoType_Playback){ /// 回放
        self.livePlaybackPlayer = [[PLVLivePlaybackPlayer alloc] initWithPLVAccountUserId:userIdForAccount channelId:roomData.channelId vodId:roomData.vid vodList:roomData.vodList];
        self.livePlaybackPlayer.delegate = self;
        self.livePlaybackPlayer.livePlaybackDelegate = self;
        [self.livePlaybackPlayer setupDisplaySuperview:self.playerBackgroundView];

        self.livePlaybackPlayer.videoToolBox = NO;
        self.livePlaybackPlayer.customParam = roomData.customParam;
    }
}

- (void)setupUI{
    [self.displayView addSubview:self.backgroundView];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.frame = self.displayView.bounds;
    
    [self.backgroundView addSubview:self.playerBackgroundView];
    [self.backgroundView addSubview:self.warmUpImageView];
    [self.backgroundView addSubview:self.activityView];
    [self.backgroundView addSubview:self.loadSpeedLabel];
        
    self.playerBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.playerBackgroundView.frame = self.backgroundView.bounds;
    
    self.warmUpImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.warmUpImageView.frame = self.backgroundView.bounds;
        
    __weak typeof(self) weakSelf = self;
    self.backgroundView.layoutSubviewsBlock = ^(BOOL sizeAvailable) {
        if (sizeAvailable && !weakSelf.activityView.constraints.count) {
            UIView * superView = weakSelf.backgroundView;
            UIActivityIndicatorView * activityView = weakSelf.activityView;
            NSDictionary * activityViewViews = NSDictionaryOfVariableBindings(activityView, superView);
            [superView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[activityView]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:activityViewViews]];
            [superView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[activityView]-30-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:activityViewViews]];
            [weakSelf.activityView setTranslatesAutoresizingMaskIntoConstraints:NO];
            
            UILabel * loadSpeedLabel = weakSelf.loadSpeedLabel;
            NSDictionary * loadSpeedLabelViews = NSDictionaryOfVariableBindings(loadSpeedLabel, superView);
            [superView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[loadSpeedLabel]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:loadSpeedLabelViews]];
            [superView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-30-[loadSpeedLabel]-|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:loadSpeedLabelViews]];
            [weakSelf.loadSpeedLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        }
    };
}

- (void)showAdv {
    /** 不显示片头广告(此开关应对云课堂暂时不显示片头广告情况，后面云课程支持片头广告，需去掉openAdv) */
    if (! self.openAdv) {
        return;
    }
    
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    
    // 存在片头广告
    if ((roomData.liveState == PLVChannelLiveStreamState_Live ||
         roomData.videoType == PLVChannelVideoType_Playback) && // 直播开播了或者是点播
        ([PLVFdUtil checkStringUseable:roomData.channelInfo.advertImage] ||
         [PLVFdUtil checkStringUseable:roomData.channelInfo.advertFlvUrl])) { // 存在片头图片或视频
        [self pausePlay];

        if (! self.advView) { // 广告播放器初始化
            _advView = [[PLVAdvView alloc] init];
            self.advView.delegate = self;
            [self.advView setupDisplaySuperview:self.playerBackgroundView];
        }
        
        if ([PLVFdUtil checkStringUseable:roomData.channelInfo.advertImage]) {
            [self.advView showImageWithUrl:roomData.channelInfo.advertImage time:roomData.channelInfo.advertDuration];
        } else {
            [self.advView showVideoWithUrl:roomData.channelInfo.advertFlvUrl time:roomData.channelInfo.advertDuration];
        }
    }
}

#pragma mark Getter
- (PLVPlayerPresenterBackgroundView *)backgroundView{
    if (!_backgroundView) {
        _backgroundView = [[PLVPlayerPresenterBackgroundView alloc] init];
    }
    return _backgroundView;
}

- (UIView *)playerBackgroundView{
    if (!_playerBackgroundView) {
        _playerBackgroundView = [[UIView alloc] init];
    }
    return _playerBackgroundView;
}

- (UIImageView *)warmUpImageView{
    if (!_warmUpImageView) {
        _warmUpImageView = [[UIImageView alloc] init];
        _warmUpImageView.contentMode = UIViewContentModeScaleAspectFit;
        _warmUpImageView.hidden = YES;
    }
    return _warmUpImageView;
}

- (UIActivityIndicatorView *)activityView{
    if (!_activityView) {
        _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityView.color = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    }
    return _activityView;
}

- (UILabel *)loadSpeedLabel{
    if (!_loadSpeedLabel) {
        _loadSpeedLabel = [[UILabel alloc] init];
        _loadSpeedLabel.font = [UIFont systemFontOfSize:11.0];
        _loadSpeedLabel.textAlignment = NSTextAlignmentCenter;
        _loadSpeedLabel.textColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        _loadSpeedLabel.hidden = YES;
    }
    return _loadSpeedLabel;
}


#pragma mark - [ Event ]
#pragma mark Timer
- (void)timerEvent:(NSTimer *)timer{
    if (self.livePlayer && self.activityView.isAnimating) {
        self.loadSpeedLabel.hidden = NO;
        self.loadSpeedLabel.text = self.livePlayer.tcpSpeed;
    }else{
        self.loadSpeedLabel.hidden = YES;
    }
    
    /** 断网后联网回看重新播放-从广告开始 */
    if (self.currentVideoType == PLVChannelVideoType_Playback) {
        PLVNetworkStatus networkStatus = [PLVReachability reachabilityForInternetConnection].currentReachabilityStatus;
        if (networkStatus != PLVNotReachable && self.keepShowAdv &&
            self.livePlaybackPlayer.showingContent) {
            _keepShowAdv = NO;
            [self showAdv];
        }
    }
}


#pragma mark - [ Delegate ]
#pragma mark PLVPlayerDelegate
/// 播放器加载前 回调options配置对象
- (PLVOptions *)plvPlayer:(PLVPlayer *)player playerWillLoad:(PLVPlayerMainSubType)mainSubType withOptions:(nonnull PLVOptions *)options{
    [self.activityView startAnimating];
    [self timerEvent:nil];
    
    return options;
}

/// 主播放器 ‘SEI信息’ 发生改变
- (void)plvPlayer:(PLVPlayer *)player playerSeiDidChanged:(long)timeStamp{
    long newTimeStamp = timeStamp - player.videoCacheDuration;
    if (newTimeStamp > 0) {
        if ([self.delegate respondsToSelector:@selector(playerPresenter:seiDidChange:newTimeStamp:)]) {
            [self.delegate playerPresenter:self seiDidChange:timeStamp newTimeStamp:newTimeStamp];
        }
    }
}

/// 播放器 已准备好播放
- (void)plvPlayer:(PLVPlayer *)player playerIsPreparedToPlay:(PLVPlayerMainSubType)mainSubType{
    [self.activityView stopAnimating];
    [self timerEvent:nil];
    
    /**
     * 此处两种情况会执行：
     * 1. 直播、回看初始播放广告；
     * 2. 直播断开后联网也会调用此方法进行重新播放 */
    if (self.keepShowAdv) {
        _keepShowAdv = NO;
        [self showAdv];
    }

    if ([self.delegate respondsToSelector:@selector(playerPresenter:videoSizeChange:)]) {
        [self.delegate playerPresenter:self videoSizeChange:player.naturalSize];
    }
}

/// 播放器 ’加载状态‘ 发生改变
- (void)plvPlayer:(PLVPlayer *)player playerLoadStateDidChange:(PLVPlayerMainSubType)mainSubType{
    if (mainSubType == PLVPlayerMainSubType_Main) {
        if (player.mainPlayerLoadState & IJKMPMovieLoadStateStalled) {
            self.needShowLoading = YES;
            __weak typeof(self) weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                BOOL playerExist = (weakSelf.currentVideoType == PLVChannelVideoType_Live) ? weakSelf.livePlayer.mainPlayerExist : weakSelf.livePlaybackPlayer.mainPlayerExist;
                if (weakSelf.needShowLoading && playerExist) {
                    [weakSelf.activityView startAnimating];
                }
            });
        } else {
            self.needShowLoading = NO;
            [self.activityView stopAnimating];
        }
    }
}

/// 播放器 ’播放状态‘ 发生改变
- (void)plvPlayer:(PLVPlayer *)player playerPlaybackStateDidChange:(PLVPlayerMainSubType)mainSubType{

}

/// 播放器 ’是否正在播放中‘状态 发生改变
- (void)plvPlayer:(PLVPlayer *)player playerPlayingStateDidChange:(PLVPlayerMainSubType)mainSubType playing:(BOOL)playing{
    if (mainSubType == PLVPlayerMainSubType_Main) {
        [PLVRoomDataManager sharedManager].roomData.playing = playing;
        if ([self.delegate respondsToSelector:@selector(playerPresenter:playerPlayingStateDidChanged:)]) {
            [self.delegate playerPresenter:self playerPlayingStateDidChanged:playing];
        }
    }
}

/// 播放器 播放结束
- (void)plvPlayer:(PLVPlayer *)player playerPlaybackDidFinish:(PLVPlayerMainSubType)mainSubType finishReson:(IJKMPMovieFinishReason)finishReson{
    NSString * errorMessage = @"";
    if (finishReson == IJKMPMovieFinishReasonPlaybackEnded) {
        if (self.currentVideoType == PLVChannelVideoType_Playback) {
            if ([self.delegate respondsToSelector:@selector(playerPresenter:downloadProgress:playedProgress:playedTimeString:durationTimeString:)]) {
                [self.delegate playerPresenter:self downloadProgress:0 playedProgress:1 playedTimeString:self.livePlaybackPlayer.playedTimeString durationTimeString:self.livePlaybackPlayer.durationTimeString];
                /// 断网导致播放停止的情况
                if (self.duration - self.currentPlaybackTime >= 1) {
                    if (self.delegate && [self.delegate respondsToSelector:@selector(playerPresenterPlaybackInterrupted:)]) {
                        [self.delegate playerPresenterPlaybackInterrupted:self];
                    }
                }
            }
        }
    } else if (finishReson == IJKMPMovieFinishReasonPlaybackError) {
        errorMessage = @"视频播放失败，请退出重新登录";
        [self.activityView stopAnimating];
        
        if (self.currentVideoType == PLVChannelVideoType_Playback) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(playerPresenterPlaybackInterrupted:)]) {
                [self.delegate playerPresenterPlaybackInterrupted:self];
            }
        }
    }
    
    if ([PLVFdUtil checkStringUseable:errorMessage]) {
        if ([self.delegate respondsToSelector:@selector(playerPresenter:loadPlayerFailureWithMessage:)]) {
            [self.delegate playerPresenter:self loadPlayerFailureWithMessage:errorMessage];
        }
    }
}

/// 播放器 已销毁
- (void)plvPlayer:(PLVPlayer *)player playerDidDestroyed:(PLVPlayerMainSubType)mainSubType{
    [self.activityView stopAnimating];
}

#pragma mark PLVLivePlayerDelegate
/// 直播播放器 ‘加载状态’ 发生改变
- (void)plvLivePlayer:(PLVLivePlayer *)livePlayer loadStateDidChanged:(PLVLivePlayerLoadState)loadState{

}

/// 直播播放器 ‘流状态’ 更新
- (void)plvLivePlayer:(PLVLivePlayer *)livePlayer streamStateUpdate:(PLVChannelLiveStreamState)newestStreamState streamStateDidChanged:(BOOL)streamStateDidChanged{
    [PLVRoomDataManager sharedManager].roomData.liveState = newestStreamState;
    
    /** 直播断开，设置联网后播放广告 */
    if (newestStreamState != PLVChannelLiveStreamState_Live) {
//        _keepShowAdv = YES;
        PLVNetworkStatus networkStatus = [PLVReachability reachabilityForInternetConnection].currentReachabilityStatus;
        if (networkStatus == PLVNotReachable) {
            if (self.advView.playing) { // 广告在播放则不后续操作
                return;
            }
        } else {
            if (self.advView) {
                [self.advView distroy];
                self.advView = nil;
            }
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(playerPresenter:streamStateUpdate:streamStateDidChanged:)]) {
        [self.delegate playerPresenter:self streamStateUpdate:newestStreamState streamStateDidChanged:streamStateDidChanged];
    }
    
    if (livePlayer.channelWatchNoDelay) {
        BOOL noDelayLiveStart = (newestStreamState == PLVChannelLiveStreamState_Live);
        BOOL noDelayLiveStartDidChanged = (noDelayLiveStart != self.currentNoDelayLiveStart);
        self.currentNoDelayLiveStart = noDelayLiveStart;
        if ([self.delegate respondsToSelector:@selector(playerPresenter:noDelayLiveStartUpdate:noDelayLiveStartDidChanged:)]) {
            [self.delegate playerPresenter:self noDelayLiveStartUpdate:noDelayLiveStart noDelayLiveStartDidChanged:noDelayLiveStartDidChanged];
        }
    }
}

/// 直播播放器 发生错误
- (void)plvLivePlayer:(PLVLivePlayer *)livePlayer loadMainPlayerFailureWithError:(NSError * _Nullable)error{
    /* 若需进行 “报错描述自定义”，可根据已划分好的类别，来分别作自定义 */
    NSString * message = @"";
    if ((error.code >= [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeChannelRestrict_PlayRestrict] &&
         error.code <= [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeChannelRestrict_RequestFailed])) {
        /// 限制信息
        message = [NSString stringWithFormat:@"%ld %@",(long)error.code,error.localizedDescription];
    } else if ((error.code >= [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetChannelInfo_RequestFailed] &&
                error.code <= [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetChannelInfo_CodeError]) ||
               error.code == [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetChannelInfo_ParameterError]){
        /// 频道信息请求失败
        message = [NSString stringWithFormat:@"%ld %@",(long)error.code,error.localizedDescription];
    } else if (error.code == [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeNetwork_NotGoodNetwork]){
        /// 网络不佳视频加载缓
        message = [NSString stringWithFormat:@"%ld %@",(long)error.code,error.localizedDescription];
    } else if ((error.code >= [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetStreamState_DataError] &&
                error.code <= [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetStreamState_RequestFailed]) ||
               error.code == [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetStreamState_ParameterError]){
        /// 直播流状态信息 请求失败
        message = [NSString stringWithFormat:@"%ld %@",(long)error.code,error.localizedDescription];
    } else if (error.code == [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetSessionID_RequestFailed] ||
               error.code == [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetSessionID_ParameterError]){
        /// 直播SessionID 请求失败
        message = [NSString stringWithFormat:@"%ld %@",(long)error.code,error.localizedDescription];
    } else {
        /// 其他错误 (如网络错误)
        message = [NSString stringWithFormat:@"%ld %@",(long)error.code,error.localizedDescription];
    }
    
    if ([self.delegate respondsToSelector:@selector(playerPresenter:loadPlayerFailureWithMessage:)]) {
        [self.delegate playerPresenter:self loadPlayerFailureWithMessage:message];
    }
}

/// 直播播放器 ‘频道信息’ 发生改变
- (void)plvLivePlayer:(PLVLivePlayer *)livePlayer channelInfoDidUpdated:(PLVChannelInfoModel *)channelInfo{
    [PLVRoomDataManager sharedManager].roomData.channelInfo = channelInfo;
    
    if ([self.delegate respondsToSelector:@selector(playerPresenter:channelInfoDidUpdated:)]) {
        [self.delegate playerPresenter:self channelInfoDidUpdated:channelInfo];
    }
}

/// 直播播放器 ‘码率可选项、当前码率、线路可选数、当前线路‘ 发生改变
- (void)plvLivePlayer:(PLVLivePlayer *)livePlayer codeRateOptions:(NSArray <NSString *> *)codeRateOptions currentCodeRate:(NSString *)currentCodeRate lineNum:(NSInteger)lineNum currentLineIndex:(NSInteger)currentLineIndex{
    if ([self.delegate respondsToSelector:@selector(playerPresenter:codeRateOptions:currentCodeRate:lineNum:currentLineIndex:)]) {
        [self.delegate playerPresenter:self codeRateOptions:codeRateOptions currentCodeRate:currentCodeRate lineNum:lineNum currentLineIndex:currentLineIndex];
    }
}

/// 直播播放器 需获知外部 ‘当前是否正在连麦’
- (BOOL)plvLivePlayerGetInLinkMic:(PLVLivePlayer *)livePlayer{
    if ([self.delegate respondsToSelector:@selector(playerPresenterGetInLinkMic:)]) {
        return [self.delegate playerPresenterGetInLinkMic:self];
    }else{
        return NO;
    }
}

/// 直播播放器 需展示暖场图片
- (void)plvLivePlayer:(PLVLivePlayer *)livePlayer showWarmUpImage:(BOOL)show warmUpImageURLString:(NSString *)warmUpImageURLString{
    if (show) {
        self.warmUpImageView.hidden = NO;
        [self.warmUpImageView sd_setImageWithURL:[NSURL URLWithString:warmUpImageURLString] placeholderImage:nil options:SDWebImageRetryFailed];
    }else{
        self.warmUpImageView.hidden = YES;
    }
}

#pragma mark PLVLivePlaybackPlayerDelegate
/// 直播回放播放器 发生错误
- (void)plvLivePlaybackPlayer:(PLVLivePlaybackPlayer *)livePlaybackPlayer loadMainPlayerFailureWithError:(NSError * _Nullable)error{
    /* 若需进行 “报错描述自定义”，可根据已划分好的类别，来分别作自定义 */
    NSString * message = @"";
    if ((error.code >= [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetVideoInfo_CodeError] &&
         error.code <= [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetVideoInfo_RequestFailed]) ||
        error.code == [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetVideoInfo_ParameterError]) {
        /// 回放信息请求失败
        message = [NSString stringWithFormat:@"%ld %@",(long)error.code,error.localizedDescription];
    } else if ((error.code >= [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetChannelInfo_RequestFailed] &&
                error.code <= [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetChannelInfo_CodeError]) ||
               error.code == [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetChannelInfo_ParameterError]){
        /// 频道信息请求失败
        message = [NSString stringWithFormat:@"%ld %@",(long)error.code,error.localizedDescription];
    }
    
    if ([self.delegate respondsToSelector:@selector(playerPresenter:loadPlayerFailureWithMessage:)]) {
        [self.delegate playerPresenter:self loadPlayerFailureWithMessage:message];
    }
}

/// 直播回放播放器 定时返回当前播放进度
- (void)plvLivePlaybackPlayer:(PLVLivePlaybackPlayer *)livePlaybackPlayer downloadProgress:(CGFloat)downloadProgress playedProgress:(CGFloat)playedProgress playedTimeString:(NSString *)playedTimeString durationTimeString:(NSString *)durationTimeString{
//    /** 回看播放中监控到断网了，设置联网后播放广告 */
//    PLVNetworkStatus networkStatus = [PLVReachability reachabilityForInternetConnection].currentReachabilityStatus;
//    if (networkStatus == NotReachable) {
//        _keepShowAdv = YES;
//    }
    
    if ([self.delegate respondsToSelector:@selector(playerPresenter:downloadProgress:playedProgress:playedTimeString:durationTimeString:)]) {
        [self.delegate playerPresenter:self downloadProgress:downloadProgress playedProgress:playedProgress playedTimeString:playedTimeString durationTimeString:durationTimeString];
    }
}

/// 直播回放播放器 ‘频道信息’ 发生改变
- (void)plvLivePlaybackPlayer:(PLVLivePlaybackPlayer *)livePlaybackPlayer channelInfoDidUpdated:(PLVChannelInfoModel *)channelInfo{
    [PLVRoomDataManager sharedManager].roomData.channelInfo = channelInfo;
    if ([self.delegate respondsToSelector:@selector(playerPresenter:channelInfoDidUpdated:)]) {
        [self.delegate playerPresenter:self channelInfoDidUpdated:channelInfo];
    }
}

#pragma mark PLVAdvViewDelegate
/// 广告状态回调
- (void)advView:(PLVAdvView *)advView status:(PLVAdvViewStatus)status {
    if (status == PLVAdvViewStatusPlay) {
        
    } else if (status == PLVAdvViewStatusFinish) {
        PLVNetworkStatus networkStatus = [PLVReachability reachabilityForInternetConnection].currentReachabilityStatus;
        if (networkStatus != PLVNotReachable &&
            (!self.keepShowAdv || self.livePlaybackPlayer.downloadProgress == 1)) {
            [self.advView distroy];
            self.advView = nil;
            [self resumePlay];
        } else {
            _keepShowAdv = YES;
        }
    }
}

@end

@implementation PLVPlayerPresenterBackgroundView

- (void)layoutSubviews{
    BOOL sizeAvailable = !CGSizeEqualToSize(self.frame.size, CGSizeZero);
    if (self.layoutSubviewsBlock) { self.layoutSubviewsBlock(sizeAvailable); }
}

@end
