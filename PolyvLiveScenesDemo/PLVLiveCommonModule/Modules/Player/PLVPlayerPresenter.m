//
//  PLVPlayerPresenter.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/12/11.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVPlayerPresenter.h"

#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDWebImageDownloader.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVPlayerLogoView.h"

static NSString * const kUserDefaultPlaybackLastTimeInfo = @"UserDefaultPlaybackLastTimeInfo";

static NSString * const kUserDefaultPlaybackMaxPositionInfo = @"UserDefaultPlaybackMaxPositionInfo";

@interface PLVPlayerPresenterBackgroundView : UIView /// 仅 PLVPlayerPresenter 内部使用的背景视图类

/// 子视图布局时机回调
@property (nonatomic, strong) void (^layoutSubviewsBlock) (BOOL sizeAvailable);

@end

@interface PLVPlayerPresenter ()<
PLVPlayerDelegate,
PLVLivePlayerDelegate,
PLVLivePlayerPictureInPictureDelegate,
PLVLivePlaybackPlayerDelegate,
PLVAdvertViewDelegate,
PLVPublicStreamPlayerDelegate,
PLVDefaultPageViewDelegate
>

#pragma mark 状态
@property (nonatomic, assign) PLVChannelVideoType currentVideoType;
@property (nonatomic, assign) BOOL needShowLoading;
@property (nonatomic, assign) BOOL keepShowAdvert;
@property (nonatomic, assign) BOOL currentNoDelayLiveStart;
@property (nonatomic, assign) PLVLivePlayerQuickLiveNetworkQuality networkQuality;
@property (nonatomic, assign) NSInteger networkQualityRepeatCount;
@property (nonatomic, assign) PLVPublicStreamPlayerNetworkQuality publicStreamNetworkQuality; //!< 公共流网络质量
@property (nonatomic, assign) NSInteger publicStreamNetworkQualityRepeatCount; //!< 公共流网络质量重复次数
@property (nonatomic, assign) BOOL currentLivePlaybackChangingVid;
@property (nonatomic, assign) IJKMPMovieScalingMode scalingMode;

#pragma mark UI
/// view hierarchy
///
/// (UIView) displayView (外部通过 [setupPlayerWithDisplayView:] 方法传入)
///  └── (PLVPlayerPresenterBackgroundView) backgroundView
///      ├── (UIView) playerBackgroundView
///      ├── (UIImageView) warmUpImageView
///      ├── (UIActivityIndicatorView) activityView
///      ├── (UILabel) loadSpeedLabel
///      └── (PLVPlayerLogoView) logoView
///      └── (PLVDefaultPageView) defaultPageView
@property (nonatomic, weak) UIView * displayView;
@property (nonatomic, strong) PLVPlayerPresenterBackgroundView * backgroundView;
@property (nonatomic, strong) UIView * playerBackgroundView;
@property (nonatomic, strong) UIImageView * warmUpImageView;
@property (nonatomic, strong) PLVPlayerLogoView * logoView;
@property (nonatomic, strong) PLVDefaultPageView * defaultPageView;
@property (nonatomic, strong) UIActivityIndicatorView * activityView;
@property (nonatomic, strong) UILabel * loadSpeedLabel;

#pragma mark 功能对象
@property (nonatomic, strong) PLVLivePlayer * livePlayer;
@property (nonatomic, strong) PLVPublicStreamPlayer *streamPlayer;
@property (nonatomic, strong) PLVLivePlaybackPlayer * livePlaybackPlayer;
@property (nonatomic, strong) PLVAdvertView * advertView;
@property (nonatomic, strong) NSTimer * timer;
@property (nonatomic, strong) NSTimer * countDownTimer;

#pragma mark 数据
@property (nonatomic, readonly) PLVChannelInfoModel *channelInfo;
@property (nonatomic, copy) NSString * channelId;
@property (nonatomic, copy) NSString * vodId;
@property (nonatomic, copy) NSString * fileId;
@property (nonatomic, assign) BOOL vodList;
@property (nonatomic, assign) BOOL recordEnable;
@property (nonatomic, assign) PLVLiveRecordFileModel * recordFile; /// 当前直播间的暂存数据
@property (nonatomic, weak, readonly) PLVRoomData * currentExternalRoomData; /// 当前直播间数据 (指外部的，即不一定与播放器的频道号匹配)
@property (nonatomic, weak, readonly) PLVViewLogCustomParam * currentExternalCustomParam; /// 当前统计自定义参数 (只允许读取外部配置的)
@property (nonatomic, assign) NSInteger countDownTime;

@end

@implementation PLVPlayerPresenter

#pragma mark - [ Life Period ]
- (void)dealloc{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    
    if (_countDownTimer) {
        [_countDownTimer invalidate];
        _countDownTimer = nil;
    }
    
    if (_advertView) {
        [_advertView destroyTitleAdvert];
    }
    
    [self.backgroundView removeFromSuperview]; /// 需单独作移除操作以保证释放
    NSLog(@"%s",__FUNCTION__);
}


#pragma mark - [ Public Methods ]
#pragma mark Getter
- (PLVChannelInfoModel *)currentChannelInfo{
    if (self.currentVideoType == PLVChannelVideoType_Live) {
        return self.livePlayer.channelInfo;
    } else if (self.currentVideoType == PLVChannelVideoType_Playback){
        return self.livePlaybackPlayer.channelInfo;
    } else {
        return nil;
    }
}

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

- (BOOL)advertPlaying {
    return self.advertView.startAdvertIsPlaying;
}

- (BOOL)channelMatchExternal{
    return [self.channelId isEqualToString:self.currentExternalRoomData.channelId];
}

- (BOOL)channelInLive{
    BOOL channelInLive = (self.currentStreamState == PLVChannelLiveStreamState_Live);
    return channelInLive;
}

- (PLVChannelLiveStreamState)currentStreamState{
    return self.livePlayer.currentStreamState;
}

- (BOOL)channelWatchNoDelay{
    if (self.currentExternalRoomData.menuInfo.transmitMode && self.currentExternalRoomData.menuInfo.mainRoom) {
        // 双师模式下，位于大房间时只允许拉CDN流
        return NO;
    } else if (self.channelMatchExternal) {
        return self.currentExternalRoomData.menuInfo.watchNoDelay;
    } else {
        /// 当前PlayerPresenter的频道号，与外部频道号不一致
        /// 此时不允许执行观看无延迟，因此[channelWatchNoDelay]该值无意义，而恒为NO
        return NO;
    }
}

- (BOOL)currentPlayerWatchNoDelay{
    return self.livePlayer.channelWatchNoDelay;
}

