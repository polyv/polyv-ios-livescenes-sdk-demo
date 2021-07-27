//
//  PLVECHomePageView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/1/22.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVECHomePageView.h"

// 模块
#import "PLVRoomDataManager.h"
#import "PLVECChatroomViewModel.h"
#import "PLVECBulletinView.h"
#import "PLVECCommodityViewController.h"
#import "PLVECCommodityPushView.h"
#import "PLVECGiftView.h"
#import "PLVECRewardController.h"
#import <PLVLiveScenesSDK/PLVSocketManager.h>

// UI
#import "PLVECLiveRoomInfoView.h"
#import "PLVECChatroomView.h"
#import "PLVECLikeButtonView.h"
#import "PLVECPlayerContolView.h"
#import "PLVECMoreView.h"
#import "PLVECSwitchView.h"

// 工具
#import "PLVECUtils.h"
#import <PLVFoundationSDK/PLVFdUtil.h>

// 依赖库

/// SwitchView类型
typedef NS_ENUM(NSInteger, PLVECSwitchViewType) {
    /// SwitchView类型为 未知
    PLVECSwitchViewType_Unknown = 0,
    /// SwitchView类型为 切换线路
    PLVECSwitchViewType_Line = 1,
    /// SwitchView类型为 切换码率
    PLVECSwitchViewType_CodeRate = 2,
    /// SwitchView类型为 切换速率
    PLVECSwitchViewType_Speed = 4
};

@interface PLVECHomePageView ()<
PLVPlayerContolViewDelegate,
PLVECMoreViewDelegate,
PLVPlayerSwitchViewDelegate,
PLVECCommodityDelegate,
PLVECCommodityPushViewDelegate,
PLVSocketManagerProtocol
>

#pragma mark 数据

@property (nonatomic, weak) id<PLVECHomePageViewDelegate> delegate;
@property (nonatomic, assign) PLVECHomePageType type;
@property (nonatomic, assign) PLVECSwitchViewType switchViewType;
/// 直播特有属性
@property (nonatomic, copy) NSArray<NSString *> *codeRateItems;        // 当前直播支持码率列表
@property (nonatomic, assign) NSUInteger curCodeRateIndex;             // 当前直播播放码率
@property (nonatomic, assign) NSUInteger lineCount;                    // 当前直播支持切换线路数
@property (nonatomic, assign) NSUInteger curlineIndex;                 // 当前直播所选线路
@property (nonatomic, assign) BOOL audioMode;                          // 音频模式，默认NO-视频模式
@property (nonatomic, assign) BOOL hiddenCodeRateSwitch;               // 是否显示切换码率按钮
@property (nonatomic, assign) BOOL isPlaying;
/// 回放特有属性
@property (nonatomic, assign) NSTimeInterval duration;                 // 回放视频时长
@property (nonatomic, assign) NSUInteger curSpeedIndex;                // 回放视频当前播放速率

#pragma mark 模块

@property (nonatomic, strong) PLVECMoreView *moreView;                 // 更多视图
@property (nonatomic, strong) PLVECSwitchView *switchView;             // 切换视图
@property (nonatomic, strong) PLVECGiftView *giftView;                 // 礼物视图
@property (nonatomic, strong) PLVECRewardController *rewardCtrl;       // 打赏控制器
@property (nonatomic, weak) PLVECCommodityViewController *commodityVC; // 商品视图
@property (nonatomic, strong) PLVECCommodityPushView *pushView;        // 商品推送视图

#pragma mark UI

@property (nonatomic, strong) PLVECLiveRoomInfoView *liveRoomInfoView; // 直播详情视图
@property (nonatomic, strong) PLVECChatroomView *chatroomView;         // 聊天室视图
@property (nonatomic, strong) PLVECLikeButtonView *likeButtonView;     // 点赞视图
@property (nonatomic, strong) PLVECPlayerContolView *playerContolView; // 视频播放控制视图
@property (nonatomic, strong) UIButton *moreButton;                    // 更多按钮
@property (nonatomic, strong) UIButton *giftButton;                    // 送礼按钮
@property (nonatomic, strong) UIButton *shoppingCartButton;            // 购物车按钮

@end

@implementation PLVECHomePageView {
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
}

#pragma mark - Life Cycle

