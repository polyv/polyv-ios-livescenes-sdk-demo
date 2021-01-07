//
//  PLVECLiveHomePageView.m
//  PolyvLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECLiveHomePageView.h"
#import "PLVRoomDataManager.h"
#import <PolyvFoundationSDK/PLVFdUtil.h>
#import "PLVECChatroomView.h"
#import "PLVECCommodityView.h"
#import "PLVECLiveRoomInfoView.h"
#import "PLVECMoreView.h"
#import "PLVECSwitchView.h"
#import "PLVECBulletinView.h"
#import "PLVECGiftView.h"
#import "PLVECRewardController.h"
#import "PLVECCommodityPushView.h"
#import "PLVECUtils.h"
#import "PLVECChatroomViewModel.h"

@interface PLVECLiveHomePageView () <PLVECMoreViewDelegate, PLVPlayerSwitchViewDelegate, PLVECRewardControllerDelegate, PLVECCommodityDelegate, PLVSocketManagerProtocol>

@property (nonatomic, weak) id<PLVECLiveHomePageViewDelegate> delegate;

@property (nonatomic, strong) PLVECLiveRoomInfoView *liveRoomInfoView; // 直播详情视图
@property (nonatomic, strong) PLVECChatroomView *chatroomView;         // 聊天室视图
@property (nonatomic, strong) PLVECCommodityView *commodityView;       // 商品视图
@property (nonatomic, strong) PLVECMoreView *moreView;                 // 更多视图
@property (nonatomic, strong) PLVECSwitchView *switchLineView;         // 线路切换视图
@property (nonatomic, strong) PLVECSwitchView *switchCodeRateView;     // 清晰度切换视图
@property (nonatomic, strong) PLVECRewardController *rewardCtrl;       // 打赏控制器

@property (nonatomic, strong) PLVECCommodityPushView *pushView;

@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UILabel *likeLable;

@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UIButton *giftButton;
/// 码率列表
@property (nonatomic, copy) NSArray<NSString *> *codeRateItems;
/// 当前码率
@property (nonatomic, assign) NSUInteger curCodeRateIndex;
/// 线路数
@property (nonatomic, assign) NSUInteger lineCount;
/// 当前线路
@property (nonatomic, assign) NSUInteger curlineIndex;
/// 音频模式，默认NO，为视频模式
@property (nonatomic, assign) BOOL audioMode;
/// 线路数
@property (nonatomic, assign) BOOL hiddenCodeRateSwitch;

@property (nonatomic, strong) PLVECGiftView *giftView;     // 礼物视图
@property (nonatomic, assign) CGRect originGiftViewFrame;

@property (nonatomic, strong) NSTimer *likeTimer;

@end

@implementation PLVECLiveHomePageView {
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
}

#pragma mark - Getter & Setter

- (PLVECGiftView *)giftView {
    if (!_giftView) {
        self.originGiftViewFrame = CGRectMake(-270, CGRectGetHeight(self.bounds)-335-P_SafeAreaBottomEdgeInsets(), 270, 40);
        
        _giftView = [[PLVECGiftView alloc] init];
        _giftView.frame = self.originGiftViewFrame;
        [self addSubview:_giftView];
    }
    return _giftView;
}

- (PLVECRewardController *)rewardCtrl {
    if (!_rewardCtrl) {
        _rewardCtrl = [[PLVECRewardController alloc] init];
        _rewardCtrl.roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
        _rewardCtrl.delegate = self;
        
        CGFloat height = 258 + P_SafeAreaBottomEdgeInsets();
        _rewardCtrl.view = [[PLVECRewardView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.bounds)-height, CGRectGetWidth(self.bounds), height)];
        [self addSubview:_rewardCtrl.view];
    }
    return _rewardCtrl;
}