- (BOOL)channelWatchQuickLive{
    if (self.currentExternalRoomData.menuInfo.transmitMode && self.currentExternalRoomData.menuInfo.mainRoom) {
        // 双师模式下，位于大房间时只允许拉CDN流
        return NO;
    } else if (self.channelMatchExternal) {
        return self.currentExternalRoomData.menuInfo.watchQuickLive;
    } else {
        /// 当前PlayerPresenter的频道号，与外部频道号不一致
        /// 此时不允许执行观看快直播，因此[channelWatchQuickLive]该值无意义，而恒为NO
        return NO;
    }
}

- (BOOL)currentPlayerWatchQuickLive{
    return self.livePlayer.channelWatchQuickLive;
}

- (BOOL)channelWatchPublicStream {
    if (self.channelMatchExternal) {
        return self.currentExternalRoomData.menuInfo.watchPublicStream;
    } else {
        /// 当前PlayerPresenter的频道号，与外部频道号不一致
        /// 此时不允许执行观看公共流，因此[watchPublicStream]该值无意义，而恒为NO
        return NO;
    }
}

- (BOOL)noDelayWatchMode {
    return self.livePlayer.noDelayWatchMode;
}

- (BOOL)noDelayLiveWatching {
    return self.livePlayer.noDelayLiveWatching;
}

- (BOOL)quickLiveWatching {
    return self.livePlayer.quickLiveWatching;
}

- (BOOL)publicStreamWatching {
    return self.livePlayer.publicStreamWatching;
}

- (BOOL)audioMode {
    return self.livePlayer.audioMode;
}

- (UIImageView *)logoImageView {
    return self.logoView.logoImageView;
}

- (PLVDefaultPageView *)defaultPageView {
    if (!_defaultPageView) {
        _defaultPageView = [[PLVDefaultPageView alloc] init];
        _defaultPageView.delegate = self;
        _defaultPageView.hidden = YES;
    }
    return _defaultPageView;
}

#pragma mark Setter
- (void)setWarmUpHrefEnable:(BOOL)warmUpHrefEnable {
    _warmUpHrefEnable = warmUpHrefEnable;
    self.warmUpImageView.userInteractionEnabled = warmUpHrefEnable;
}

- (NSString *)videoId {
    return self.livePlaybackPlayer.videoId;
}

#pragma mark 通用
- (instancetype)initWithVideoType:(PLVChannelVideoType)videoType{
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    return [self initWithVideoType:videoType channelId:roomData.channelId vodId:roomData.vid vodList:roomData.vodList recordFile:roomData.recordFile recordEnable:roomData.recordEnable];
}

- (instancetype)initWithVideoType:(PLVChannelVideoType)videoType channelId:(NSString *)channelId vodId:(NSString *)vodId vodList:(BOOL)vodList recordFile:(PLVLiveRecordFileModel *)recordFile recordEnable:(BOOL)recordEnable {
    if (videoType != PLVChannelVideoType_Live && videoType != PLVChannelVideoType_Playback) {
        NSLog(@"PLVPlayerPresenter - initWithVideoType failed (videoType:%lu)",videoType);
        return nil;
    }
    
    if (![PLVFdUtil checkStringUseable:channelId]) {
        NSLog(@"PLVPlayerPresenter - initWithVideoType failed (channelId:%@)",channelId);
        return nil;
    }
    
    if (videoType == PLVChannelVideoType_Playback) {
        if (recordEnable && !recordFile) {
            NSLog( @"PLVPlayerPresenter - initWithVideoType failed (recordFile is nil)");
            return nil;
        } else if (!recordEnable && ![PLVFdUtil checkStringUseable:vodId]) {
            NSLog(@"PLVPlayerPresenter - initWithVideoType failed (vodId:%@)",vodId);
            return nil;
        }
    }
    
    self = [super init];
    if (self) {
        self.currentVideoType = videoType;
        self.channelId = channelId;
        self.vodId = vodId;
        self.vodList = vodList;
        self.recordFile = recordFile;
        self.fileId = recordFile.fileId;
        self.recordEnable = recordEnable;
        self.keepShowAdvert = YES;
        _defaultPageShowDuration = 15;
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
    
    if (self.channelWatchPublicStream) {
        [self.streamPlayer setupDisplaySuperview:self.playerBackgroundView];
    }else {
        [self.livePlayer setupDisplaySuperview:self.playerBackgroundView];
    }
    [self.livePlaybackPlayer setupDisplaySuperview:self.playerBackgroundView];
    
    self.defaultPageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.defaultPageView.frame = self.backgroundView.bounds;
}

- (void)setupScalingMode:(IJKMPMovieScalingMode)scalingMode {
    if (!self.livePlayer && !self.livePlaybackPlayer) {
        NSLog(@"PLVPlayerPresenter - %s failed, no player exsit",__FUNCTION__);
        return;
    }
    self.scalingMode = scalingMode;
    [self.livePlayer setupScalingMode:scalingMode];
    [self.livePlaybackPlayer setupScalingMode:scalingMode];
}

- (void)cleanPlayer{
    [self.livePlayer clearAllPlayer];
    [self.streamPlayer clearPlayer];
    [self.livePlaybackPlayer clearAllPlayer];
}

- (BOOL)resumePlay{
    if (self.advertPlaying) { // 片头广告显示中
        return NO;
    }
    
    if (self.currentVideoType == PLVChannelVideoType_Live) {
        // 修复频道未在开播状态时，主动调用resumePlay方法，导致的播放器异常问题
        if (self.currentStreamState == PLVChannelLiveStreamState_Live || self.currentStreamState == PLVChannelLiveStreamState_Stop) {
            [self.livePlayer reloadLivePlayer];
            if (self.publicStreamWatching) {
                [self.streamPlayer reloadStreamPlayer];
            }
        }
    } else if (self.currentVideoType == PLVChannelVideoType_Playback){
        [self.livePlaybackPlayer play];
    }
    [self.advertView hideStopAdvertView];
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerPresenterResumePlaying:)]) {
        [self.delegate playerPresenterResumePlaying:self];
    }
    return YES;
}

- (BOOL)pausePlay{
    if (self.currentVideoType == PLVChannelVideoType_Live) {
        // 修复频道未在开播状态时，主动调用pausePlay方法，导致的播放器异常问题
        if (self.currentStreamState == PLVChannelLiveStreamState_Live || self.currentStreamState == PLVChannelLiveStreamState_Stop) {
            [self.livePlayer pause];
            if (self.publicStreamWatching) {
                [self.streamPlayer stop];
            }
        }
    } else if (self.currentVideoType == PLVChannelVideoType_Playback){
        [self.livePlaybackPlayer pause];
    }
    return YES;
}