- (instancetype)initWithType:(PLVECHomePageType)type delegate:(id<PLVECHomePageViewDelegate>)delegate {
    self = [super init];
    if (self) {
        self.type = type;
        self.delegate = delegate;
        self.curSpeedIndex = 1;
        
        [self setupUI];
        
        socketDelegateQueue = dispatch_get_main_queue();
        [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
    }
    return self;
}

#pragma mark - Override

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.liveRoomInfoView.frame = CGRectMake(15, 10, 118, 36);
    
    CGFloat buttonWidth = 32.f;
    if (self.type == PLVECHomePageType_Live) {
        // 聊天室布局
        self.chatroomView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)-P_SafeAreaBottomEdgeInsets());
        // 底部按钮
        self.moreButton.frame = CGRectMake(CGRectGetWidth(self.bounds)-buttonWidth-15, CGRectGetHeight(self.bounds)-buttonWidth-15-P_SafeAreaBottomEdgeInsets(), buttonWidth, buttonWidth);
        self.giftButton.frame = CGRectMake(CGRectGetMinX(self.moreButton.frame)-48, CGRectGetMinY(self.moreButton.frame), buttonWidth, buttonWidth);
        self.shoppingCartButton.frame = CGRectMake(CGRectGetMinX(self.giftButton.frame)-48, CGRectGetMinY(self.moreButton.frame), buttonWidth, buttonWidth);
        // 点赞按钮
        self.likeButtonView.frame = CGRectMake(CGRectGetMinX(self.moreButton.frame), CGRectGetMinY(self.moreButton.frame)-PLVECLikeButtonViewHeight-5, PLVECLikeButtonViewWidth, PLVECLikeButtonViewHeight);
    } else if (self.type == PLVECHomePageType_Playback) {
        // 底部控件
        self.moreButton.frame = CGRectMake(CGRectGetWidth(self.bounds)-buttonWidth-15, CGRectGetHeight(self.bounds)-buttonWidth-15-P_SafeAreaBottomEdgeInsets(), buttonWidth, buttonWidth);
        self.playerContolView.frame = CGRectMake(0, CGRectGetHeight(self.bounds)-41-P_SafeAreaBottomEdgeInsets(), CGRectGetMinX(self.moreButton.frame)-8, 41);
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _moreView.hidden = YES;
    _switchView.hidden = YES;
    [_rewardCtrl hiddenView:YES];
}

#pragma mark - Initialize

- (void)setupUI {
    [self addSubview:self.liveRoomInfoView];
    
    if (self.type == PLVECHomePageType_Live) {
        [self addSubview:self.chatroomView];
        [self addSubview:self.likeButtonView];
        [self addSubview:self.giftButton];
        [self addSubview:self.shoppingCartButton];
    } else if (self.type == PLVECHomePageType_Playback) {
        [self addSubview:self.playerContolView];
    }
    
    [self addSubview:self.moreButton];
}

#pragma mark - Getter & Setter

- (PLVECLiveRoomInfoView *)liveRoomInfoView {
    if (!_liveRoomInfoView) {
        _liveRoomInfoView = [[PLVECLiveRoomInfoView alloc] init];
    }
    return _liveRoomInfoView;
}

- (PLVECChatroomView *)chatroomView {
    if (!_chatroomView) {
        _chatroomView = [[PLVECChatroomView alloc] init];
    }
    return _chatroomView;
}

- (PLVECLikeButtonView *)likeButtonView {
    if (!_likeButtonView) {
        _likeButtonView = [[PLVECLikeButtonView alloc] init];
        _likeButtonView.likeCount = [PLVRoomDataManager sharedManager].roomData.likeCount;
        [_likeButtonView startTimer];
        _likeButtonView.didTapLikeButton = ^{
            [[PLVECChatroomViewModel sharedViewModel] sendLike];
        };
    }
    return _likeButtonView;
}

- (PLVECPlayerContolView *)playerContolView {
    if (!_playerContolView) {
        _playerContolView = [[PLVECPlayerContolView alloc] init];
        _playerContolView.delegate = self;
    }
    return _playerContolView;
}