- (PLVECCommodityView *)commodityView {
    if (!_commodityView) {
        CGFloat height = 400 + P_SafeAreaBottomEdgeInsets();
        _commodityView = [[PLVECCommodityView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.bounds)-height, CGRectGetWidth(self.bounds), height)];
        _commodityView.channelId = [PLVRoomDataManager sharedManager].roomData.channelId;
        [self addSubview:_commodityView];
        _commodityView.hidden = YES;
        
        [_commodityView setCloseButtonActionBlock:^(PLVECBottomView * _Nonnull view) {
            [view setHidden:YES];
            if ([view isKindOfClass:PLVECCommodityView.class]) {
                [(PLVECCommodityView *)view clearCommodityInfo];
            }
        }];
        __weak typeof(self) weakSelf = self;
        [_commodityView setGoodsSelectedHandler:^(NSURL * _Nonnull goodsURL) {
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector: @selector(homePageView:openGoodsDetail:)]) {
                [weakSelf.delegate homePageView:weakSelf openGoodsDetail:goodsURL];
            }
        }];
    }
    return _commodityView;
}

- (PLVECCommodityPushView *)pushView {
    if (!_pushView) {
        _pushView = [[PLVECCommodityPushView alloc] initWithFrame:CGRectMake(16, CGRectGetMinY(self.shoppingCardButton.frame)-90, CGRectGetWidth(self.bounds)-110, 86)];
        _pushView.delegate = self;
        if (_commodityView) {
            [self insertSubview:_pushView belowSubview:_commodityView];
        } else {
            [self addSubview:_pushView];
        }
    }
    return _pushView;
}

- (PLVECMoreView *)moreView {
    if (!_moreView) {
        CGFloat height = 130 + P_SafeAreaBottomEdgeInsets();
        _moreView = [[PLVECMoreView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.bounds)-height, CGRectGetWidth(self.bounds), height)];
        _moreView.delegate = self;
        _moreView.hidden = YES;
        [self addSubview:_moreView];
        
        [_moreView setCloseButtonActionBlock:^(PLVECBottomView * _Nonnull view) {
            [view setHidden:YES];
        }];
    }
    return _moreView;
}

- (PLVECSwitchView *)switchLineView {
    if (!_switchLineView) {
        _switchLineView = [[PLVECSwitchView alloc] initWithFrame:self.moreView.frame];
        _switchLineView.titleLable.text = @"切换线路";
        _switchLineView.delegate = self;
        _switchLineView.selectedIndex = self.curlineIndex;
        [self addSubview:_switchLineView];
        
        [_switchLineView setCloseButtonActionBlock:^(PLVECBottomView * _Nonnull view) {
            [view setHidden:YES];
        }];
    }
    return _switchLineView;
}

- (PLVECSwitchView *)switchCodeRateView {
    if (!_switchCodeRateView) {
        _switchCodeRateView = [[PLVECSwitchView alloc] initWithFrame:self.moreView.frame];
        _switchCodeRateView.titleLable.text = @"切换清晰度";
        _switchCodeRateView.delegate = self;
        _switchCodeRateView.selectedIndex = self.curCodeRateIndex;
        [self addSubview:_switchCodeRateView];
        
        [_switchCodeRateView setCloseButtonActionBlock:^(PLVECBottomView * _Nonnull view) {
            [view setHidden:YES];
        }];
    }
    return _switchCodeRateView;
}

- (void)setAudioMode:(BOOL)audioMode {
    if (_audioMode == audioMode) {
        return;
    }
    _audioMode = audioMode;
    self.hiddenCodeRateSwitch = audioMode || (!self.codeRateItems || [self.codeRateItems count] == 0);
}

- (void)setHiddenCodeRateSwitch:(BOOL)hiddenCodeRateSwitch {
    if (_hiddenCodeRateSwitch == hiddenCodeRateSwitch) {
        return;
    }
    _hiddenCodeRateSwitch = hiddenCodeRateSwitch;
    [self.moreView reloadData];
}