- (void)mute{
    [self.livePlayer mute];
    if (self.publicStreamWatching) {
        [self.streamPlayer pause];
    }
    [self.livePlaybackPlayer mute];
}

- (void)cancelMute{
    [self.livePlayer cancelMute];
    if (self.publicStreamWatching) {
        [self.streamPlayer resume];
    }
    [self.livePlaybackPlayer cancelMute];
}

#pragma mark 直播相关
- (void)switchLiveToAudioMode:(BOOL)audioMode{
    self.logoView.hidden = audioMode;
    self.defaultPageView.hidden = YES;
    [self.livePlayer switchToAudioMode:audioMode];
}

- (void)switchLiveToCodeRate:(NSString *)codeRate{
    self.defaultPageView.hidden = YES;
    [self.livePlayer switchToLineIndex:self.currentLineIndex codeRate:codeRate];
}

- (void)switchLiveToLineIndex:(NSInteger)lineIndex{
    self.defaultPageView.hidden = YES;
    [self.livePlayer switchToLineIndex:lineIndex codeRate:self.currentCodeRate];
}

- (void)switchToNoDelayWatchMode:(BOOL)noDelayWatchMode {
    if (self.channelWatchPublicStream) {
        if (noDelayWatchMode) {
            [self.streamPlayer reloadStreamPlayer];
        }else {
            [self.streamPlayer clearPlayer];
        }
    }
    self.defaultPageView.hidden = YES;
    [self.livePlayer switchToNoDelayWatchMode:noDelayWatchMode];
}

- (void)startPictureInPictureFromOriginView:(UIView *)originView {
    self.defaultPageView.hidden = YES;
    if (self.livePlayer) {
        [self.livePlayer startPictureInPictureFromOriginView:originView];
    } else if (self.livePlaybackPlayer) {
        [self.livePlaybackPlayer startPictureInPictureFromOriginView:originView];
    }
}

- (void)stopPictureInPicture {
    if (self.livePlayer) {
        [self.livePlayer stopPictureInPicture];
    } else if (self.livePlaybackPlayer) {
        [self.livePlaybackPlayer stopPictureInPicture];
    }
}

#pragma mark 非直播相关
- (void)seekLivePlaybackToTime:(NSTimeInterval)toTime{
    if (self.advertPlaying) { // 片头广告显示中
        return;
    }
    
    PLVLiveVideoChannelMenuInfo *menuInfo = [PLVRoomDataManager sharedManager].roomData.menuInfo;
    if ([menuInfo.playbackProgressBarOperationType isEqualToString:@"dragHistoryOnly"]) { // 对进度拖拽进行部分限制
        NSTimeInterval max = MAX(self.playbackMaxPosition, self.livePlaybackPlayer.currentPlaybackTime);
        if (toTime > max) { // 不符合允许拖拽的条件
            return;
        }
    } else if ([menuInfo.playbackProgressBarOperationType isEqualToString:@"dragHistoryOnly"]) {
        return;
    }
    
    [self.livePlaybackPlayer seekLivePlaybackToTime:toTime];
}

- (void)switchLivePlaybackSpeedRate:(CGFloat)toSpeed{
    if (self.advertPlaying) { // 片头广告显示中
        return;
    }
    
    [self.livePlaybackPlayer switchLivePlaybackSpeedRate:toSpeed];
}

- (void)changeVid:(NSString *)vid {
    self.currentLivePlaybackChangingVid = YES;
    [self.livePlaybackPlayer pause];
    [self.livePlaybackPlayer changeLivePlaybackVodId:vid];
    [self resumePlay];
}

- (void)changeFileId:(NSString *)fileId {
    [self.livePlaybackPlayer changeLivePlaybackFileId:fileId];
    [self resumePlay];
}