- (UIButton *)moreButton {
    if (!_moreButton) {
        _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_moreButton setImage:[PLVECUtils imageForWatchResource:@"plv_more_btn"] forState:UIControlStateNormal];
        [_moreButton addTarget:self action:@selector(moreButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _moreButton;
}

- (UIButton *)giftButton {
    if (!_giftButton) {
        _giftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_giftButton setImage:[PLVECUtils imageForWatchResource:@"plv_gift_btn"] forState:UIControlStateNormal];
        [_giftButton addTarget:self action:@selector(giftButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _giftButton;
}

- (UIButton *)shoppingCartButton {
    if (!_shoppingCartButton) {
        _shoppingCartButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_shoppingCartButton setImage:[PLVECUtils imageForWatchResource:@"plv_shoppingCard_btn"] forState:UIControlStateNormal];
        [_shoppingCartButton addTarget:self action:@selector(shoppingCardButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _shoppingCartButton.hidden = YES;
    }
    return _shoppingCartButton;
}

- (PLVECMoreView *)moreView {
    if (!_moreView) {
        CGFloat height = 130 + P_SafeAreaBottomEdgeInsets();
        _moreView = [[PLVECMoreView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.bounds)-height, CGRectGetWidth(self.bounds), height)];
        _moreView.delegate = self;
        _moreView.hidden = YES;
        [self addSubview:_moreView];
    }
    return _moreView;
}

- (PLVECSwitchView *)switchView {
    if (!_switchView) {
        _switchView = [[PLVECSwitchView alloc] initWithFrame:self.moreView.frame];
        _switchView.delegate = self;
        [self addSubview:_switchView];
    }
    return _switchView;
}

- (PLVECGiftView *)giftView {
    if (!_giftView) {
        CGRect rect = CGRectMake(-270, CGRectGetHeight(self.bounds)-335-P_SafeAreaBottomEdgeInsets(), 270, 40);
        _giftView = [[PLVECGiftView alloc] initWithFrame:rect];
        [self addSubview:_giftView];
    }
    return _giftView;
}

- (PLVECRewardController *)rewardCtrl {
    if (!_rewardCtrl) {
        _rewardCtrl = [[PLVECRewardController alloc] init];
        __weak typeof(self) weakSelf = self;
        _rewardCtrl.didSendGift = ^(NSString * _Nonnull giftName, NSString * _Nonnull giftType) {
            PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
            [weakSelf.giftView showGiftAnimation:roomUser.viewerName giftName:giftName giftType:giftType];
        };
        
        CGFloat height = 258 + P_SafeAreaBottomEdgeInsets();
        _rewardCtrl.view = [[PLVECRewardView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.bounds)-height, CGRectGetWidth(self.bounds), height)];
        [self addSubview:_rewardCtrl.view];
    }
    return _rewardCtrl;
}

- (PLVECCommodityPushView *)pushView {
    if (!_pushView) {
        _pushView = [[PLVECCommodityPushView alloc] initWithFrame:CGRectMake(16, CGRectGetMinY(self.shoppingCartButton.frame)-90, CGRectGetWidth(self.bounds)-110, 86)];
        _pushView.delegate = self;
        [self addSubview:_pushView];
    }
    return _pushView;
}

#pragma mark - Public

- (void)destroy {
    [_pushView destroy];
    if (self.type == PLVECHomePageType_Live) {
        [_likeButtonView invalidTimer];
        [[PLVECChatroomViewModel sharedViewModel] clear];
    }
}

- (void)showShoppingCart:(BOOL)show {
    self.shoppingCartButton.hidden = !show;
}

- (void)updateChannelInfo:(NSString *)publisher coverImage:(NSString *)coverImage {
    self.liveRoomInfoView.publisherLB.text = publisher;
    [PLVFdUtil setImageWithURL:[NSURL URLWithString:coverImage]
                   inImageView:self.liveRoomInfoView.coverImageView
                     completed:nil];
}

- (void)updateRoomInfoCount:(NSUInteger)roomInfoCount {
    self.liveRoomInfoView.pageViewLB.text = [NSString stringWithFormat:@"%lu",(unsigned long)roomInfoCount];
}

- (void)updateLikeCount:(NSUInteger)likeCount {
    self.likeButtonView.likeCount = likeCount;
}

- (void)updatePlayerState:(BOOL)playing {
    if (self.type == PLVECHomePageType_Live) {
        self.isPlaying = playing;
        if (!playing) {
            _moreView.hidden = YES;
            _switchView.hidden = YES;
        }
    } else if (self.type == PLVECHomePageType_Playback) {
        if (!self.playerContolView.sliderDragging) {
            self.playerContolView.playButton.selected = playing;
        }
    }
}

- (void)updateLineCount:(NSUInteger)lineCount defaultLine:(NSUInteger)line {
    if (lineCount == self.lineCount) {
        return;
    }
    self.lineCount = lineCount;
    self.curlineIndex = line;
}

- (void)updateCodeRateItems:(NSArray <NSString *>*)codeRates defaultCodeRate:(NSString *)codeRate {
    self.codeRateItems = codeRates;
    for (int i = 0; i < [codeRates count]; i++) {
        NSString *codeRateItem = codeRates[i];
        if ([codeRateItem isEqualToString:codeRate]) {
            self.curCodeRateIndex = i;
            break;
        }
    }
    [self updateCodeRateSwitchViewHiddenState];
}

- (void)updateDowloadProgress:(CGFloat)dowloadProgress
               playedProgress:(CGFloat)playedProgress
                     duration:(CGFloat)duration
          currentPlaybackTime:(NSString *)currentPlaybackTime
                 durationTime:(NSString *)durationTime {
    self.duration = self.playerContolView.duration = duration;
    if (self.playerContolView.currentTimeLabel.text.length != currentPlaybackTime.length) {
        [self.playerContolView setNeedsLayout];
    }
    self.playerContolView.currentTimeLabel.text = currentPlaybackTime;
    
    if (![self.playerContolView.totalTimeLabel.text isEqualToString:durationTime]) {
        self.playerContolView.totalTimeLabel.text = durationTime;
        [self.playerContolView setNeedsLayout];
    }
    
    if (!self.playerContolView.sliderDragging) {
        self.playerContolView.progressSlider.value = playedProgress;
    }
}

#pragma mark - Private

- (void)updateCodeRateSwitchViewHiddenState {
    BOOL hidden = self.audioMode || (!self.codeRateItems || [self.codeRateItems count] == 0);
    if (hidden == self.hiddenCodeRateSwitch) {
        return;
    }
    self.hiddenCodeRateSwitch = hidden;
    if (_moreView) {
        [self.moreView reloadData];
    }
}

#pragma mark - Action

- (void)moreButtonAction:(id)sender {
    if (self.type == PLVECHomePageType_Live) {
        if (self.isPlaying) {
            [self.moreView reloadData];
        } else {
            [self.moreView removeMoreViewItems];
        }
        self.moreView.hidden = NO;
    } else if (self.type == PLVECHomePageType_Playback) {
        [self updateSwitchView:PLVECSwitchViewType_Speed];
    }
}

- (void)giftButtonAction:(id)sender {
    [self.rewardCtrl hiddenView:NO];
}

- (void)shoppingCardButtonAction:(id)sender {
    if (self.commodityVC) {
        self.commodityVC = nil;
    }
    PLVECCommodityViewController *commodityVC = [[PLVECCommodityViewController alloc] init];
    commodityVC.delegate = self;
    commodityVC.providesPresentationContextTransitionStyle = YES;
    commodityVC.definesPresentationContext = YES;
    commodityVC.modalPresentationStyle =UIModalPresentationOverCurrentContext;
    [[PLVFdUtil getCurrentViewController] presentViewController:commodityVC animated:YES completion:nil];
    
    self.commodityVC = commodityVC;
}

#pragma mark - Delegate

#pragma mark PLVSocketManager Protocol

- (void)socketMananger_didReceiveMessage:(NSString *)subEvent
                                    json:(NSString *)jsonString
                              jsonObject:(id)object {
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    if ([subEvent isEqualToString:@"BULLETIN"]) { //
        [self bulletinEvent:jsonDict];
    } else if ([subEvent isEqualToString:@"REMOVE_BULLETIN"]) { //
        [self removeBulletinEvent:jsonDict];
    } else if ([subEvent isEqualToString:@"LIKES"]) {
        [self likesEvent:jsonDict];
    } else if ([subEvent isEqualToString:@"PRODUCT_MESSAGE"]) {
        [self productMessageEvent:jsonDict];
    }
}

- (void)socketMananger_didReceiveEvent:(NSString *)event
                              subEvent:(NSString *)subEvent
                                  json:(NSString *)jsonString
                            jsonObject:(id)object {
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    if ([event isEqualToString:@"customMessage"]) {
        [self customMessageEvent:jsonDict subEvent:subEvent];
    }
}

- (void)bulletinEvent:(NSDictionary *)jsonDict {
    NSString *content = PLV_SafeStringForDictKey(jsonDict, @"content");
    PLVECBulletinView *bulletinView = [[PLVECBulletinView alloc] init];
    bulletinView.frame = CGRectMake(15, CGRectGetMaxY(self.liveRoomInfoView.frame)+15, CGRectGetWidth(self.bounds)-30, 24);
    [bulletinView showBulletinView:content duration:5.0];
    [self addSubview:bulletinView];
    
    if ([self.delegate respondsToSelector: @selector(homePageView:receiveBulletinMessage:open:)]) {
        [self.delegate homePageView:self receiveBulletinMessage:content open:1];
    }
}

- (void)removeBulletinEvent:(NSDictionary *)jsonDict {
    if ([self.delegate respondsToSelector: @selector(homePageView:receiveBulletinMessage:open:)]) {
        [self.delegate homePageView:self receiveBulletinMessage:nil open:0];
    }
}

- (void)likesEvent:(NSDictionary *)jsonDict {
    NSString *userId = PLV_SafeStringForDictKey(jsonDict, @"userId");
    if ([userId isEqualToString:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId]) {
        return;
    }
    NSUInteger count = PLV_SafeIntegerForDictKey(jsonDict, @"count");
    count = MIN(5, count);
    for (int i = 0; i < count; i++) {
        [self.likeButtonView showLikeAnimation];
    }
}

- (void)productMessageEvent:(NSDictionary *)jsonDict {
    NSString *subEvent = PLV_SafeStringForDictKey(jsonDict, @"EVENT");
    if (![subEvent isEqualToString:@"PRODUCT_MESSAGE"]) {
        return;
    }
    
    if (self.shoppingCartButton.isHidden) {
        return; // 未开启商品功能
    }
    
    NSInteger status = PLV_SafeIntegerForDictKey(jsonDict, @"status");
    
    if (self.commodityVC) {
        [self.commodityVC receiveProductMessage:status content:jsonDict[@"content"]];
    }
    
    if (9 == status) {
        NSDictionary *content = PLV_SafeDictionaryForDictKey(jsonDict, @"content");
        PLVCommodityModel *model = [PLVCommodityModel commodityModelWithDict:content];
        [self.pushView setModel:model];
    }
}

- (void)customMessageEvent:(NSDictionary *)jsonDict subEvent:(NSString *)subEvent {
    if ([subEvent isEqualToString:@"GiftMessage"]) {           // 自定义礼物消息
        NSDictionary *user = PLV_SafeDictionaryForDictKey(jsonDict, @"user");
        NSDictionary *data = PLV_SafeDictionaryForDictKey(jsonDict, @"data");
        if ([[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId isEqualToString:PLV_SafeStringForDictKey(user, @"userId")]) {
            return;
        }
        
        NSString *nickName = PLV_SafeStringForDictKey(user, @"nick");
        NSString *giftName = PLV_SafeStringForDictKey(data, @"giftName");
        NSString *giftType = PLV_SafeStringForDictKey(data, @"giftType");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.giftView showGiftAnimation:nickName giftName:giftName giftType:giftType];
        });
    }
}

#pragma mark PLVPlayerContolViewDelegate

- (void)playerContolView:(PLVECPlayerContolView *)playerContolView switchPause:(BOOL)pause {
    if ([self.delegate respondsToSelector:@selector(homePageView:switchPause:)]) {
        [self.delegate homePageView:self switchPause:pause];
    }
}

- (void)playerContolViewSeeking:(PLVECPlayerContolView *)playerContolView {
    NSTimeInterval interval = self.duration * playerContolView.progressSlider.value;
    
    // 拖动进度条后，同步当前进度时间
    [self updateDowloadProgress:0
                 playedProgress:playerContolView.progressSlider.value
                       duration:self.duration
            currentPlaybackTime:[PLVFdUtil secondsToString:interval]
                   durationTime:self.playerContolView.totalTimeLabel.text];
    
    if ([self.delegate respondsToSelector:@selector(homePageView:seekToTime:)]) {
        [self.delegate homePageView:self seekToTime:interval];
    }
}

#pragma mark PLVECCommodityDelegate、PLVECCommodityPushViewDelegate

- (void)jumpToGoodsDetail:(NSURL *)goodsURL {
    if (self.delegate && [self.delegate respondsToSelector: @selector(homePageView:openGoodsDetail:)]) {
        [self.delegate homePageView:self openGoodsDetail:goodsURL];
    }
}

#pragma mark PLVECMoreViewDelegate

- (NSArray<PLVECMoreViewItem *> *)dataSourceOfMoreView:(PLVECMoreView *)moreView {
    NSMutableArray *muArray = [[NSMutableArray alloc] initWithCapacity:3];
    
    PLVECMoreViewItem *item1 = [[PLVECMoreViewItem alloc] init];
    item1.title = @"音频模式";
    item1.selectedTitle = @"视频模式";
    item1.iconImageName = @"plv_audioSwitch_btn";
    item1.selectedIconImageName = @"plv_videoSwitch_btn";
    item1.selected = self.audioMode;
    [muArray addObject:item1];
    
    if (self.lineCount > 1) {
        PLVECMoreViewItem *item2 = [[PLVECMoreViewItem alloc] init];
        item2.title = @"线路";
        item2.iconImageName = @"plv_lineSwitch_btn";
        [muArray addObject:item2];
    }
    
    if (!self.hiddenCodeRateSwitch) {
        PLVECMoreViewItem *item3 = [[PLVECMoreViewItem alloc] init];
        item3.title = @"清晰度";
        item3.iconImageName = @"plv_codeRateSwitch_btn";
        [muArray addObject:item3];
    }
    return [muArray copy];
}

- (void)moreView:(PLVECMoreView *)moreView didSelectItem:(PLVECMoreViewItem *)item index:(NSUInteger)index {
    if (index == 0) {
        if ([self.delegate respondsToSelector:@selector(homePageView:switchAudioMode:)]) {
            [self.delegate homePageView:self switchAudioMode:item.isSelected];
        }
        self.audioMode = item.isSelected;
        [self updateCodeRateSwitchViewHiddenState];
    } else if (index == 1 || index == 2) {
        moreView.hidden = YES;
        PLVECSwitchViewType switchViewType = PLVECSwitchViewType_Unknown;
        if (index == 1) {
            switchViewType = PLVECSwitchViewType_Line;
        } else if (index == 2) {
            switchViewType = PLVECSwitchViewType_CodeRate;
        }
        [self updateSwitchView:switchViewType];
    }
}

- (void)updateSwitchView:(PLVECSwitchViewType)switchViewType {
    if (switchViewType != PLVECSwitchViewType_Line &&
        switchViewType != PLVECSwitchViewType_CodeRate &&
        switchViewType != PLVECSwitchViewType_Speed) {
        return;
    }
    self.switchViewType = switchViewType;
    if (switchViewType == PLVECSwitchViewType_Line) {
        self.switchView.titleLable.text = @"切换线路";
        self.switchView.selectedIndex = self.curlineIndex;
    } else if (switchViewType == PLVECSwitchViewType_CodeRate) {
        self.switchView.titleLable.text = @"切换清晰度";
        self.switchView.selectedIndex = self.curCodeRateIndex;
    } else if (switchViewType == PLVECSwitchViewType_Speed) {
        self.switchView.titleLable.text = @"播放速度";
        self.switchView.selectedIndex = self.curSpeedIndex;
    }
    [self.switchView reloadData];
}

#pragma mark PLVPlayerSwitchViewDelegate

- (NSArray<NSString *> *)dataSourceOfSwitchView:(PLVECSwitchView *)switchView {
    if (self.switchViewType == PLVECSwitchViewType_Line) {
        NSMutableArray *mArr = [NSMutableArray array];
        for (int i = 1; i <= self.lineCount; i ++) {
            [mArr addObject:[NSString stringWithFormat:@"线路%d",i]];
        }
        return [mArr copy];
    } else if (self.switchViewType == PLVECSwitchViewType_CodeRate) {
        return self.codeRateItems;
    } else if (self.switchViewType == PLVECSwitchViewType_Speed) {
        return @[@"0.5x", @"1.0x", @"1.25x", @"1.5x", @"2.0x"];
    } else {
        return @[];
    }
}

- (void)playerSwitchView:(PLVECSwitchView *)playerSwitchView
        didSelectedIndex:(NSUInteger)selectedIndex
            selectedItem:(NSString *)selectedItem {
    if (self.switchViewType == PLVECSwitchViewType_Line) {
        self.curlineIndex = selectedIndex;
        if ([self.delegate respondsToSelector:@selector(homePageView:switchPlayLine:)]) {
            [self.delegate homePageView:self switchPlayLine:self.curlineIndex];
        }
    } else if (self.switchViewType == PLVECSwitchViewType_CodeRate) {
        self.curCodeRateIndex = selectedIndex;
        if ([self.delegate respondsToSelector:@selector(homePageView:switchCodeRate:)]) {
            [self.delegate homePageView:self switchCodeRate:selectedItem];
        }
    } else if (self.switchViewType == PLVECSwitchViewType_Speed) {
        self.curSpeedIndex = selectedIndex;
        CGFloat speed = [[selectedItem substringToIndex:selectedItem.length] floatValue];
        speed = MIN(2.0, MAX(0.5, speed));
        if ([self.delegate respondsToSelector:@selector(homePageView:switchSpeed:)]) {
            [self.delegate homePageView:self switchSpeed:speed];
        }
    }
}

@end