- (instancetype)initWithDelegate:(id<PLVECLiveHomePageViewDelegate>)delegate {
    self = [super init];
    if (self) {
        self.delegate = delegate;
        
        [self setupUI];
        
        [self initTimer];
        
        socketDelegateQueue = dispatch_get_main_queue();
        [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
    }
    return self;
}

- (void)setupUI {
    self.liveRoomInfoView = [[PLVECLiveRoomInfoView alloc] initWithFrame:CGRectMake(15, 10, 118, 36)];
    [self addSubview:self.liveRoomInfoView];
    
    // 初始化聊天室视图和相关配置
    self.chatroomView = [[PLVECChatroomView alloc] init];
    [self addSubview:self.chatroomView];
    
    self.likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.likeButton setImage:[PLVECUtils imageForWatchResource:@"plv_like_btn"] forState:UIControlStateNormal];
    [self.likeButton setImage:[PLVECUtils imageForWatchResource:@"plv_like_btn"] forState:UIControlStateHighlighted];
    [self.likeButton addTarget:self action:@selector(likeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.likeButton];
    
    self.likeLable = [[UILabel alloc] init];
    self.likeLable.textAlignment = NSTextAlignmentCenter;
    self.likeLable.textColor = UIColor.whiteColor;
    self.likeLable.font = [UIFont systemFontOfSize:12.0];
    [self addSubview:self.likeLable];
    
    self.moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.moreButton setImage:[PLVECUtils imageForWatchResource:@"plv_more_btn"] forState:UIControlStateNormal];
    [self.moreButton addTarget:self action:@selector(moreButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.moreButton];
    
    self.giftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.giftButton setImage:[PLVECUtils imageForWatchResource:@"plv_gift_btn"] forState:UIControlStateNormal];
    [self.giftButton addTarget:self action:@selector(giftButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.giftButton];
    
    self.shoppingCardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.shoppingCardButton setImage:[PLVECUtils imageForWatchResource:@"plv_shoppingCard_btn"] forState:UIControlStateNormal];
    [self.shoppingCardButton addTarget:self action:@selector(shoppingCardButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    self.shoppingCardButton.hidden = YES;
    [self addSubview:self.shoppingCardButton];
}

#pragma mark - Override

- (void)layoutSubviews {
    [super layoutSubviews];

    self.chatroomView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)-P_SafeAreaBottomEdgeInsets());
    CGFloat buttonWidth = 32.f;
    self.moreButton.frame = CGRectMake(CGRectGetWidth(self.bounds)-buttonWidth-15, CGRectGetHeight(self.bounds)-buttonWidth-15-P_SafeAreaBottomEdgeInsets(), buttonWidth, buttonWidth);
    self.giftButton.frame = CGRectMake(CGRectGetMinX(self.moreButton.frame)-48, CGRectGetMinY(self.moreButton.frame), buttonWidth, buttonWidth);
    self.shoppingCardButton.frame = CGRectMake(CGRectGetMinX(self.giftButton.frame)-48, CGRectGetMinY(self.moreButton.frame), buttonWidth, buttonWidth);
    self.likeButton.frame = CGRectMake(CGRectGetMinX(self.moreButton.frame), CGRectGetMinY(self.moreButton.frame)-59, buttonWidth + 10, buttonWidth + 10);
    self.likeLable.frame = CGRectMake(CGRectGetMidX(self.likeButton.frame)-50/2, CGRectGetMaxY(self.likeButton.frame)+3.0, 50, 12);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (_moreView && !_moreView.hidden) {
        _moreView.hidden = YES;
    }
    if (_switchLineView && !_switchLineView.hidden) {
        _switchLineView.hidden = YES;
    }
    if (_switchCodeRateView && !_switchCodeRateView.hidden) {
        _switchCodeRateView.hidden = YES;
    }
    if (_commodityView && !_commodityView.hidden) {
        _commodityView.hidden = YES;
        [_commodityView clearCommodityInfo];
    }
    [_rewardCtrl hiddenView:YES];
}

#pragma mark Timer

- (void)initTimer {
    if (!self.likeTimer) {
        self.likeTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(likeTimerTick) userInfo:nil repeats:YES];
    }
}

- (void)invalidateTimer {
    if (self.likeTimer) {
        [self.likeTimer invalidate];
        self.likeTimer = nil;
    }
}

- (void)likeTimerTick {
    /// 每10s随机显示一些点赞动画
    for (int i=0; i<rand()%4+1; i++) {
        [self showLikeAnimation];
    }
}

#pragma mark - PLVSocketManager Protocol

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
        [self showLikeAnimation];
    }
}