#pragma mark - [ Private Methods ]
- (void)setup{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(timerEvent:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)setupPlayer{
    NSString * userIdForAccount = [PLVLiveVideoConfig sharedInstance].userId;
    if (self.currentVideoType == PLVChannelVideoType_Live) { /// 直播
        self.livePlayer = [[PLVLivePlayer alloc] initWithPLVAccountUserId:userIdForAccount channelId:self.channelId];
        self.livePlayer.delegate = self;
        self.livePlayer.liveDelegate = self;
        self.livePlayer.pictureInPictureDelegate = self;
        self.livePlayer.channelWatchPublicStream = self.channelWatchPublicStream;
        self.livePlayer.channelWatchNoDelay = self.channelWatchNoDelay;
        self.livePlayer.channelWatchQuickLive = self.channelWatchQuickLive;
        [self.livePlayer setupDisplaySuperview:self.playerBackgroundView];
        self.livePlayer.videoToolBox = NO;
        self.livePlayer.chaseFrame = NO;
        
        if (self.channelWatchPublicStream) {
            [self setupPublicStreamPlayer];
        }
        
        self.livePlayer.customParam = self.currentExternalCustomParam;
    }else if (self.currentVideoType == PLVChannelVideoType_Playback){ /// 回放
        if (self.recordEnable) {
            self.livePlaybackPlayer = [[PLVLivePlaybackPlayer alloc] initWithPLVAccountUserId:userIdForAccount channelId:self.channelId recordFile:self.recordFile];
        } else {
            self.livePlaybackPlayer = [[PLVLivePlaybackPlayer alloc] initWithPLVAccountUserId:userIdForAccount channelId:self.channelId vodId:self.vodId vodList:self.vodList];
        }
        self.livePlaybackPlayer.delegate = self;
        self.livePlaybackPlayer.livePlaybackDelegate = self;
        self.livePlaybackPlayer.pictureInPictureDelegate = self;
        [self.livePlaybackPlayer setupDisplaySuperview:self.playerBackgroundView];

        self.livePlaybackPlayer.videoToolBox = NO;
        self.livePlaybackPlayer.customParam = self.currentExternalCustomParam;
    }
}

- (void)setupPublicStreamPlayer {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    PLVSocketManager *socketManager = [PLVSocketManager sharedManager];
    
    PLVPublicStreamGetInfoModel * getPublicStreamModel = [[PLVPublicStreamGetInfoModel alloc]init];
    getPublicStreamModel.channelId = roomData.channelId;
    getPublicStreamModel.userId = socketManager.linkMicId;
    getPublicStreamModel.channelType = roomData.channelType;
    getPublicStreamModel.viewerId = socketManager.viewerId;
    getPublicStreamModel.nickname = socketManager.viewerName;
    getPublicStreamModel.sessionId = roomData.sessionId;

    PLVRoomUserType currentUserViewerType = roomData.roomUser.viewerType;
    if (currentUserViewerType == PLVRoomUserTypeSlice || currentUserViewerType == PLVRoomUserTypeStudent) {
        getPublicStreamModel.userType = @"audience";
    }

    self.streamPlayer = [[PLVPublicStreamPlayer alloc]init];
    self.streamPlayer.delegate = self;
    [self.streamPlayer setupPlayerWith:getPublicStreamModel];
    [self.streamPlayer setupDisplaySuperview:self.playerBackgroundView];
    [self.streamPlayer play];
}

- (void)setupUI{
    [self.displayView addSubview:self.backgroundView];
    self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundView.frame = self.displayView.bounds;
    
    [self.backgroundView addSubview:self.playerBackgroundView];
    [self.backgroundView addSubview:self.warmUpImageView];
    [self.backgroundView addSubview:self.activityView];
    [self.backgroundView addSubview:self.loadSpeedLabel];
    [self.backgroundView addSubview:self.defaultPageView];
        
    self.playerBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.playerBackgroundView.frame = self.backgroundView.bounds;
    
    self.warmUpImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.warmUpImageView.frame = self.backgroundView.bounds;
        
    __weak typeof(self) weakSelf = self;
    self.backgroundView.layoutSubviewsBlock = ^(BOOL sizeAvailable) {
        weakSelf.logoView.frame = weakSelf.backgroundView.frame;
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

- (void)showTitleAdvert {
    /// 无延迟直播不显示片头广告
    if (self.channelWatchNoDelay) {
        return;
    }
    
    /// 正在直播中或回放
    if (self.channelInLive || self.currentVideoType == PLVChannelVideoType_Playback) {
        /// 替换广告视图
        [self.advertView setupDisplaySuperview:self.backgroundView];
        [self.advertView showTitleAdvert];
    }
}

- (void)setupPlayerLogoImage {
    [self.backgroundView addSubview:self.logoView];
}

- (void)savePlaybackLastTime {
    NSString *viewerId = self.currentExternalRoomData.roomUser.viewerId;
    NSMutableDictionary *infoDict = [[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultPlaybackLastTimeInfo] mutableCopy];
    NSMutableDictionary *lastTimeDict = [infoDict[viewerId] mutableCopy];
    if (!infoDict) {
        infoDict = [NSMutableDictionary dictionary];
    }
    if (!lastTimeDict) {
        lastTimeDict = [NSMutableDictionary dictionary];
    }
    if (self.recordEnable && [PLVFdUtil checkStringUseable:self.fileId]) {
        [lastTimeDict setObject:@(self.livePlaybackPlayer.currentPlaybackTime) forKey:self.fileId];
    } else if ([PLVFdUtil checkStringUseable:self.vodId]) {
        [lastTimeDict setObject:@(self.livePlaybackPlayer.currentPlaybackTime) forKey:self.vodId];
    }
    if ([PLVFdUtil checkStringUseable:viewerId]) {
        [infoDict setObject:lastTimeDict forKey:viewerId];
    }
    [[NSUserDefaults standardUserDefaults] setObject:infoDict forKey:kUserDefaultPlaybackLastTimeInfo];
}

- (void)seekLivePlaybackToLastTime {
    NSString *viewerId = self.currentExternalRoomData.roomUser.viewerId;
    NSMutableDictionary *infoDict = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultPlaybackLastTimeInfo];
    NSMutableDictionary *lastTimeDict = infoDict[viewerId];
    NSTimeInterval lastTime = 0;
    if (self.recordEnable && [PLVFdUtil checkStringUseable:self.fileId]) {
        lastTime = [lastTimeDict[self.fileId] doubleValue];
    } else if ([PLVFdUtil checkStringUseable:self.vodId]) {
        lastTime = [lastTimeDict[self.vodId] doubleValue];
    }
    if (lastTime != 0 && (self.livePlaybackPlayer.duration - lastTime) > 1) {
        [self seekLivePlaybackToTime:lastTime];
    }
}

- (NSTimeInterval)playbackMaxPosition {
    NSTimeInterval maxPosition = 0.0;
    NSString *viewerId = self.currentExternalRoomData.roomUser.viewerId;
    NSMutableDictionary *infoDict = [[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultPlaybackMaxPositionInfo] mutableCopy];
    NSMutableDictionary *maxPositionDict = [infoDict[viewerId] mutableCopy];
    if (maxPositionDict.count) {
        if (self.recordEnable && [PLVFdUtil checkStringUseable:self.fileId]) {
            maxPosition = [maxPositionDict[self.fileId] doubleValue];
        } else if ([PLVFdUtil checkStringUseable:self.vodId]) {
            maxPosition = [maxPositionDict[self.vodId] doubleValue];
        }
        if (isnan(maxPosition))
            maxPosition = 0.0;
    }
    return maxPosition;
}

- (void)setPlaybackMaxPosition:(NSTimeInterval)maxPosition {
    PLVLiveVideoChannelMenuInfo *menuInfo = [PLVRoomDataManager sharedManager].roomData.menuInfo;
    if ([menuInfo.playbackProgressBarOperationType isEqualToString:@"prohibitDrag"]) {
        return;
    }
    
    if (maxPosition <= 0 || maxPosition <= self.playbackMaxPosition) {
        return;
    }
    
    NSString *viewerId = self.currentExternalRoomData.roomUser.viewerId;
    NSMutableDictionary *infoDict = [[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultPlaybackMaxPositionInfo] mutableCopy];
    NSMutableDictionary *maxPositionDict = [infoDict[viewerId] mutableCopy];
    if (!infoDict) {
        infoDict = [NSMutableDictionary dictionary];
    }
    if (!maxPositionDict) {
        maxPositionDict = [NSMutableDictionary dictionary];
    }
    if (self.recordEnable && [PLVFdUtil checkStringUseable:self.fileId]) {
        [maxPositionDict setObject:@(self.livePlaybackPlayer.currentPlaybackTime) forKey:self.fileId];
    } else if ([PLVFdUtil checkStringUseable:self.vodId]) {
        [maxPositionDict setObject:@(self.livePlaybackPlayer.currentPlaybackTime) forKey:self.vodId];
    }
    if ([PLVFdUtil checkStringUseable:viewerId]) {
        [infoDict setObject:maxPositionDict forKey:viewerId];
    }
    [[NSUserDefaults standardUserDefaults] setObject:infoDict forKey:kUserDefaultPlaybackMaxPositionInfo];
}

- (void)startCountDownTimer{
    if (!self.countDownTimer) {
        self.countDownTime = self.defaultPageShowDuration;
        self.countDownTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                               target:[PLVFWeakProxy proxyWithTarget:self]
                                                             selector:@selector(countDownTimerEvent:)
                                                             userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.countDownTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)stopCountDownTimer {
    if (self.countDownTimer) {
        [self.countDownTimer invalidate];
        self.countDownTimer = nil;
    }
}

#pragma mark Getter
- (PLVRoomData *)currentExternalRoomData {
    return [PLVRoomDataManager sharedManager].roomData;
}

- (PLVViewLogCustomParam *)currentExternalCustomParam {
    return self.currentExternalRoomData.customParam;
}

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
        _warmUpImageView.userInteractionEnabled = NO;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(warmUpImageViewTapAction:)];
        [_warmUpImageView addGestureRecognizer:tap];
    }
    return _warmUpImageView;
}

- (PLVPlayerLogoView *)logoView {
    if (!_logoView) {
        PLVChannelInfoModel *channel = self.channelInfo;
        if ([PLVFdUtil checkStringUseable:channel.logoImageUrl]) {
            PLVPlayerLogoParam *logoParam = [[PLVPlayerLogoParam alloc] init];
            logoParam.logoUrl = channel.logoImageUrl;
            logoParam.position = channel.logoPosition;
            logoParam.logoAlpha = channel.logoOpacity;
            logoParam.logoHref = channel.logoHref;
            logoParam.logoWidthScale = 0.14;
            logoParam.logoHeightScale = 0.25;

            _logoView = [[PLVPlayerLogoView alloc] init];
            [_logoView insertLogoWithParam:logoParam];
        }
    }
    return _logoView;
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

- (PLVAdvertView *)advertView {
    if (!_advertView) {
        PLVChannelInfoModel *channelInfo = self.channelInfo;
        PLVAdvertParam *param = [[PLVAdvertParam alloc] init];
        param.advertType = channelInfo.advertType;
        param.advertImageUrl = channelInfo.advertImageUrl;
        param.advertFlvUrl = channelInfo.advertFlvUrl;
        param.advertHref = channelInfo.advertHref;
        param.advertDuration = channelInfo.advertDuration;
        param.stopAdvertImageUrl = channelInfo.stopAdvertImageUrl;
        param.stopAdvertHref = channelInfo.stopAdvertHref;
        
        _advertView = [[PLVAdvertView alloc] initWithParam:param];
        _advertView.delegate = self;
    }
    return _advertView;
}

- (PLVChannelInfoModel *)channelInfo {
    return self.currentExternalRoomData.channelInfo;
}

#pragma mark - [ Action ]
- (void)warmUpImageViewTapAction:(UITapGestureRecognizer *)gestureRecognizer {
    NSString *warmUpContentUrlString = self.channelInfo.warmUpImageHREF;
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:warmUpContentUrlString]];
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
}

- (void)countDownTimerEvent:(NSTimer *)timer{
    self.countDownTime--;
    if (self.countDownTime == 0) {
        [self stopCountDownTimer];
        if (self.currentVideoType == PLVChannelVideoType_Playback) {
            [self.defaultPageView showWithErrorMessage:PLVLocalizedString(@"视频加载缓慢，请刷新或退出重进") type:PLVDefaultPageViewTypeRefresh];
        } else {
            if (!self.quickLiveWatching) {
                [self.defaultPageView showWithErrorMessage:nil type:PLVDefaultPageViewTypeRefreshAndSwitchLine];
            }
        }
    }
}

#pragma mark - [ Delegate ]
#pragma mark PLVPlayerDelegate
/// 播放器加载前 回调options配置对象
- (PLVOptions *)plvPlayer:(PLVPlayer *)player playerWillLoad:(PLVPlayerMainSubType)mainSubType withOptions:(nonnull PLVOptions *)options{
    [self.activityView startAnimating];
    [self startCountDownTimer];
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
    [self stopCountDownTimer];
    self.defaultPageView.hidden = YES;
    [self timerEvent:nil];
    self.currentLivePlaybackChangingVid = NO;
    
    if (self.keepShowAdvert && self.channelInfo.advertType != PLVChannelAdvertType_None) {
        self.keepShowAdvert = NO;
        [self showTitleAdvert];
        return;
    }
    
    if (self.currentVideoType == PLVChannelVideoType_Playback) {
        [self seekLivePlaybackToLastTime];
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
                    [weakSelf startCountDownTimer];
                }
            });
        } else {
            if (player.mainPlayerLoadState & IJKMPMovieLoadStatePlaythroughOK) {
                [self stopCountDownTimer];
            }
            self.needShowLoading = NO;
            [self.activityView stopAnimating];
        }
    }
}

/// 播放器 ’播放状态‘ 发生改变
- (void)plvPlayer:(PLVPlayer *)player playerPlaybackStateDidChange:(PLVPlayerMainSubType)mainSubType {
    /// 处理回放播放拖动后立即暂停情况引起的播放结束未改变 “是否正在播放中” 状态的情况
    if (mainSubType != PLVPlayerMainSubType_Main) {
        return;
    }
    if (player.mainPlayerPlaybackState == IJKMPMoviePlaybackStatePaused &&
        [PLVRoomDataManager sharedManager].roomData.playing &&
        self.currentVideoType == PLVChannelVideoType_Playback) {
        [PLVRoomDataManager sharedManager].roomData.playing = NO;
        if ([self.delegate respondsToSelector:@selector(playerPresenter:playerPlayingStateDidChanged:)]) {
            [self.delegate playerPresenter:self playerPlayingStateDidChanged:NO];
        }
    }
}