- (void)productMessageEvent:(NSDictionary *)jsonDict {
    NSString *subEvent = PLV_SafeStringForDictKey(jsonDict, @"EVENT");
    if (![subEvent isEqualToString:@"PRODUCT_MESSAGE"]) {
        return;
    }
    
    if (self.shoppingCardButton.isHidden) {
        return; // 未开启商品功能
    }
    
    NSInteger status = PLV_SafeIntegerForDictKey(jsonDict, @"status");
    [self.commodityView receiveProductMessage:status content:jsonDict[@"content"]];
    if (9 == status) {
        NSDictionary *content = PLV_SafeDictionaryForDictKey(jsonDict, @"content");
        PLVECCommodityModel *model = [PLVECCommodityModel modelWithDict:content];
        PLVECCommodityCellModel *cellModel = [[PLVECCommodityCellModel alloc] initWithModel:model];
        self.pushView.cellModel = cellModel;
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
            [self showGiftAnimation:nickName giftName:giftName giftType:giftType duration:2.0];
        });
    }
}

#pragma mark - Public

- (void)destroy {
    [self invalidateTimer];
    [_pushView destroy];
    [[PLVECChatroomViewModel sharedViewModel] clear];
}

- (void)updateChannelInfo:(NSString *)publisher coverImage:(NSString *)coverImage {
    self.liveRoomInfoView.publisherLB.text = publisher;
    [PLVFdUtil setImageWithURL:[NSURL URLWithString:coverImage] inImageView:self.liveRoomInfoView.coverImageView completed:^(UIImage *image, NSError *error, NSURL *imageURL) {
        if (error) {
            NSLog(@"设置头像失败：%@\n%@",imageURL,error.localizedDescription);
        }
    }];
}

- (void)updateOnlineCount:(NSUInteger)onlineCount {
    self.liveRoomInfoView.pageViewLB.text = [NSString stringWithFormat:@"%lu",(unsigned long)onlineCount];
}

- (void)updateLikeCount:(NSUInteger)likeCount {
    NSString *countStr = [NSString stringWithFormat:@"%ld",likeCount];
    if (likeCount > 10000) {
        countStr = [NSString stringWithFormat:@"%ld.%ldw",likeCount/10000,(likeCount%10000)/1000];
    }
    self.likeLable.text = countStr;
}

- (void)updateLineCount:(NSUInteger)lineCount defaultLine:(NSUInteger)line {
    if (lineCount == self.lineCount) {
        return;
    }
    self.lineCount = lineCount;
    self.curlineIndex = line;
    [self.moreView reloadData];
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
    self.hiddenCodeRateSwitch = self.audioMode || (!codeRates || [codeRates count] == 0);
}

- (void)updatePlayerState:(BOOL)playing {
    if (_moreView) {
        if (!_moreView.isHidden) {
            [_moreView setItemsHidden:!playing];
        }
        if (!_switchLineView.isHidden && !playing) {
            _switchLineView.hidden = YES;
        }
        if (!_switchCodeRateView.isHidden && !playing) {
            _switchLineView.hidden = YES;
        }
    }
}

#pragma mark - Action

- (void)likeButtonAction:(UIButton *)button {
    [self showLikeAnimation];
    [[PLVECChatroomViewModel sharedViewModel] sendLike];
}

- (void)moreButtonAction:(UIButton *)button {
    self.moreView.hidden = NO;
    [self.moreView reloadData];
    if ([self.delegate respondsToSelector:@selector(playerIsPlaying)]) {
        BOOL playing = [self.delegate playerIsPlaying];
        [self.moreView setItemsHidden:!playing];
    }
}

- (void)giftButtonAction:(UIButton *)button {
    [self.rewardCtrl hiddenView:NO];
}

- (void)shoppingCardButtonAction:(UIButton *)button {
    self.commodityView.hidden = NO;
    [self.commodityView loadCommodityInfo];
}

#pragma mark - <PLVECCommodityDelegate>

- (void)commodity:(id)commodity didSelect:(PLVECCommodityCellModel *)cellModel {
    NSLog(@"商品跳转：%@",cellModel.jumpLinkUrl);
    
    if (cellModel.jumpLinkUrl) {
        if (![UIApplication.sharedApplication openURL:cellModel.jumpLinkUrl]) {
            NSLog(@"url: %@",cellModel.jumpLinkUrl);
        }
    }
}