/// 播放器 ’是否正在播放中‘状态 发生改变
- (void)plvPlayer:(PLVPlayer *)player playerPlayingStateDidChange:(PLVPlayerMainSubType)mainSubType playing:(BOOL)playing{
    if (mainSubType != PLVPlayerMainSubType_Main) {
        return;
    }
    if (player.mainPlayerPlaybackState != IJKMPMoviePlaybackStateSeekingForward &&
        player.mainPlayerPlaybackState != IJKMPMoviePlaybackStateSeekingBackward) {
        [PLVRoomDataManager sharedManager].roomData.playing = playing;
        if (playing && !self.defaultPageView.hidden) {
            self.defaultPageView.hidden = YES;
        }
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
            ///回放播放拖动情况引起的播放结束未改变 “是否正在播放中” 状态的情况
            if ([PLVRoomDataManager sharedManager].roomData.playing) {
                [PLVRoomDataManager sharedManager].roomData.playing = NO;
                if ([self.delegate respondsToSelector:@selector(playerPresenter:playerPlayingStateDidChanged:)]) {
                    [self.delegate playerPresenter:self playerPlayingStateDidChanged:NO];
                }
            }

            if ([self.delegate respondsToSelector:@selector(playerPresenter:downloadProgress:playedProgress:playedTimeString:durationTimeString:)]) {
                [self.delegate playerPresenter:self downloadProgress:0 playedProgress:1 playedTimeString:self.livePlaybackPlayer.playedTimeString durationTimeString:self.livePlaybackPlayer.durationTimeString];
                
                ///回放列表播放结束自动播放下一回放
                PLVPlaybackListModel *playbackList = self.channelMatchExternal ? self.currentExternalRoomData.playbackList : nil;
                if (playbackList.totalItems > 1 && [playbackList.contents count] > 1) {
                    for (int i = 0; i < playbackList.totalItems; i++) {
                        if ([[PLVRoomDataManager sharedManager].roomData.vid isEqualToString:playbackList.contents[i].videoPoolId]) {
                            PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
                            PLVPlaybackVideoModel *videoModel = (i == (playbackList.totalItems - 1)) ? playbackList.contents.firstObject: playbackList.contents[i + 1];
                            roomData.vid = videoModel.videoPoolId;
                            roomData.videoId = videoModel.videoId;
                            roomData.playbackSessionId = videoModel.channelSessionId;
                            break;
                        }
                    }
                }
                
                /// 断网导致播放停止的情况
                if (self.duration - self.currentPlaybackTime >= 1) {
                    if (self.delegate && [self.delegate respondsToSelector:@selector(playerPresenterPlaybackInterrupted:)]) {
                        [self.delegate playerPresenterPlaybackInterrupted:self];
                    }
                }
            }
        }
    } else if (finishReson == IJKMPMovieFinishReasonPlaybackError) {
        errorMessage = PLVLocalizedString(@"视频播放失败，请尝试手动刷新，或退出重新登录");
        [self.activityView stopAnimating];
        if (self.currentVideoType == PLVChannelVideoType_Playback) {
            [self.defaultPageView showWithErrorMessage:PLVLocalizedString(@"视频加载缓慢，请刷新或退出重进") type:PLVDefaultPageViewTypeRefresh];
        } else {
            if (!self.quickLiveWatching) {
                [self.defaultPageView showWithErrorMessage:nil type:PLVDefaultPageViewTypeRefreshAndSwitchLine];
            }
        }
        
        
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
    [self stopCountDownTimer];
    self.defaultPageView.hidden = YES;
}

#pragma mark PLVLivePlayerDelegate
/// 直播播放器 ‘加载状态’ 发生改变
- (void)plvLivePlayer:(PLVLivePlayer *)livePlayer loadStateDidChanged:(PLVLivePlayerLoadState)loadState{

}

/// 直播播放器 ‘流状态’ 更新
- (void)plvLivePlayer:(PLVLivePlayer *)livePlayer streamStateUpdate:(PLVChannelLiveStreamState)newestStreamState streamStateDidChanged:(BOOL)streamStateDidChanged{
    PLVChannelLiveStreamState lastState = [PLVRoomDataManager sharedManager].roomData.liveState;
    [PLVRoomDataManager sharedManager].roomData.liveState = newestStreamState;
    if (newestStreamState == PLVChannelLiveStreamState_Live) {
        [self setupPlayerLogoImage];
        if (self.publicStreamWatching && lastState != PLVChannelLiveStreamState_Live) {
            [self.streamPlayer reloadStreamPlayer];
        }
    } else {
        [self.logoView removeFromSuperview];
        if (self.publicStreamWatching && (newestStreamState == PLVChannelLiveStreamState_End || newestStreamState == PLVChannelLiveStreamState_Stop)) {
            [self.streamPlayer clearPlayer];
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(playerPresenter:streamStateUpdate:streamStateDidChanged:)]) {
        [self.delegate playerPresenter:self streamStateUpdate:newestStreamState streamStateDidChanged:streamStateDidChanged];
    }
    
    if (livePlayer.noDelayLiveWatching) {
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
    
    if (error.code == [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeChannelRestrict_PlayRestrict]) {
        [self.defaultPageView showWithErrorCode:error.code message:PLVLocalizedString(@"存在观看限制，暂不支持进入") type:PLVDefaultPageViewTypeErrorCode];
    } else if ((error.code >= [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetChannelInfo_RequestFailed] &&
                error.code <= [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetChannelInfo_CodeError]) ||
               error.code == [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeChannelRestrict_RequestFailed] ||
               error.code == [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetChannelInfo_ParameterError] ||
               (error.code >= [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetStreamState_ParameterError] &&
                           error.code <= [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetSessionID_ParameterError])){
        [self.defaultPageView showWithErrorCode:error.code message:nil type:PLVDefaultPageViewTypeErrorCode];

    } else {
        [self.defaultPageView showWithErrorMessage:nil type:PLVDefaultPageViewTypeRefresh];
    }
}

/// 直播播放器 ‘频道信息’ 发生改变
- (void)plvLivePlayer:(PLVLivePlayer *)livePlayer channelInfoDidUpdated:(PLVChannelInfoModel *)channelInfo{
    [PLVRoomDataManager sharedManager].roomData.playerChannelInfo = channelInfo;
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

- (BOOL)plvLivePlayerGetPausedWatchNoDelay:(PLVLivePlayer *)livePlayer {
    if (self.publicStreamWatching) {
        return self.streamPlayer ? self.streamPlayer.streamPlaying : NO;
    }
    if ([self.delegate respondsToSelector:@selector(playerPresenterGetPausedWatchNoDelay:)]) {
        return [self.delegate playerPresenterGetPausedWatchNoDelay:self];
    }else{
        return NO;
    }
}

/// 直播播放器 需展示暖场图片
- (void)plvLivePlayer:(PLVLivePlayer *)livePlayer showWarmUpImage:(BOOL)show warmUpImageURLString:(NSString *)warmUpImageURLString{
    if (show) {
        self.warmUpImageView.hidden = NO;
        if ([warmUpImageURLString containsString:@".gif"]) {
            [[SDWebImageDownloader sharedDownloader]downloadImageWithURL:[NSURL URLWithString:warmUpImageURLString] options:SDWebImageDownloaderUseNSURLCache progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                if (finished) {
                    UIImage *imageData = [UIImage imageWithData:data];
                    [self.warmUpImageView setImage:imageData];
                } else {
                    self.warmUpImageView.image = nil;
                }
            }];
        } else {
            [self.warmUpImageView sd_setImageWithURL:[NSURL URLWithString:warmUpImageURLString] placeholderImage:nil options:SDWebImageRetryFailed];
        }
        NSString *warmUpImageHREF = self.currentChannelInfo.warmUpImageHREF;
        if ([PLVFdUtil checkStringUseable:warmUpImageHREF]) {
            self.warmUpImageView.userInteractionEnabled = YES;
        }
    }else{
        self.warmUpImageView.hidden = YES;
    }
}

/// 直播播放器（快直播）网络质量回调
- (void)plvLivePlayer:(PLVLivePlayer *)livePlayer quickLiveNetworkQuality:(PLVLivePlayerQuickLiveNetworkQuality)netWorkQuality {
    if (self.networkQuality == netWorkQuality) {
        self.networkQualityRepeatCount ++;
    }
    self.networkQuality = netWorkQuality;
    if (self.networkQualityRepeatCount == 2) {
        self.networkQualityRepeatCount = 0;
        self.networkQuality = PLVLivePlayerQuickLiveNetworkQuality_NoConnection;
        if (self.delegate && [self.delegate respondsToSelector:@selector(playerPresenter:quickLiveNetworkQuality:)]) {
            [self.delegate playerPresenter:self quickLiveNetworkQuality:netWorkQuality];
        }
    }
}

#pragma mark PLVLivePlayerPictureInPictureDelegate
- (void)plvLivePlayerPictureInPictureWillStart:(PLVPlayer<PLVLivePlayerPictureInPictureProtocol> *)livePlayer {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerPresenterPictureInPictureWillStart:)]) {
        [self.delegate playerPresenterPictureInPictureWillStart:self];
    }
}

- (void)plvLivePlayerPictureInPictureDidStart:(PLVPlayer<PLVLivePlayerPictureInPictureProtocol> *)livePlayer {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerPresenterPictureInPictureDidStart:)]) {
        [self.delegate playerPresenterPictureInPictureDidStart:self];
    }
}

- (void)plvLivePlayer:(PLVPlayer<PLVLivePlayerPictureInPictureProtocol> *)livePlayer pictureInPictureFailedToStartWithError:(NSError *)error {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerPresenter:pictureInPictureFailedToStartWithError:)]) {
        [self.delegate playerPresenter:self pictureInPictureFailedToStartWithError:error];
    }
}

- (void)plvLivePlayerPictureInPictureWillStop:(PLVPlayer<PLVLivePlayerPictureInPictureProtocol> *)livePlayer {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerPresenterPictureInPictureWillStop:)]) {
        [self.delegate playerPresenterPictureInPictureWillStop:self];
    }
}

- (void)plvLivePlayerPictureInPictureDidStop:(PLVPlayer<PLVLivePlayerPictureInPictureProtocol> *)livePlayer {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerPresenterPictureInPictureDidStop:)]) {
        [self.delegate playerPresenterPictureInPictureDidStop:self];
    }
}

-(void)plvLivePlayer:(PLVPlayer<PLVLivePlayerPictureInPictureProtocol> *)livePlayer pictureInPicturePlayerPlayingStateDidChange:(BOOL)playing {
    [PLVRoomDataManager sharedManager].roomData.playing = playing;
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerPresenter:pictureInPicturePlayerPlayingStateDidChange:)]) {
        [self.delegate playerPresenter:self pictureInPicturePlayerPlayingStateDidChange:playing];
    }    
}

-(void)plvLivePlayer:(PLVPlayer<PLVLivePlayerPictureInPictureProtocol> *)livePlayer pictureInPicturePlayerPlayingStateDidChange:(BOOL)playing systemInterrupts:(BOOL)systemInterrupts{
    
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
    } else if ((error.code >= [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeChannelRestrict_PlayRestrict] &&
                error.code <= [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeChannelRestrict_RequestFailed])) {
     /// 限制信息
     message = [NSString stringWithFormat:@"%ld %@",(long)error.code,error.localizedDescription];
 }
    
    if ([self.delegate respondsToSelector:@selector(playerPresenter:loadPlayerFailureWithMessage:)] &&
        [PLVFdUtil checkStringUseable:message]) {
        [self.delegate playerPresenter:self loadPlayerFailureWithMessage:message];
    }
    
    if (error.code == [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetVideoInfo_DataError] ||
        error.code == [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetVideoInfo_FileUrlError] ||
        error.code == [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetVideoInfo_ParameterError] ||
        error.code == [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeChannelRestrict_RequestFailed]) {
        [self.defaultPageView showWithErrorCode:error.code message:nil type:PLVDefaultPageViewTypeErrorCode];
    } else if (error.code == [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetVideoInfo_CodeError] ||
               error.code == [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeGetVideoInfo_RequestFailed]){
        [self.defaultPageView showWithErrorMessage:nil type:PLVDefaultPageViewTypeRefresh];
    } else if (error.code == [PLVFPlayErrorCodeGenerator errorCode:PLVFPlayErrorCodeChannelRestrict_PlayRestrict]) {
        [self.defaultPageView showWithErrorCode:error.code message:PLVLocalizedString(@"存在观看限制，暂不支持进入") type:PLVDefaultPageViewTypeErrorCode];
    }
}

/// 直播回放播放器 需获知外部 ‘当前本地缓存’
- (PLVPlaybackLocalVideoInfoModel *)plvLivePlaybackPlayerGetPlaybackCache:(PLVLivePlaybackPlayer *)livePlaybackPlayer videoId:(NSString * _Nullable)videoId channelId:(NSString * _Nullable)channelId listType:(NSString * _Nullable)listType isRecord:(BOOL)isRecord {
    if (![PLVFdUtil checkStringUseable:videoId]) {
        return nil;
    }
    PLVDownloadPlaybackTaskInfo *taskInfo = [[PLVDownloadPlaybackTaskInfo alloc] init];
    if (isRecord) {
        taskInfo = [[PLVDownloadDatabaseManager shareManager] checkAndGetPlaybackTaskInfoWithFileId:videoId];
    } else {
        taskInfo = [[PLVDownloadDatabaseManager shareManager] checkAndGetPlaybackTaskInfoWithVideoPoolId:videoId];
    }
    if (taskInfo && taskInfo.state == PLVDownloadStateSuccess) {
        PLVPlaybackLocalVideoInfoModel *localPlayerModel = [PLVPlaybackCacheManager toPlaybackPlayerModel:taskInfo];
        return localPlayerModel;
    } else {
        return nil;
    }
}