#pragma mark - <PLVECMoreViewDelegate>

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
    switch (index) {
        case 0: {
            if ([self.delegate respondsToSelector:@selector(homePageView:switchAudioMode:)]) {
                [self.delegate homePageView:self switchAudioMode:item.isSelected];
            }
            self.audioMode = item.isSelected;
        } break;
        case 1: {
            moreView.hidden = YES;
            self.switchLineView.hidden = NO;
            if (self.lineCount > 0) {
                if (!self.switchLineView.items || !self.switchLineView.items.count) {
                    NSMutableArray *mArr = [NSMutableArray array];
                    for (int i = 1; i <= self.lineCount; i ++) {
                        [mArr addObject:[NSString stringWithFormat:@"线路%d",i]];
                    }
                    self.switchLineView.items = mArr;
                }
            }
        } break;
        case 2: {
            moreView.hidden = YES;
            self.switchCodeRateView.hidden = NO;
            if (!self.switchCodeRateView.items || self.switchCodeRateView.items.count == 0) {
                self.switchCodeRateView.items = self.codeRateItems;
            }
        } break;
        default:
            break;
    }
}


#pragma mark - <PLVPlayerSwitchViewDelegate>

- (void)playerSwitchView:(PLVECSwitchView *)playerSwitchView didSelectItem:(NSString *)item {
    if (playerSwitchView == _switchLineView) {
        self.curlineIndex = [[item substringFromIndex:2] integerValue] - 1;
        if ([self.delegate respondsToSelector:@selector(homePageView:switchPlayLine:)]) {
            [self.delegate homePageView:self switchPlayLine:self.curlineIndex];
        }
    } else if (playerSwitchView == _switchCodeRateView) {
        if ([self.delegate respondsToSelector:@selector(homePageView:switchCodeRate:)]) {
            [self.delegate homePageView:self switchCodeRate:item];
        }
    }
    [playerSwitchView setHidden:YES];
}


#pragma mark - <PLVECRewardControllerDelegate>

- (void)showGiftAnimation:(NSString *)userName giftName:(NSString *)giftName giftType:(NSString *)giftType {
    [self showGiftAnimation:userName giftName:giftName giftType:giftType duration:2.0];
}

#pragma mark - 点赞动画

- (void)showLikeAnimation {
    UIImage *heartImage = [PLVECUtils imageForWatchResource:[NSString stringWithFormat:@"plv_like_heart%@_img",@(rand()%4)]];
    if (!heartImage) {
        return;
    }
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:heartImage];
    imageView.frame = CGRectMake(5.0, 5.0, 18.0, 15.0);
    [imageView setContentMode:UIViewContentModeCenter];
    imageView.clipsToBounds = YES;
    imageView.userInteractionEnabled = NO;
    [self.likeButton addSubview:imageView];
    
    CGFloat finishX = round(random() % 84) - 84 + (CGRectGetWidth(self.bounds) - CGRectGetMinX(self.likeButton.frame));
    CGFloat speed = 1.0 / round(random() % 900) + 0.6;
    NSTimeInterval duration = 4.0 * speed;
    if (duration == INFINITY) {
        duration = 2.412346;
    }
    
    [UIView animateWithDuration:duration animations:^{
        imageView.alpha = 0.0;
        imageView.frame = CGRectMake(finishX, - 180, 30.0, 30.0);
    } completion:^(BOOL finished) {
        [imageView removeFromSuperview];
    }];
}

#pragma mark - 礼物动画

- (void)showGiftAnimation:(NSString *)userName giftName:(NSString *)giftName giftType:(NSString *)giftType duration:(NSTimeInterval)duration {
    if (self.giftView.hidden) {
        self.giftView.hidden = NO;
        self.giftView.nameLabel.text = userName;
        self.giftView.messageLable.text = [NSString stringWithFormat:@"赠送 %@",giftName];
        NSString *giftImageStr = [NSString stringWithFormat:@"plv_gift_icon_%@",giftType];
        self.giftView.giftImgView.image = [PLVECUtils imageForWatchResource:giftImageStr];
        [UIView animateWithDuration:.5 animations:^{
            CGRect newFrame = self.giftView.frame;
            newFrame.origin.x = 0;
            self.giftView.frame = newFrame;
        }];
         
        SEL shutdownGiftView = @selector(shutdownGiftView);
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:shutdownGiftView object:nil];
        [self performSelector:shutdownGiftView withObject:nil afterDelay:duration];
    } else {
        [self shutdownGiftView];
        [self showGiftAnimation:userName giftName:giftName giftType:giftType duration:duration];
    }
}

- (void)shutdownGiftView {
    self.giftView.hidden = YES;
    self.giftView.frame = self.originGiftViewFrame;
}

@end