/// 直播回放播放器 定时返回当前播放进度
- (void)plvLivePlaybackPlayer:(PLVLivePlaybackPlayer *)livePlaybackPlayer downloadProgress:(CGFloat)downloadProgress playedProgress:(CGFloat)playedProgress playedTimeString:(NSString *)playedTimeString durationTimeString:(NSString *)durationTimeString{
    if ([self.delegate respondsToSelector:@selector(playerPresenter:downloadProgress:playedProgress:playedTimeString:durationTimeString:)]) {
        [self.delegate playerPresenter:self downloadProgress:downloadProgress playedProgress:playedProgress playedTimeString:playedTimeString durationTimeString:durationTimeString];
    }
    if (!self.currentLivePlaybackChangingVid) {
        [self savePlaybackLastTime];
        [self setPlaybackMaxPosition:self.livePlaybackPlayer.currentPlaybackTime];
    }
}

/// 直播回放播放器 ‘频道信息’ 发生改变
- (void)plvLivePlaybackPlayer:(PLVLivePlaybackPlayer *)livePlaybackPlayer channelInfoDidUpdated:(PLVChannelInfoModel *)channelInfo {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    roomData.playerChannelInfo = channelInfo;
    if ([self.delegate respondsToSelector:@selector(playerPresenter:channelInfoDidUpdated:)]) {
        [self.delegate playerPresenter:self channelInfoDidUpdated:channelInfo];
    }
    /// 设置播放器LOGO
    [self setupPlayerLogoImage];
}

/// 直播回放播放器 ‘回放视频信息’ 发生改变
- (void)plvLivePlaybackPlayer:(PLVLivePlaybackPlayer *)livePlaybackPlayer playbackVideoInfoDidUpdated:(PLVPlaybackVideoInfoModel *)playbackVideoInfo {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    roomData.playbackVideoInfo = playbackVideoInfo;
    self.vodId = playbackVideoInfo.vid;
    self.recordEnable = ![PLVFdUtil checkStringUseable:playbackVideoInfo.videoPoolId];
    self.fileId = playbackVideoInfo.fileId;
    if (!roomData.playbackSessionId) {
        roomData.playbackSessionId = playbackVideoInfo.channelSessionId;
    }
    if ([self.delegate respondsToSelector:@selector(playerPresenter:playbackVideoInfoDidUpdated:)]) {
        [self.delegate playerPresenter:self playbackVideoInfoDidUpdated:playbackVideoInfo];
    }
}

#pragma mark PLVAdvertViewDelegate

- (void)plvAdvertView:(PLVAdvertView *)advertView playStateDidChange:(PLVAdvertViewPlayState)state {
    if (state == PLVAdvertViewPlayStatePlay) {
        [self pausePlay];
        if ([self.delegate respondsToSelector:@selector(playerPresenter:advertViewPlayingStateDidChanged:)]) {
            [self.delegate playerPresenter:self advertViewPlayingStateDidChanged:YES];
        }
    } else if (state == PLVAdvertViewPlayStateFinish) {
        if (!self.keepShowAdvert) {
            [self.advertView destroyTitleAdvert];
            [self resumePlay];
            if (self.currentVideoType == PLVChannelVideoType_Playback) {
                [self seekLivePlaybackToLastTime];
                if ([self.delegate respondsToSelector:@selector(playerPresenter:videoSizeChange:)]) {
                    [self.delegate playerPresenter:self videoSizeChange:self.livePlaybackPlayer.naturalSize];
                }
            }
            if ([self.delegate respondsToSelector:@selector(playerPresenter:advertViewPlayingStateDidChanged:)]) {
                [self.delegate playerPresenter:self advertViewPlayingStateDidChanged:NO];
            }
        }
    }
}

- (void)plvAdvertView:(PLVAdvertView *)advertView clickStartAdvertWithHref:(NSURL *)advertHref {
    [[UIApplication sharedApplication] openURL:advertHref];
}

#pragma mark PLVPublicStreamPlayerDelegate
- (void)plvPublicStreamPlayer:(PLVPublicStreamPlayer *)streamPlayer streamPlayerPlayingStateDidChange:(BOOL)playing {
    [PLVRoomDataManager sharedManager].roomData.playing = playing;
    if (playing) {
        self.defaultPageView.hidden = YES;
        self.warmUpImageView.hidden = YES;
    }
    
    if ([self.delegate respondsToSelector:@selector(playerPresenter:playerPlayingStateDidChanged:)]) {
        [self.delegate playerPresenter:self playerPlayingStateDidChanged:playing];
    }
}

/// 公共流播放器（公共流）网络质量回调
- (void)plvPublicStreamPlayer:(PLVPublicStreamPlayer *)streamPlayer publicStreamNetworkQuality:(PLVPublicStreamPlayerNetworkQuality)netWorkQuality {
    if (self.publicStreamNetworkQuality == netWorkQuality) {
        self.publicStreamNetworkQualityRepeatCount ++;
    }
    self.publicStreamNetworkQuality = netWorkQuality;
    if (self.publicStreamNetworkQualityRepeatCount == 2) {
        self.publicStreamNetworkQualityRepeatCount = 0;
        self.publicStreamNetworkQuality = PLVPublicStreamPlayerNetworkQuality_NoConnection;
        if (self.delegate && [self.delegate respondsToSelector:@selector(playerPresenter:publicStreamNetworkQuality:)]) {
            [self.delegate playerPresenter:self publicStreamNetworkQuality:netWorkQuality];
        }
    }
}

- (void)plvPublicStreamPlayer:(PLVPublicStreamPlayer *)streamPlayer videoSize:(CGSize)videoSize {
    if ([self.delegate respondsToSelector:@selector(playerPresenter:videoSizeChange:)]) {
        [self.delegate playerPresenter:self videoSizeChange:videoSize];
    }
}

#pragma mark PLVDefaultPageViewDelegate

- (void)plvDefaultPageViewWannaRefresh:(PLVDefaultPageView *)defaultPageView {
    self.defaultPageView.hidden = YES;
    [self resumePlay];
}

- (void)plvDefaultPageViewWannaSwitchLine:(PLVDefaultPageView *)defaultPageView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerPresenterWannaSwitchLine:)]) {
        [self.delegate playerPresenterWannaSwitchLine:self];
    }
}

@end

@implementation PLVPlayerPresenterBackgroundView

- (void)layoutSubviews{
    BOOL sizeAvailable = !CGSizeEqualToSize(self.frame.size, CGSizeZero);
    if (self.layoutSubviewsBlock) { self.layoutSubviewsBlock(sizeAvailable); }
}

@end
