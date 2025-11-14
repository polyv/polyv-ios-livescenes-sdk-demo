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
#import "PLVCommodityPushSmallCardView.h"
#import "PLVECPlaybackListViewController.h"
#import "PLVECSubtitleConfigView.h"
#import <PLVLiveScenesSDK/PLVSocketManager.h>

// UI
#import "PLVECLiveRoomInfoView.h"
#import "PLVECChatroomView.h"
#import "PLVECLikeButtonView.h"
#import "PLVECCardPushButtonView.h"
#import "PLVECRedpackButtonView.h"
#import "PLVECPlayerContolView.h"
#import "PLVECMoreView.h"
#import "PLVECSwitchView.h"
#import "PLVECPIPPlaysetPopView.h"
#import "PLVECLotteryWidgetView.h"
#import "PLVECWelfareLotteryWidgetView.h"

// 工具
#import "PLVECUtils.h"
#import "PLVActionSheet.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFdUtil.h>

static NSString *const PLVECHomePageView_Data_AudioModeItemTitle = @"音频模式";
static NSString *const PLVECHomePageView_Data_RouteItemTitle     = @"线路";
static NSString *const PLVECHomePageView_Data_QualityItemTitle   = @"清晰度";
static NSString *const PLVECHomePageView_Data_DelayModeItemTitle = @"模式";
static NSString *const PLVECHomePageView_Data_PictureInPictureItemTitle = @"小窗播放";
static NSString *const PLVECHomePageView_Data_PictureInPicturePlaySetItemTitle = @"播放设置";
static NSString *const PLVECHomePageView_Data_SwitchLanguageItemTitle = @"PLVLiveLanguageSwitchTitle";
static NSString *const PLVECHomePageView_Data_PlaySpeedItemTitle = @"播放速度";
static NSString *const PLVECHomePageView_Data_SubtitleItemTitle = @"回放字幕";
static NSString *const PLVECHomeSwitchNormalDelayAttributeName = @"switchnormaldelay";

/// SwitchView类型
typedef NS_ENUM(NSInteger, PLVECSwitchViewType) {
    /// SwitchView类型为 未知
    PLVECSwitchViewType_Unknown = 0,
    /// SwitchView类型为 切换线路
    PLVECSwitchViewType_Line = 1,
    /// SwitchView类型为 切换码率
    PLVECSwitchViewType_CodeRate = 2,
    /// SwitchView类型为 切换延迟模式
    PLVECSwitchViewType_DelayMode = 3,
    /// SwitchView类型为 切换速率
    PLVECSwitchViewType_Speed = 4
};

@interface PLVECHomePageView ()<
UITextViewDelegate,
PLVPlayerContolViewDelegate,
PLVECMoreViewDelegate,
PLVPlayerSwitchViewDelegate,
PLVECCommodityViewControllerDelegate,
PLVCommodityPushSmallCardViewDelegate,
PLVSocketManagerProtocol,
PLVECChatroomViewDelegate,
PLVECCardPushButtonViewDelegate,
PLVECLotteryWidgetViewDelegate,
PLVECWelfareLotteryWidgetViewDelegate,
PLVECSubtitleConfigViewDelegate
>

#pragma mark 数据

@property (nonatomic, weak) id<PLVECHomePageViewDelegate> delegate;
@property (nonatomic, assign) PLVECHomePageType type;
@property (nonatomic, assign) PLVECSwitchViewType switchViewType;
@property (nonatomic, strong) NSArray *interactButtonArray;            // 互动应用添加按钮

/// 直播特有属性
@property (nonatomic, copy) NSArray<NSString *> *codeRateItems;        // 当前直播支持码率列表
@property (nonatomic, assign) NSUInteger curCodeRateIndex;             // 当前直播播放码率
@property (nonatomic, assign) NSUInteger lineCount;                    // 当前直播支持切换线路数
@property (nonatomic, assign) NSUInteger curlineIndex;                 // 当前直播所选线路
@property (nonatomic, assign) NSUInteger curDelayModeIndex;            // 当前直播所选延迟模式
@property (nonatomic, assign) BOOL audioMode;                          // 音频模式，默认NO-视频模式
@property (nonatomic, assign) BOOL hiddenCodeRateSwitch;               // 是否显示切换码率按钮
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) BOOL hiddenDelayModeSwitch;              // 是否显示模式切换按钮
@property (nonatomic, assign) BOOL noDelayWatchMode;                   // 当前是否为无延迟观看模式
@property (nonatomic, assign) BOOL networkQualityMiddleViewShowed;     // 网络不佳提示视图是否显示过
@property (nonatomic, assign) BOOL networkQualityPoorViewShowed;       // 网络糟糕提示视图是否显示过
@property (nonatomic, copy) NSString *questionnaireEventName;          // 互动问卷事件
/// 回放特有属性
@property (nonatomic, assign) NSTimeInterval duration;                 // 回放视频时长
@property (nonatomic, assign) NSUInteger curSpeedIndex;                // 回放视频当前播放速率
@property (nonatomic, assign) NSTimeInterval currentPlaybackTime;      // 回放视频当前播放节点

#pragma mark 模块

@property (nonatomic, strong) PLVECMoreView *moreView;                 // 更多视图
@property (nonatomic, strong) PLVECSwitchView *switchView;             // 切换视图
@property (nonatomic, strong) PLVECPIPPlaysetPopView *pipPopView;      // 小窗播放设置
@property (nonatomic, weak) PLVECCommodityViewController *commodityVC; // 商品视图
@property (nonatomic, strong) PLVCommodityPushSmallCardView *pushView;        // 商品推送视图
@property (nonatomic, weak) PLVECPlaybackListViewController *playbackListVC;     //回放列表视图
@property (nonatomic, strong) PLVPinMessagePopupView *pinMsgPopupView; // 评论上墙视图
@property (nonatomic, strong) PLVECSubtitleConfigView *subtitleConfigView; // 字幕配置视图

#pragma mark UI

@property (nonatomic, strong) PLVECLiveRoomInfoView *liveRoomInfoView; // 直播详情视图
@property (nonatomic, strong) PLVECChatroomView *chatroomView;         // 聊天室视图
@property (nonatomic, strong) PLVECLikeButtonView *likeButtonView;     // 点赞视图
@property (nonatomic, strong) PLVECCardPushButtonView *cardPushButtonView; // 卡片推送挂件
@property (nonatomic, strong) PLVECRedpackButtonView *redpackButtonView; // 倒计时红包挂件
@property (nonatomic, strong) PLVECPlayerContolView *playerContolView; // 视频播放控制视图
@property (nonatomic, strong) PLVECLotteryWidgetView *lotteryWidgetView; // 抽奖挂件视图
@property (nonatomic, strong) PLVECWelfareLotteryWidgetView *welfareLotteryWidgetView; // 福利抽奖挂件
@property (nonatomic, strong) UIButton *moreButton;                    // 更多按钮
@property (nonatomic, strong) UIButton *giftButton;                    // 送礼按钮
@property (nonatomic, strong) UIButton *shoppingCartButton;            // 购物车按钮
@property (nonatomic, strong) UIButton *playbackListButton;            // 回放列表按钮
@property (nonatomic, strong) UIButton *questionnaireButton;          // 互动问卷入口
@property (nonatomic, strong) UIButton *backButton;                  // 横屏返回按钮
@property (nonatomic, strong) UILabel *networkQualityMiddleLable;      // 网络不佳提示视图
@property (nonatomic, strong) UIView *networkQualityPoorView;          // 网络糟糕提示视图
@property (nonatomic, assign) BOOL visiable;                       // 该属性为YES表示当前该视图处于用户可见状态
@property (nonatomic, assign) BOOL showMemoryPlayWithoutPlaybackTimeChanged; // 该属性为YES表示续播时没有触发播放器时间更新
@property (nonatomic, strong) UIButton *onlineListButton; // 在线列表按钮

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
        self.curSpeedIndex = 2; // 默认1.0x
        
        [self setupUI];
        
        socketDelegateQueue = dispatch_get_main_queue();
        [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
    }
    return self;
}

#pragma mark - Override

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateUIFrame];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _moreView.hidden = YES;
    _switchView.hidden = YES;
}

#pragma mark - Initialize

- (void)setupUI {
    [self addSubview:self.liveRoomInfoView];
    [self addSubview:self.pinMsgPopupView];
    
    if (self.type == PLVECHomePageType_Live) {
        [self addSubview:self.chatroomView];
        [self addSubview:self.likeButtonView];
        [self addSubview:self.giftButton];
        [self addSubview:self.questionnaireButton];
        if ([PLVRoomDataManager sharedManager].roomData.menuInfo.portraitOnlineListEnabled) {
            [self addSubview:self.onlineListButton];
        }
    } else if (self.type == PLVECHomePageType_Playback) {
        [self addSubview:self.chatroomView];
        [self addSubview:self.playerContolView];
        if (![PLVRoomDataManager sharedManager].roomData.menuInfo.showPlayButtonEnabled) {
            self.playerContolView.playButton.hidden = YES;
        }
        if (![PLVRoomDataManager sharedManager].roomData.menuInfo.playbackProgressBarEnabled) {
            self.playerContolView.progressSlider.hidden = YES;
        }
        [self addSubview:self.playbackListButton];
    }
    
    [self addSubview:self.redpackButtonView];
    [self addSubview:self.cardPushButtonView];
    [self addSubview:self.lotteryWidgetView];
    [self addSubview:self.welfareLotteryWidgetView];
    [self addSubview:self.moreButton];
    [self addSubview:self.shoppingCartButton];
    [self addSubview:self.backButton];
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
        if (self.type == PLVECHomePageType_Live ||
            [PLVRoomDataManager sharedManager].roomData.menuInfo.chatInputDisable) { // 直播一定会显示聊天室，回放只有chatInputDisable为YES时会显示聊天室
            _chatroomView.delegate = self;
        } else {
            _chatroomView.hidden = YES;
        }
    }
    return _chatroomView;
}

- (PLVECCardPushButtonView *)cardPushButtonView {
    if (!_cardPushButtonView) {
        _cardPushButtonView = [[PLVECCardPushButtonView alloc] init];
        _cardPushButtonView.delegate = self;
        _cardPushButtonView.hidden = YES;
    }
    return _cardPushButtonView;
}

- (PLVECRedpackButtonView *)redpackButtonView {
    if (!_redpackButtonView) {
        _redpackButtonView = [[PLVECRedpackButtonView alloc] init];
    }
    return _redpackButtonView;
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

- (PLVECLotteryWidgetView *)lotteryWidgetView {
    if (!_lotteryWidgetView) {
        _lotteryWidgetView = [[PLVECLotteryWidgetView alloc] init];
        _lotteryWidgetView.delegate = self;
    }
    return _lotteryWidgetView;
}

- (PLVECWelfareLotteryWidgetView *)welfareLotteryWidgetView {
    if (!_welfareLotteryWidgetView) {
        _welfareLotteryWidgetView = [[PLVECWelfareLotteryWidgetView alloc] init];
        _welfareLotteryWidgetView.delegate = self;
    }
    return _welfareLotteryWidgetView;
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
        _giftButton.hidden = YES;
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

- (UIButton *)playbackListButton {
    if (!_playbackListButton) {
        _playbackListButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playbackListButton setImage:[PLVECUtils imageForWatchResource:@"plv_playbackList_btn"] forState:UIControlStateNormal];
        [_playbackListButton addTarget:self action:@selector(playbackListButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _playbackListButton.hidden = YES;
    }
    return _playbackListButton;
}

- (UIButton *)questionnaireButton {
    if (!_questionnaireButton) {
        _questionnaireButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_questionnaireButton setTitle:PLVLocalizedString(@"问卷") forState:UIControlStateNormal];
        _questionnaireButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [_questionnaireButton setBackgroundColor:PLV_UIColorFromRGBA(@"#000000", 0.16)];
        [_questionnaireButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _questionnaireButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_questionnaireButton setImage:[PLVECUtils imageForWatchResource:@"plvec_iarentrance_questionnaire"] forState:UIControlStateNormal];
        [_questionnaireButton addTarget:self action:@selector(questionnaireButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _questionnaireButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [_questionnaireButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 4, 0, 0)];
        [_questionnaireButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 4)];
        _questionnaireButton.layer.masksToBounds = YES;
        _questionnaireButton.layer.cornerRadius = 12;
        _questionnaireButton.hidden = YES;
    }
    return _questionnaireButton;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setImage:[PLVECUtils imageForWatchResource:@"plvec_media_skin_back"] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UIButton *)onlineListButton {
    if (!_onlineListButton) {
        _onlineListButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_onlineListButton setTitle:[NSString stringWithFormat:PLVLocalizedString(@"%@人在线"),@"0"] forState:UIControlStateNormal];
        _onlineListButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [_onlineListButton setBackgroundColor:PLV_UIColorFromRGBA(@"#000000", 0.4)];
        [_onlineListButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_onlineListButton addTarget:self action:@selector(onlineListButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _onlineListButton.layer.masksToBounds = YES;
        _onlineListButton.layer.cornerRadius = 12;
    }
    return _onlineListButton;
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
        _switchView.hidden = YES;
        [self addSubview:_switchView];
    }
    return _switchView;
}

- (PLVECPIPPlaysetPopView *)pipPopView{
    if (!_pipPopView){
        CGFloat viewH = 266;
        __weak typeof(self) weakSelf = self;
        _pipPopView = [[PLVECPIPPlaysetPopView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height - viewH, self.bounds.size.width, viewH)];
        _pipPopView.exitRoomSwitchChanged = ^(BOOL on) {
            //
            [PLVRoomDataManager sharedManager].roomData.disableStartPipWhenExitLiveRoom = !on;
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(homePageView:autoStartPIP:)]){
                BOOL can = [[PLVRoomDataManager sharedManager].roomData canAutoStartPictureInPicture];
                [weakSelf.delegate homePageView:weakSelf autoStartPIP:can];
            }
        };
        _pipPopView.enterBackSwitchChanged = ^(BOOL on) {
            //
            [PLVRoomDataManager sharedManager].roomData.disableStartPipWhenEnterBackground = !on;
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(homePageView:autoStartPIP:)]){
                BOOL can = [[PLVRoomDataManager sharedManager].roomData canAutoStartPictureInPicture];
                [weakSelf.delegate homePageView:weakSelf autoStartPIP:can];
            }
        };
        _pipPopView.hidden = YES;
        [self addSubview:_pipPopView];
    }
    return _pipPopView;
}

- (PLVCommodityPushSmallCardView *)pushView {
    if (!_pushView) {
        _pushView = [[PLVCommodityPushSmallCardView alloc] init];
        _pushView.delegate = self;
    }
    return _pushView;
}

- (UILabel *)networkQualityMiddleLable {
    if (!_networkQualityMiddleLable) {
        _networkQualityMiddleLable = [[UILabel alloc] init];
        _networkQualityMiddleLable.text = PLVLocalizedString(@"您的网络状态不佳，可尝试切换网络");
        _networkQualityMiddleLable.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _networkQualityMiddleLable.textColor = PLV_UIColorFromRGB(@"#333333");
        _networkQualityMiddleLable.backgroundColor = PLV_UIColorFromRGB(@"#FFFFFF");
        _networkQualityMiddleLable.layer.masksToBounds = YES;
        _networkQualityMiddleLable.layer.cornerRadius = 12;
        _networkQualityMiddleLable.hidden = YES;
        _networkQualityMiddleLable.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_networkQualityMiddleLable];
    }
    return _networkQualityMiddleLable;
}

- (UIView *)networkQualityPoorView {
    if (!_networkQualityPoorView) {
        _networkQualityPoorView = [[UIView alloc] init];
        _networkQualityPoorView.hidden = YES;
        _networkQualityPoorView.backgroundColor =  PLV_UIColorFromRGB(@"#FFFFFF");
        [self addSubview:_networkQualityPoorView];
        
        UITextView *networkQualityTextView = [[UITextView alloc] init];
        networkQualityTextView.delegate = self;
        networkQualityTextView.editable = YES;
        networkQualityTextView.scrollEnabled = NO;
        networkQualityTextView.backgroundColor = [UIColor clearColor];
        networkQualityTextView.textContainerInset = UIEdgeInsetsZero;
        networkQualityTextView.textContainer.lineFragmentPadding = 0;
        UIFont *font = [UIFont fontWithName:@"PingFangSC-Regular" size: 12];
        UIColor *normalColor = PLV_UIColorFromRGB(@"#333333");
        UIColor *linkColor = PLV_UIColorFromRGB(@"#6DA7FF");
        NSDictionary *normalAttributes = @{NSFontAttributeName:font,
                                              NSForegroundColorAttributeName:normalColor};
        NSDictionary *switchAttributes = @{NSFontAttributeName:font,
                                                NSForegroundColorAttributeName:linkColor,
                                                NSLinkAttributeName: [NSString stringWithFormat:@"%@://", PLVECHomeSwitchNormalDelayAttributeName]};
        NSString *tipsString = PLVLocalizedString(@"您的网络状态糟糕，可尝试在更多>模式");
        NSString *switchString = PLVLocalizedString(@"切换到正常延迟");
        NSString *networkQualityString = [NSString stringWithFormat:@"%@ %@",tipsString, switchString];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:networkQualityString];
        [attributedString addAttributes:normalAttributes range:NSMakeRange(0, tipsString.length)];
        [attributedString addAttributes:switchAttributes range:NSMakeRange(tipsString.length + 1, switchString.length)];
        networkQualityTextView.linkTextAttributes = @{NSForegroundColorAttributeName: linkColor};
        networkQualityTextView.attributedText = attributedString;
        [_networkQualityPoorView addSubview:networkQualityTextView];
        
        CGFloat viewSizeHeight = 56;
        CGSize textViewSize = [attributedString boundingRectWithSize:CGSizeMake(self.bounds.size.width * 0.6, 36) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        networkQualityTextView.frame = CGRectMake(16, (viewSizeHeight - textViewSize.height)/2 - 2, textViewSize.width, textViewSize.height);
        
        UIButton *closeButton = [[UIButton alloc] init];
        [closeButton addTarget:self action:@selector(closeNetworkTipsViewClick:) forControlEvents:UIControlEventTouchUpInside];
        [closeButton setImage:[PLVECUtils imageForWatchResource:@"plv_network_tips_close"] forState:UIControlStateNormal];
        [_networkQualityPoorView addSubview:closeButton];
        closeButton.frame = CGRectMake(CGRectGetMaxX(networkQualityTextView.frame) + 8, 8, 16, 16);
        
        CGFloat viewSizeWidth = CGRectGetMaxX(closeButton.frame) + 16;
        UIBezierPath *bezierPath = [self BezierPathWithSize:CGSizeMake(viewSizeWidth, viewSizeHeight)];
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.path = bezierPath.CGPath;
        self.networkQualityPoorView.layer.mask = shapeLayer;
        self.networkQualityPoorView.bounds = CGRectMake(0, 0, viewSizeWidth, viewSizeHeight);
    }
    return _networkQualityPoorView;
}

- (PLVPinMessagePopupView *)pinMsgPopupView {
    if (!_pinMsgPopupView) {
        _pinMsgPopupView = [[PLVPinMessagePopupView alloc] init];
        _pinMsgPopupView.hidden = YES;
    }
    return _pinMsgPopupView;
}

- (UIBezierPath *)BezierPathWithSize:(CGSize)size {
    CGFloat conner = 8.0; // 圆角角度
    CGFloat trangleHeight = 4; // 尖角高度
    CGFloat trangleWidth = 4; // 尖角半径
    CGFloat leftPadding = size.width - 20;
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    // 起点
    [bezierPath moveToPoint:CGPointMake(conner, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width - conner, 0)];
    
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width, conner) controlPoint:CGPointMake(size.width, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width, size.height- conner - trangleHeight)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width-conner, size.height - trangleHeight) controlPoint:CGPointMake(size.width, size.height - trangleHeight)];

    [bezierPath addLineToPoint:CGPointMake(conner, size.height - trangleHeight)];
    [bezierPath addQuadCurveToPoint:CGPointMake(0, size.height - conner - trangleHeight) controlPoint:CGPointMake(0, size.height - trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(0, conner)];
    [bezierPath addQuadCurveToPoint:CGPointMake(conner, 0) controlPoint:CGPointMake(0, 0)];
    
    // 画尖角
    [bezierPath moveToPoint:CGPointMake(conner, size.height - trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(leftPadding - conner, size.height - trangleHeight)];
    // 顶点
    [bezierPath addLineToPoint:CGPointMake(leftPadding, size.height)];
    [bezierPath addLineToPoint:CGPointMake(leftPadding + trangleWidth, size.height - trangleHeight)];
    [bezierPath closePath];
    return bezierPath;
}

#pragma mark - Public

- (void)destroy {
    if (self.type == PLVECHomePageType_Live) {
        [_likeButtonView invalidTimer];
        [[PLVECChatroomViewModel sharedViewModel] clear];
    }
    [self.cardPushButtonView leaveLiveRoom];
}

- (void)showShoppingCart:(BOOL)show {
    self.shoppingCartButton.hidden = !show;
}

- (void)showMoreView {
    if (self.type == PLVECHomePageType_Live) {
        [self.moreView reloadData];
        self.moreView.hidden = NO;
    } else if (self.type == PLVECHomePageType_Playback) {
        [self.moreView reloadData];
        self.moreView.hidden = NO;
    }
}

- (void)updateChannelInfo:(NSString *)publisher coverImage:(NSString *)coverImage {
    self.liveRoomInfoView.publisherLB.text = PLVLocalizedString(publisher);
    [PLVFdUtil setImageWithURL:[NSURL URLWithString:coverImage]
                   inImageView:self.liveRoomInfoView.coverImageView
                     completed:nil];
}

- (void)updateRoomInfoCount:(NSUInteger)roomInfoCount {
    self.liveRoomInfoView.pageViewLB.text = [NSString stringWithFormat:@"%lu",(unsigned long)roomInfoCount];
}

- (void)updateLikeCount:(NSUInteger)likeCount {
    [self.likeButtonView setupLikeAnimationWithCount:likeCount];
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
            [self.playerContolView updatePlayButtonWithPlaying:playing];
        }
    }

    if (!playing &&
        [PLVRoomDataManager sharedManager].roomData.liveState != PLVChannelLiveStreamState_Live) {
        [self.pinMsgPopupView updatePopupViewWithMessage:nil];
    }
}

- (void)updateLinkMicState:(BOOL)linkMic {
    _moreView.hidden = YES;
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

- (void)updateNoDelayWatchMode:(BOOL)noDelayWatchMode {
    self.curDelayModeIndex = noDelayWatchMode ? 0 : 1;
    self.noDelayWatchMode = noDelayWatchMode;
    [self updateDelayModeSwitchViewHiddenState];
}

/// 根据缓存的播放速度初始化UI选中状态（仅回放场景有效）
- (void)initSpeedIndexFromCache {
    if (self.type != PLVECHomePageType_Playback) {
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(homePageView_getCachedPlaybackSpeedIndex:)]) {
        self.curSpeedIndex = [self.delegate homePageView_getCachedPlaybackSpeedIndex:self];
    }
}

- (void)updateDowloadProgress:(CGFloat)dowloadProgress
               playedProgress:(CGFloat)playedProgress
                     duration:(CGFloat)duration
  currentPlaybackTimeInterval:(NSTimeInterval)currentPlaybackTimeInterval
          currentPlaybackTime:(NSString *)currentPlaybackTime
                 durationTime:(NSString *)durationTime {
    self.duration = self.playerContolView.duration = duration;
    self.currentPlaybackTime = currentPlaybackTimeInterval;
    [self.chatroomView updateDuration:self.duration];
    if (self.showMemoryPlayWithoutPlaybackTimeChanged) {
        self.showMemoryPlayWithoutPlaybackTimeChanged = NO;
        [self playbackTimeChanged];
    }
    
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

- (void)updatePlaybackVideoInfo {
    [self.chatroomView playbackVideoInfoDidUpdated];

    // 加载显示默认字幕
    if (self.type == PLVECHomePageType_Playback) {
        PLVPlaybackVideoInfoModel *videoInfo = [PLVRoomDataManager sharedManager].roomData.playbackVideoInfo;
        if (videoInfo) {
            [self loadDefaultSubtitle:videoInfo];
        }
    }
}

- (void)showNetworkQualityMiddleView {
    if (self.networkQualityMiddleViewShowed) {
        return;
    }
    self.networkQualityMiddleViewShowed = YES;
    self.networkQualityMiddleLable.hidden = NO;

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.networkQualityMiddleLable.hidden = YES;
    });
}

- (void)showNetworkQualityPoorView {
    if (self.networkQualityPoorViewShowed) {
        return;
    }
    self.networkQualityPoorViewShowed = YES;
    self.networkQualityPoorView.hidden = NO;

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.networkQualityPoorView.hidden = YES;
    });
}

/// 更新更多按钮的显示或隐藏
/// @param show YES:显示  NO:隐藏
- (void)updateMoreButtonShow:(BOOL)show {
    self.moreButton.hidden = !show;
    [self updateUIFrame];
}

- (void)updateProgressControlsHidden:(BOOL)hidden {
    self.playerContolView.currentTimeLabel.hidden = hidden;
    self.playerContolView.totalTimeLabel.hidden = hidden;
    self.playerContolView.progressSlider.hidden = hidden;
}

- (void)updatePlayButtonEnabled:(BOOL)enabled {
    self.playerContolView.playButton.enabled = enabled;
    [self.playerContolView updatePlayButtonWithPlaying:self.playerContolView.playButton.isSelected];
}

- (void)updateIarEntranceButtonDataArray:(NSArray *)dataArray {
    if (![PLVFdUtil checkArrayUseable:dataArray]) {
        self.questionnaireButton.hidden = YES;
    }
    for (NSInteger index = 0; index < dataArray.count; index++) {
        NSDictionary *dict = dataArray[index];
        if ([PLVFdUtil checkDictionaryUseable:dict]) {
            BOOL isShow = PLV_SafeBoolForDictKey(dict, @"isShow");
            NSString *title = PLV_SafeStringForDictKey(dict, @"title");
            if ([PLVFdUtil checkStringUseable:title] && [title isEqualToString:PLVLocalizedString(@"问卷")]) {
                self.questionnaireEventName = PLV_SafeStringForDictKey(dict, @"event");
                self.questionnaireButton.hidden = !isShow;
            }
        }
    }
}

- (void)updateMoreButtonDataArray:(NSArray *)dataArray {
    self.interactButtonArray = dataArray;
    if (_moreView) {
        [self.moreView reloadData];
    }
}

- (void)updateLotteryWidgetViewInfo:(NSArray *)dataArray {
    if ([PLVFdUtil checkArrayUseable:dataArray]) {
        [self.lotteryWidgetView updateLotteryWidgetInfo:dataArray.firstObject];
    } else {
        [self.lotteryWidgetView hideWidgetView];
    }
    [self updateLikeViewAnimationLeftShift];
}

- (void)updateWelfareLotteryWidgetViewInfo:(NSDictionary *)dict {
    if ([PLVFdUtil checkDictionaryUseable:dict]) {
        [self.welfareLotteryWidgetView updateWelfareLotteryWidgetInfo:dict];
    } else {
        [self.welfareLotteryWidgetView hideWidgetView];
    }
    [self updateLikeViewAnimationLeftShift];
}


- (void)reportProductClickedEvent:(PLVCommodityModel *)commodity {
    [self.pushView sendProductClickedEvent:commodity];
}

- (void)updatePlaybackListButton:(BOOL)show {
    self.playbackListButton.hidden = !show;
}

- (void)showPinMessagePopupView:(BOOL)show message:(PLVSpeakTopMessage *)message {
    [self.pinMsgPopupView updatePopupViewWithMessage:message];
}

- (void)playbackDidShowMemoryPlayTip {
    if (self.currentPlaybackTime > 0 && self.duration > 0) {
        [self.chatroomView playbackTimeChanged];
    } else {
        self.showMemoryPlayWithoutPlaybackTimeChanged = YES;
    }
}

- (void)updateOnlineListButton:(NSInteger)onlineCount {
    NSString *onlineCountString = [NSString stringWithFormat:@"%ld",onlineCount];
    BOOL currentLanguageModeZH = [PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH || [PLVMultiLanguageManager sharedManager].currentLanguage == PLVMultiLanguageModeZH_HK;
    if (currentLanguageModeZH && onlineCount > 10000) {
        onlineCountString = [NSString stringWithFormat:@"%0.1fw", onlineCount / 10000.0];
    } else if (!currentLanguageModeZH && onlineCount > 1000) {
        onlineCountString = [NSString stringWithFormat:@"%0.1fk", onlineCount / 1000.0];
    }
    [self.onlineListButton setTitle:[NSString stringWithFormat:PLVLocalizedString(@"%@人在线"),onlineCountString] forState:UIControlStateNormal];
}

/// 设置字幕列表数据
/// @param subtitleList 字幕列表数据
- (void)setupSubtitleList:(NSArray<PLVPlaybackSubtitleModel *> *)subtitleList {
    if (self.subtitleConfigView) {
        [self.subtitleConfigView setupWithSubtitleList:subtitleList];
    }
}

/// 加载默认字幕（参考云课堂逻辑）
/// @param videoInfo 回放视频信息
- (void)loadDefaultSubtitle:(PLVPlaybackVideoInfoModel *)videoInfo {
    if (![PLVFdUtil checkArrayUseable:videoInfo.availableSubtitleList]) {
        // 没有可用字幕，清空当前字幕
        [self updateSubtitleWithOriginal:nil translate:nil];
        return;
    }
        
    // 选择默认字幕（参考云课堂逻辑）
    PLVPlaybackSubtitleModel *originalSubtitle = nil;   // 原声字幕
    PLVPlaybackSubtitleModel *translateSubtitle = nil;  // 翻译字幕
    
    for (PLVPlaybackSubtitleModel *subtitle in videoInfo.availableSubtitleList) {
        if (![PLVPlaybackSubtitleModel isSubtitleAvailable:subtitle]) {
            continue;
        }
        
        // 原生字幕
        if (subtitle.isOriginal && !originalSubtitle) {
            originalSubtitle = subtitle;
        }
        // 第一个翻译字幕
        if (!subtitle.isOriginal && !translateSubtitle) {
            translateSubtitle = subtitle;
        }
        
        // 如果已经找到原声和翻译字幕，可以提前退出
        if (originalSubtitle && translateSubtitle) {
            break;
        }
    }
    
    // 默认启用原声字幕（如果有的话）
    [self updateSubtitleWithOriginal:originalSubtitle translate:translateSubtitle];
    
    // 更新字幕配置视图的数据
    [self setupSubtitleList:videoInfo.availableSubtitleList];
}

/// 更新字幕显示（通过delegate回调给外部处理）
/// @param originalSubtitle 原声字幕
/// @param translateSubtitle 翻译字幕
- (void)updateSubtitleWithOriginal:(PLVPlaybackSubtitleModel *)originalSubtitle 
                         translate:(PLVPlaybackSubtitleModel *)translateSubtitle {
    
    // 通过delegate回调给外部（PLVECPlayerViewController）处理
    if (self.delegate && [self.delegate respondsToSelector:@selector(homePageView:updateSubtitleOriginal:translate:)]) {
        [self.delegate homePageView:self updateSubtitleOriginal:originalSubtitle translate:translateSubtitle];
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

- (void)updateDelayModeSwitchViewHiddenState {
    BOOL hidden = self.audioMode ||
    (![PLVRoomDataManager sharedManager].roomData.menuInfo.watchQuickLive &&
    ![PLVRoomDataManager sharedManager].roomData.menuInfo.watchNoDelay &&
     ![PLVRoomDataManager sharedManager].roomData.menuInfo.watchPublicStream);
    if (hidden == self.hiddenDelayModeSwitch) {
        return;
    }
    self.hiddenDelayModeSwitch = hidden;
    if (_moreView) {
        [self.moreView reloadData];
    }
}

/// 更新UI布局的Frame
- (void)updateUIFrame {
    CGFloat buttonWidth = 32.f;
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    
    self.liveRoomInfoView.frame = CGRectMake(15, 10, 118, 36);
    self.backButton.hidden = ![PLVECUtils sharedUtils].isLandscape || (isPad && !self.backButtonShowOnIpad);
    if (fullScreen && !self.backButton.hidden) {
        self.backButton.frame = CGRectMake(15, 16, 24, 24);
        self.liveRoomInfoView.frame = CGRectMake(CGRectGetMaxX(self.backButton.frame) + 8 , 10, 118, 36);
    }
    
    if (self.type == PLVECHomePageType_Live) {
        CGFloat bottomMargin = [PLVECUtils sharedUtils].isLandscape ? 0 : P_SafeAreaBottomEdgeInsets();
        CGFloat rightMargin = [PLVECUtils sharedUtils].isLandscape ? 15 + P_SafeAreaRightEdgeInsets() : 15 ;
        // 聊天室布局
        self.chatroomView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)-bottomMargin);
        // 底部按钮
        self.moreButton.frame = CGRectMake(CGRectGetWidth(self.bounds)-buttonWidth-rightMargin, CGRectGetHeight(self.bounds)-buttonWidth-15-bottomMargin, buttonWidth, buttonWidth);
        self.giftButton.frame = self.moreButton.hidden ? self.moreButton.frame : CGRectMake(CGRectGetMinX(self.moreButton.frame)-48, CGRectGetMinY(self.moreButton.frame), buttonWidth, buttonWidth);
        self.shoppingCartButton.frame = self.giftButton.hidden ? self.giftButton.frame : CGRectMake(CGRectGetMinX(self.giftButton.frame)-48, CGRectGetMinY(self.moreButton.frame), buttonWidth, buttonWidth);
        // 点赞按钮
        self.likeButtonView.frame = CGRectMake(CGRectGetMidX(self.moreButton.frame) - PLVECLikeButtonViewWidth * 0.5, CGRectGetMinY(self.moreButton.frame)-PLVECLikeButtonViewHeight-5, PLVECLikeButtonViewWidth, PLVECLikeButtonViewHeight);
        
        { // 右侧悬浮挂件位置
            CGFloat originX = CGRectGetMinX(self.moreButton.frame);
            CGFloat originY = CGRectGetMinY(self.likeButtonView.frame);
            if (!self.redpackButtonView.hidden) { // 倒计时红包挂件
                originY -= (8 + PLVECRedpackButtonViewHeight);
                self.redpackButtonView.frame = CGRectMake(originX, originY, PLVECRedpackButtonViewWidth, PLVECRedpackButtonViewHeight);
            }
            // 福利抽奖挂件
            if (!self.welfareLotteryWidgetView.hidden) {
                originY -= (8 + self.welfareLotteryWidgetView.widgetSize.height);
                self.welfareLotteryWidgetView.frame = CGRectMake(originX, originY, self.welfareLotteryWidgetView.widgetSize.width, self.welfareLotteryWidgetView.widgetSize.height);
            }
            
            // 抽奖挂件
            if (!self.lotteryWidgetView.hidden) {
                originY -= (8 + self.lotteryWidgetView.widgetSize.height);
                self.lotteryWidgetView.frame = CGRectMake(originX, originY, self.lotteryWidgetView.widgetSize.width, self.lotteryWidgetView.widgetSize.height);
            }
            // 卡片推送挂件
            if (!self.cardPushButtonView.hidden) {
                originY -= (8 + PLVECCardPushButtonViewHeight);
                self.cardPushButtonView.frame = CGRectMake(originX, originY, PLVECCardPushButtonViewWidth, PLVECCardPushButtonViewHeight);
            }
        }
        
        // 网络提示
        CGFloat middleLableWidth = [self.networkQualityMiddleLable sizeThatFits:CGSizeMake(MAXFLOAT, 28)].width + 20;
        self.networkQualityMiddleLable.frame = CGRectMake(CGRectGetWidth(self.bounds) - middleLableWidth - 16, CGRectGetMinY(self.giftButton.frame) - 28 - 8, middleLableWidth, 28);
        self.networkQualityPoorView.frame = CGRectMake(CGRectGetWidth(self.bounds) - CGRectGetWidth(self.networkQualityPoorView.bounds) - 8, CGRectGetMinY(self.giftButton.frame) - 56 - 8, CGRectGetWidth(self.networkQualityPoorView.bounds), 56);
        
        // 判断是否有公告控件 有则适配问卷控件按钮位置
        PLVECBulletinView *bulletinView;
        for (UIView *subview in self.subviews) {
            if (subview && [subview isKindOfClass:[PLVECBulletinView class]]) {
                bulletinView = (PLVECBulletinView *)subview;
            }
        }
        CGFloat questionnaireButtonOriginY = bulletinView ? CGRectGetMaxY(bulletinView.frame) + 10 : CGRectGetMaxY(self.liveRoomInfoView.frame) + 15;
        self.questionnaireButton.frame =  CGRectMake(15, questionnaireButtonOriginY, 68, 28);
        CGFloat padding = 12.0;
        self.pushView.frame = CGRectMake((CGRectGetWidth(self.frame) - padding - 104), CGRectGetMinY(self.shoppingCartButton.frame) - 204 - padding, 104, 204);
    } else if (self.type == PLVECHomePageType_Playback) {
        // 聊天室布局
        self.chatroomView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)-P_SafeAreaBottomEdgeInsets());
        // 底部控件
        self.playbackListButton.frame = CGRectMake(15, CGRectGetHeight(self.bounds) - buttonWidth - P_SafeAreaBottomEdgeInsets(), buttonWidth, buttonWidth);
        self.moreButton.frame = CGRectMake(CGRectGetWidth(self.bounds) - buttonWidth - 15, CGRectGetHeight(self.bounds) - buttonWidth - P_SafeAreaBottomEdgeInsets(), buttonWidth, buttonWidth);
        self.shoppingCartButton.frame = CGRectMake(CGRectGetMinX(self.moreButton.frame) - 48, CGRectGetMinY(self.moreButton.frame), buttonWidth, buttonWidth);
        self.playerContolView.frame = CGRectMake(0, CGRectGetMinY(self.moreButton.frame) - 41, CGRectGetMaxX(self.moreButton.frame), 41);
        
        CGFloat widgetOriginY = CGRectGetMinY(self.playerContolView.frame);
        // 福利抽奖挂件
        if (!self.welfareLotteryWidgetView.hidden) {
            widgetOriginY -= (self.welfareLotteryWidgetView.widgetSize.height + 8);
            self.welfareLotteryWidgetView.frame = CGRectMake(CGRectGetMidX(self.moreButton.frame) - self.welfareLotteryWidgetView.widgetSize.width/2, widgetOriginY, self.welfareLotteryWidgetView.widgetSize.width, self.welfareLotteryWidgetView.widgetSize.height);
        }
        // 抽奖挂件
        if (!self.lotteryWidgetView.hidden) {
            widgetOriginY -= (self.lotteryWidgetView.widgetSize.height + 8);
            self.lotteryWidgetView.frame = CGRectMake(CGRectGetMidX(self.moreButton.frame) - self.lotteryWidgetView.widgetSize.width/2, widgetOriginY, self.lotteryWidgetView.widgetSize.width, self.lotteryWidgetView.widgetSize.height);
        }
        // 卡片推送挂件
        if (!self.cardPushButtonView.hidden) {
            widgetOriginY -= (PLVECCardPushButtonViewHeight + 8);
            self.cardPushButtonView.frame = CGRectMake(CGRectGetMidX(self.moreButton.frame) - PLVECCardPushButtonViewWidth/2, widgetOriginY, PLVECCardPushButtonViewWidth, PLVECCardPushButtonViewHeight);
        }
        
        CGFloat padding = 12.0;
        self.pushView.frame = CGRectMake((CGRectGetWidth(self.frame) - padding - 104), CGRectGetMinY(self.shoppingCartButton.frame) - 204 - padding, 104, 204);
        [self.playbackListVC viewWillLayoutSubviews];
    }
    [self.commodityVC viewWillLayoutSubviews];
    
    CGFloat height = 130 + P_SafeAreaBottomEdgeInsets();
    self.moreView.frame = [PLVECUtils sharedUtils].isLandscape ? CGRectMake(CGRectGetWidth(self.bounds) - 375, 0, 375, CGRectGetHeight(self.bounds)) : CGRectMake(0, CGRectGetHeight(self.bounds)-height, CGRectGetWidth(self.bounds), height);
    if ([PLVECUtils sharedUtils].isLandscape){
        self.pipPopView.frame = self.moreView.frame;
    }
    else{
        CGFloat viewH = 266;
        self.pipPopView.frame = CGRectMake(0, self.bounds.size.height - viewH, self.bounds.size.width, viewH);
    }
    
    self.pinMsgPopupView.frame = CGRectMake((self.bounds.size.width - 320)/2, (fullScreen ? 47 : 80), 320, 66);

    CGFloat onlineListButtonWidth = [self.onlineListButton.titleLabel sizeThatFits:CGSizeMake(MAXFLOAT,23)].width + 16;
    self.onlineListButton.frame = fullScreen ? CGRectMake(CGRectGetWidth(self.bounds) - onlineListButtonWidth - 40, 15, onlineListButtonWidth, 23) : CGRectMake(CGRectGetWidth(self.bounds) - onlineListButtonWidth - 63, 15, onlineListButtonWidth, 23);
}

- (void)updateLikeViewAnimationLeftShift {
    self.likeButtonView.animationLeftShift = !self.cardPushButtonView.hidden || !self.redpackButtonView.hidden || !self.lotteryWidgetView.hidden || !self.welfareLotteryWidgetView.hidden;
}

- (void)playbackTimeChanged {
    [self.chatroomView playbackTimeChanged];
}

- (void)showSubtitleSelectionView {
    if (!self.subtitleConfigView) {
        self.subtitleConfigView = [[PLVECSubtitleConfigView alloc] initWithSheetHeight:190.0 sheetLandscapeWidth:375.0];
        self.subtitleConfigView.delegate = self;
        // 使用当前可用的字幕列表数据
        PLVPlaybackVideoInfoModel *videoInfo = [PLVRoomDataManager sharedManager].roomData.playbackVideoInfo;
        [self.subtitleConfigView setupWithSubtitleList:videoInfo.availableSubtitleList];
    }
    
    [self.subtitleConfigView showInView:self];
}

#pragma mark 快直播

- (void)switchToNoDelayWatchMode:(BOOL)noDelayWatchMode {
    self.networkQualityMiddleViewShowed = self.networkQualityPoorViewShowed = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(homePageView:switchToNoDelayWatchMode:)]) {
        [self.delegate homePageView:self switchToNoDelayWatchMode:noDelayWatchMode];
    }
}

#pragma mark - Action

- (void)moreButtonAction:(id)sender {
    [self showMoreView];
}

- (void)giftButtonAction:(id)sender {
    if ([PLVECChatroomViewModel sharedViewModel].enableReward) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(homePageViewOpenRewardView:)]) {
            [self.delegate homePageViewOpenRewardView:self];
        }
    }
}

- (void)shoppingCardButtonAction:(id)sender {
    if (self.commodityVC) {
        self.commodityVC = nil;
    }
    PLVECCommodityViewController *commodityVC = [[PLVECCommodityViewController alloc] init];
    commodityVC.delegate = self;
    commodityVC.providesPresentationContextTransitionStyle = YES;
    commodityVC.definesPresentationContext = YES;
    commodityVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [[PLVFdUtil getCurrentViewController] presentViewController:commodityVC animated:YES completion:nil];
    
    self.commodityVC = commodityVC;
}

- (void)playbackListButtonAction:(id)sender {
    if (self.playbackListVC) {
        self.playbackListVC = nil;
    }
    PLVECPlaybackListViewController *playbackListVC = [[PLVECPlaybackListViewController alloc] init];
    playbackListVC.providesPresentationContextTransitionStyle = YES;
    playbackListVC.definesPresentationContext = YES;
    playbackListVC.modalPresentationStyle =UIModalPresentationOverCurrentContext;
    [[PLVFdUtil getCurrentViewController] presentViewController:playbackListVC animated:YES completion:nil];
    
    self.playbackListVC = playbackListVC;
}

- (void)questionnaireButtonAction:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(homePageView_openInteractApp:eventName:)]) {
        [self.delegate homePageView_openInteractApp:self eventName:self.questionnaireEventName];
    }
}

- (void)backButtonAction:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(homePageViewWannaBackToVerticalScreen:)]) {
        [self.delegate homePageViewWannaBackToVerticalScreen:self];
    }
}

- (void)swithDelayLiveClick {
    [self switchToNoDelayWatchMode:NO];
    self.networkQualityPoorView.hidden = YES;
}

- (void)closeNetworkTipsViewClick:(UIButton *)button {
    self.networkQualityPoorView.hidden = YES;
}

- (void)onlineListButtonAction:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(homePageViewWannaShowOnlineList:)]) {
        [self.delegate homePageViewWannaShowOnlineList:self];
    }
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
    
    if ([event isEqualToString:@"newsPush"]) {
        [self newsPushEvent:jsonDict];
    } else if ([event isEqualToString:@"product"]) {
        if ([subEvent isEqualToString:@"PRODUCT_CLICK_TIMES"]) {
            NSDictionary *jsonDict = (NSDictionary *)object;
            if ([PLVFdUtil checkDictionaryUseable:jsonDict]) {
                [self.pushView updateProductClickTimes:jsonDict];
            }
        }
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

- (void)showInScreen:(BOOL)show {
    self.visiable = show;
    if (show && _pushView.alpha == 1) {
        [self.pushView reportTrackEvent];
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
    NSInteger status = PLV_SafeIntegerForDictKey(jsonDict, @"status");
    
    if (status == 10) {
        // 收到 开启/关闭商品列表 消息时进行处理
        NSDictionary *contentDict = PLV_SafeDictionaryForDictKey(jsonDict, @"content");
        NSString *enabledString = PLV_SafeStringForDictKey(contentDict, @"enabled");
        BOOL enabled = [enabledString isEqualToString:@"N"]?NO:YES;
        if (!enabled && _pushView) { // 收到 关闭商品列表 消息时进行处理
            [ _pushView hide];
        }
        [self showShoppingCart:enabled];
    } else if (self.shoppingCartButton.isHidden) {
        return; // 未开启商品功能
    }
    
    if (9 == status) {
        NSDictionary *content = PLV_SafeDictionaryForDictKey(jsonDict, @"content");
        PLVCommodityModel *model = [PLVCommodityModel commodityModelWithDict:content];
        if (![PLVFdUtil checkStringUseable:model.productPushRule]) {
            return;
        }
        
        if ([model.productPushRule isEqualToString:@"smallCard"]) {
            CGFloat padding = 12.0;
            __weak typeof(self)weakSelf = self;
            plv_dispatch_main_async_safe(^{
                [weakSelf.pushView setModel:model];
                [weakSelf.pushView showOnView:weakSelf initialFrame:CGRectMake((CGRectGetWidth(weakSelf.frame) - padding - 104), CGRectGetMinY(weakSelf.shoppingCartButton.frame) - 204 - padding, 104, 204)];
            })
            if (self.visiable) {
                [self.pushView reportTrackEvent];
            }
        } else {
            [_pushView hide];
        }
    } else if (status == 3 || status == 2 || status == 11) { // 收到 删除/下架/取消推送商品 消息时进行处理
        [ _pushView hide];
    } else if (status == 5) { // 收到 商品信息变动 消息时进行处理
        NSDictionary *content = PLV_SafeDictionaryForDictKey(jsonDict, @"content");
        PLVCommodityModel *model = [PLVCommodityModel commodityModelWithDict:content];
        if (model.productId && self.pushView.model.productId && self.pushView.model.productId == model.productId) {            [self.pushView setModel:model];
        }
    }
}

- (void)newsPushEvent:(NSDictionary *)jsonDict {
    NSString *newsPushEvent = PLV_SafeStringForDictKey(jsonDict, @"EVENT");
    if ([PLVFdUtil checkStringUseable:newsPushEvent]) {
        BOOL start = [newsPushEvent isEqualToString:@"start"];
        [self.cardPushButtonView startCardPush:start cardPushInfo:jsonDict];
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
    PLVLiveVideoChannelMenuInfo *menuInfo = [PLVRoomDataManager sharedManager].roomData.menuInfo;
    if ([menuInfo.playbackProgressBarOperationType isEqualToString:@"dragHistoryOnly"]) { // 对进度拖拽进行部分限制
        NSTimeInterval playbackMaxPosition = 0.0;
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(homePageView_playbackMaxPosition:)]) {
            playbackMaxPosition = [self.delegate homePageView_playbackMaxPosition:self];
        }
        NSTimeInterval max = MAX(playbackMaxPosition, self.currentPlaybackTime);
        if (interval > max) { // 不符合允许拖拽的条件
            return;
        }
    } else if ([menuInfo.playbackProgressBarOperationType isEqualToString:@"prohibitDrag"]) {
        return;
    }
    
    // 拖动进度条后，同步当前进度时间
    [self updateDowloadProgress:0
                 playedProgress:playerContolView.progressSlider.value
                       duration:self.duration
    currentPlaybackTimeInterval:interval
            currentPlaybackTime:[PLVFdUtil secondsToString:interval]
                   durationTime:self.playerContolView.totalTimeLabel.text];
    
    if ([self.delegate respondsToSelector:@selector(homePageView:seekToTime:)]) {
        [self.delegate homePageView:self seekToTime:interval];
    }
    
    [self playbackTimeChanged];
}

#pragma mark PLVCommodityPushSmallCardViewDelegate

- (void)PLVCommodityPushSmallCardViewDidClickCommodityDetail:(PLVCommodityModel *)commodity {
    if (self.delegate && [self.delegate respondsToSelector: @selector(homePageView:didClickCommodityDetail:)]) {
        [self.delegate homePageView:self didClickCommodityDetail:commodity];
    }
}

- (void)PLVCommodityPushSmallCardViewDidShowJobDetail:(NSDictionary *)data {
    if (self.delegate && [self.delegate respondsToSelector:@selector(homePageView:didShowJobDetail:)]) {
        [self.delegate homePageView:self didShowJobDetail:data];
    }
}

- (void)PLVCommodityPushSmallCardViewDidClickCommodityDetailPopup:(PLVCommodityModel *)commodity {
    if (self.delegate && [self.delegate respondsToSelector: @selector(homePageView:didClickCommodityDetailPopup:)]) {
        [self.delegate homePageView:self didClickCommodityDetailPopup:commodity];
    }
}

- (void)PLVCommodityPushSmallCardViewDidClickExplained:(PLVCommodityModel *)commodity {
    if (self.delegate && [self.delegate respondsToSelector: @selector(homePageView:didClickCommodityExplained:)]) {
        [self.delegate homePageView:self didClickCommodityExplained:commodity];
    }
}

#pragma mark PLVECCommodityViewControllerDelegate

- (void)plvECCommodityViewController:(PLVECCommodityViewController *)viewController didClickCommodityModel:(PLVCommodityModel *)commodity {
    if (self.delegate && [self.delegate respondsToSelector: @selector(homePageView:didClickCommodityDetail:)]) {
        [self.delegate homePageView:self didClickCommodityDetail:commodity];
    }
}

- (void)plvECCommodityViewController:(PLVECCommodityViewController *)viewController didClickExplainedCommodityModel:(PLVCommodityModel *)commodity {
    if (self.delegate && [self.delegate respondsToSelector: @selector(homePageView:didClickCommodityExplained:)]) {
        [self.delegate homePageView:self didClickCommodityExplained:commodity];
    }
}

- (void)plvECCommodityViewController:(PLVECCommodityViewController *)viewController didShowJobDetail:(NSDictionary *)data {
    if (self.delegate && [self.delegate respondsToSelector:@selector(homePageView:didShowJobDetail:)]) {
        [self.delegate homePageView:self didShowJobDetail:data];
    }
}

- (void)plvECCommodityViewController:(PLVECCommodityViewController *)viewController didShowProductDetail:(NSDictionary *)data {
    if (self.delegate && [self.delegate respondsToSelector:@selector(homePageView:didShowProductDetail:)]) {
        [self.delegate homePageView:self didShowProductDetail:data];
    }
}

#pragma mark PLVECChatroomViewDelegate

- (void)chatroomView_loadRewardEnable:(BOOL)rewardEnable payWay:(NSString * _Nullable)payWay rewardModelArray:(NSArray *_Nullable)modelArray pointUnit:(NSString * _Nullable)pointUnit {
    self.giftButton.hidden = !rewardEnable;
    [self updateUIFrame];
    if (self.delegate && [self.delegate respondsToSelector:@selector(homePageView_loadRewardEnable:payWay:rewardModelArray:pointUnit:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate homePageView_loadRewardEnable:rewardEnable payWay:payWay rewardModelArray:modelArray pointUnit:pointUnit];
        });
    }
}

- (NSTimeInterval)chatroomView_currentPlaybackTime {
    return self.currentPlaybackTime;
}

- (void)chatroomView_didLoginRestrict {
    if (self.delegate && [self.delegate respondsToSelector:@selector(homePageView_didLoginRestrict)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate homePageView_didLoginRestrict];
        });
    }
}

- (void)chatroomView_alertLongContentMessage:(PLVChatModel *)model {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(homePageView_alertLongContentMessage:)]) {
        [self.delegate homePageView_alertLongContentMessage:model];
    }
}

- (void)chatroomView_checkRedpackStateResult:(PLVRedpackState)state chatModel:(PLVChatModel *)model {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(homePageView_checkRedpackStateResult:chatModel:)]) {
        [self.delegate homePageView_checkRedpackStateResult:state chatModel:model];
    }
}

- (void)chatroomView_showDelayRedpackWithType:(PLVRedpackMessageType)type delayTime:(NSInteger)delayTime {
    if (type != PLVRedpackMessageTypeAliPassword) {
        return;
    }
    
    BOOL showFirst = (self.redpackButtonView.hidden == YES);
    [self.redpackButtonView showWithRedpackMessageType:type delayTime:delayTime];
    if (showFirst) {
        [self updateUIFrame];
    }
    [self updateLikeViewAnimationLeftShift];
}

- (void)chatroomView_hideDelayRedpack {
    [self.redpackButtonView dismiss];
    [self updateUIFrame];
    [self updateLikeViewAnimationLeftShift];
}

- (void)chatroomView_receiveSpeakTopMessageChatModel:(PLVChatModel *)model showPinMsgView:(BOOL)show {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(homePageView_receiveSpeakTopMessageChatModel:showPinMsgView:)]) {
        [self.delegate homePageView_receiveSpeakTopMessageChatModel:model showPinMsgView:show];
    }
}

#pragma mark PLVECMoreViewDelegate

- (NSArray<PLVECMoreViewItem *> *)dataSourceOfMoreView:(PLVECMoreView *)moreView {
    NSMutableArray *muArray = [[NSMutableArray alloc] initWithCapacity:3];
    
    BOOL inLinkMic = YES;
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(homePageView_inLinkMic:)]) {
        inLinkMic = [self.delegate homePageView_inLinkMic:self];
    }
    BOOL canEnablePictureInPicture = [PLVRoomDataManager sharedManager].roomData.canSupportPictureInPicure;
    if (!inLinkMic && self.isPlaying && self.type == PLVECHomePageType_Live) {
        if (!self.noDelayWatchMode) {
            PLVECMoreViewItem *item1 = [[PLVECMoreViewItem alloc] init];
            item1.title = PLVLocalizedString(PLVECHomePageView_Data_AudioModeItemTitle);
            item1.selectedTitle = PLVLocalizedString(@"视频模式");
            item1.iconImageName = @"plv_audioSwitch_btn";
            item1.selectedIconImageName = @"plv_videoSwitch_btn";
            item1.selected = self.audioMode;
            [muArray addObject:item1];
        }
        
        if (!self.noDelayWatchMode && self.lineCount > 1) {
            PLVECMoreViewItem *item2 = [[PLVECMoreViewItem alloc] init];
            item2.title = PLVLocalizedString(PLVECHomePageView_Data_RouteItemTitle);
            item2.iconImageName = @"plv_lineSwitch_btn";
            [muArray addObject:item2];
        }
        
        if (!self.noDelayWatchMode && !self.hiddenCodeRateSwitch) {
            PLVECMoreViewItem *item3 = [[PLVECMoreViewItem alloc] init];
            item3.title = PLVLocalizedString(PLVECHomePageView_Data_QualityItemTitle);
            item3.iconImageName = @"plv_codeRateSwitch_btn";
            [muArray addObject:item3];
        }
        
        if (!self.hiddenDelayModeSwitch) {
            PLVECMoreViewItem *item4 = [[PLVECMoreViewItem alloc] init];
            item4.title = PLVLocalizedString(PLVECHomePageView_Data_DelayModeItemTitle);
            item4.iconImageName = @"plv_delayModeSwitch_btn";
            [muArray addObject:item4];
        }
        
        if (canEnablePictureInPicture &&
            ![PLVLivePictureInPictureManager sharedInstance].pictureInPictureActive) {
            PLVECMoreViewItem *item5 = [[PLVECMoreViewItem alloc] init];
            item5.title = PLVLocalizedString(PLVECHomePageView_Data_PictureInPictureItemTitle);
            item5.iconImageName = @"plv_pictureInPictureSwitch_btn";
            [muArray addObject:item5];
        }
    } else if (canEnablePictureInPicture && self.type == PLVECHomePageType_Playback ) {
        PLVECMoreViewItem *item5 = [[PLVECMoreViewItem alloc] init];
        item5.title = PLVLocalizedString(PLVECHomePageView_Data_PictureInPictureItemTitle);
        item5.iconImageName = @"plv_pictureInPictureSwitch_btn";
        [muArray addObject:item5];
    }
    
    if (self.type == PLVECHomePageType_Playback && [PLVRoomDataManager sharedManager].roomData.menuInfo.playbackMultiplierEnabled) {
        PLVECMoreViewItem *speedItem = [[PLVECMoreViewItem alloc] init];
        speedItem.title = PLVLocalizedString(PLVECHomePageView_Data_PlaySpeedItemTitle);
        speedItem.iconImageName = @"plvec_live_playspeed_btn";
        speedItem.selectedIconImageName = @"plvec_live_playspeed_btn";
        [muArray addObject:speedItem];
    }
    
    // 字幕选项（仅回放场景显示）
    if (self.type == PLVECHomePageType_Playback) {
        // 如果有字幕数据 才添加选项
        PLVPlaybackVideoInfoModel *videoInfo = [PLVRoomDataManager sharedManager].roomData.playbackVideoInfo;
        if (videoInfo.availableSubtitleList.count > 0) {
        PLVECMoreViewItem *subtitleItem = [[PLVECMoreViewItem alloc] init];
        subtitleItem.title = PLVLocalizedString(PLVECHomePageView_Data_SubtitleItemTitle);
            subtitleItem.iconImageName = @"plvec_live_subtitle_btn";
            subtitleItem.selectedIconImageName = @"plvec_live_subtitle_btn";
            [muArray addObject:subtitleItem];
        }
    }
    
    // 小窗播放交互设置
    if (canEnablePictureInPicture){
        PLVECMoreViewItem *itemPlaySet = [[PLVECMoreViewItem alloc] init];
        itemPlaySet.title = PLVLocalizedString(PLVECHomePageView_Data_PictureInPicturePlaySetItemTitle);
        itemPlaySet.iconImageName = @"plvec_live_pipinpic_playset";
        itemPlaySet.selectedIconImageName = @"plvec_live_pipinpic_playset";
        [muArray addObject:itemPlaySet];
    }
        
    // 语言切换
    PLVECMoreViewItem *item6 = [[PLVECMoreViewItem alloc] init];
    item6.title = PLVLocalizedString(PLVECHomePageView_Data_SwitchLanguageItemTitle);
    item6.iconImageName = @"plvec_live_languageswitch_btn";
    item6.selectedIconImageName = @"plvec_live_languageswitch_btn";
    item6.selected = ([PLVMultiLanguageManager sharedManager].currentLanguage != PLVMultiLanguageModeZH);
    [muArray addObject:item6];
    
    if ([PLVFdUtil checkArrayUseable:self.interactButtonArray]) {
        for (NSInteger index = 0; index < self.interactButtonArray.count; index++) {
            NSDictionary *dict = self.interactButtonArray[index];
            if ([PLVFdUtil checkDictionaryUseable:dict]) {
                BOOL isShow = PLV_SafeBoolForDictKey(dict, @"isShow");
                if (isShow) {
                    PLVECMoreViewItem *interactItem = [[PLVECMoreViewItem alloc] init];
                    interactItem.title = PLV_SafeStringForDictKey(dict, @"title");
                    interactItem.iconURLString = PLV_SafeStringForDictKey(dict, @"icon");
                    [muArray addObject:interactItem];
                }
            }
        }
    }

    return [muArray copy];
}

- (void)moreView:(PLVECMoreView *)moreView didSelectItem:(PLVECMoreViewItem *)item {
    NSString *title = item.title;
    if ([title isEqualToString:PLVLocalizedString(PLVECHomePageView_Data_AudioModeItemTitle)]) {
        if ([self.delegate respondsToSelector:@selector(homePageView:switchAudioMode:)]) {
            [self.delegate homePageView:self switchAudioMode:item.isSelected];
        }
        self.audioMode = item.isSelected;
        [self updateCodeRateSwitchViewHiddenState];
        [self updateDelayModeSwitchViewHiddenState];
    } else if ([title isEqualToString:PLVLocalizedString(PLVECHomePageView_Data_RouteItemTitle)] ||
               [title isEqualToString:PLVLocalizedString(PLVECHomePageView_Data_QualityItemTitle)] ||
               [title isEqualToString:PLVLocalizedString(PLVECHomePageView_Data_DelayModeItemTitle)] ) {
        moreView.hidden = YES;
        PLVECSwitchViewType switchViewType = PLVECSwitchViewType_Unknown;
        if ([title isEqualToString:PLVLocalizedString(PLVECHomePageView_Data_RouteItemTitle)]) {
            switchViewType = PLVECSwitchViewType_Line;
        } else if ([title isEqualToString:PLVLocalizedString(PLVECHomePageView_Data_QualityItemTitle)]) {
            switchViewType = PLVECSwitchViewType_CodeRate;
        } else if ([title isEqualToString:PLVLocalizedString(PLVECHomePageView_Data_DelayModeItemTitle)]) {
            switchViewType = PLVECSwitchViewType_DelayMode;
        }
        [self updateSwitchView:switchViewType];
    } else if ([title isEqualToString:PLVLocalizedString(PLVECHomePageView_Data_PictureInPictureItemTitle)]) {
        moreView.hidden = YES;
        if (self.delegate && [self.delegate respondsToSelector:@selector(homePageViewClickPictureInPicture:)]) {
            [self.delegate homePageViewClickPictureInPicture:self];
        }
    } else if ([title isEqualToString:PLVLocalizedString(PLVECHomePageView_Data_PlaySpeedItemTitle)]) {
        moreView.hidden = YES;
        [self updateSwitchView:PLVECSwitchViewType_Speed];
    } else if ([title isEqualToString:PLVLocalizedString(PLVECHomePageView_Data_SubtitleItemTitle)]) {
        moreView.hidden = YES;
        [self showSubtitleSelectionView];
    } else if ([title isEqualToString:PLVLocalizedString(PLVECHomePageView_Data_SwitchLanguageItemTitle)]) {
        moreView.hidden = YES;
        __weak typeof(self) weakSelf = self;
        [PLVActionSheet showActionSheetWithTitle:nil cancelBtnTitle:PLVLocalizedString(@"取消") destructiveBtnTitle:nil otherBtnTitles:@[@"简体中文-ZH", @"English-EN", @"繁體中文-ZH", @"日本語-JA", @"한국어-KO"] handler:^(PLVActionSheet * _Nonnull actionSheet, NSInteger index) {
            if (index > 0) {
                PLVMultiLanguageMode selectedLanguage = PLVMultiLanguageModeZH;
                switch (index) {
                    case 1:
                        selectedLanguage = PLVMultiLanguageModeZH;
                        break;
                    case 2:
                        selectedLanguage = PLVMultiLanguageModeEN;
                        break;
                    case 3:
                        selectedLanguage = PLVMultiLanguageModeZH_HK;
                        break;
                    case 4:
                        selectedLanguage = PLVMultiLanguageModeJA;
                        break;
                    case 5:
                        selectedLanguage = PLVMultiLanguageModeKO;
                        break;
                    default:
                        break;
                }
                if (selectedLanguage != [PLVMultiLanguageManager sharedManager].currentLanguage) {
                    if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(homePageView:switchLanguageMode:)]) {
                        [weakSelf.delegate homePageView:weakSelf switchLanguageMode:selectedLanguage];
                    }
                }
            }
        }];
    } else if ([title isEqualToString:PLVLocalizedString(PLVECHomePageView_Data_PictureInPicturePlaySetItemTitle)]) {
        // 小窗交互设置
        self.moreView.hidden = YES;
        self.pipPopView.hidden = NO;
        self.pipPopView.exitRoomState = ![PLVRoomDataManager sharedManager].roomData.disableStartPipWhenExitLiveRoom;
        self.pipPopView.enterBackState = ![PLVRoomDataManager sharedManager].roomData.disableStartPipWhenEnterBackground;
    }
    else {
        __block NSString *eventName;
        [self.interactButtonArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([PLVFdUtil checkDictionaryUseable:obj]) {
                NSString *buttonTitle = PLV_SafeStringForDictKey(obj, @"title");
                if ([title isEqualToString:buttonTitle]) {
                    eventName = PLV_SafeStringForDictKey(obj, @"event");
                    *stop = YES;
                }
            }
        }];
        if ([PLVFdUtil checkStringUseable:eventName] && self.delegate && [self.delegate respondsToSelector:@selector(homePageView_openInteractApp:eventName:)]) {
            [self.delegate homePageView_openInteractApp:self eventName:eventName];
        }
    }
}

- (void)updateSwitchView:(PLVECSwitchViewType)switchViewType {
    if (switchViewType == PLVECSwitchViewType_Unknown) {
        return;
    }
    self.switchViewType = switchViewType;
    if (switchViewType == PLVECSwitchViewType_Line) {
        self.switchView.titleLable.text = PLVLocalizedString(@"切换线路");
        self.switchView.selectedIndex = self.curlineIndex;
    } else if (switchViewType == PLVECSwitchViewType_CodeRate) {
        self.switchView.titleLable.text = PLVLocalizedString(@"切换清晰度");
        self.switchView.selectedIndex = self.curCodeRateIndex;
    } else if (switchViewType == PLVECSwitchViewType_Speed) {
        self.switchView.titleLable.text = PLVLocalizedString(PLVECHomePageView_Data_PlaySpeedItemTitle);
        self.switchView.selectedIndex = self.curSpeedIndex;
    } else if (switchViewType == PLVECSwitchViewType_DelayMode) {
        self.switchView.titleLable.text = PLVLocalizedString(@"模式");
        self.switchView.selectedIndex = self.curDelayModeIndex;
    }
    [self.switchView reloadData];
}

#pragma mark PLVPlayerSwitchViewDelegate

- (NSArray<NSString *> *)dataSourceOfSwitchView:(PLVECSwitchView *)switchView {
    if (self.switchViewType == PLVECSwitchViewType_Line) {
        NSMutableArray *mArr = [NSMutableArray array];
        for (int i = 1; i <= self.lineCount; i ++) {
            [mArr addObject:[NSString stringWithFormat:PLVLocalizedString(@"线路%d"),i]];
        }
        return [mArr copy];
    } else if (self.switchViewType == PLVECSwitchViewType_CodeRate) {
        return self.codeRateItems;
    } else if (self.switchViewType == PLVECSwitchViewType_Speed) {
        if (@available(iOS 15.0, *)) {
            return @[@"0.5x", @"0.75x", @"1.0x", @"1.25x", @"1.5x", @"2.0x", @"3.0x"];
        } else {
            return @[@"0.5x", @"0.75x", @"1.0x", @"1.25x", @"1.5x", @"2.0x"];
        }
    } else if (self.switchViewType == PLVECSwitchViewType_DelayMode) {
        return @[PLVLocalizedString(@"无延迟"), PLVLocalizedString(@"正常延迟")];
    } else {
        return @[];
    }
}

- (void)playerSwitchView:(PLVECSwitchView *)playerSwitchView
        didSelectedIndex:(NSUInteger)selectedIndex
            selectedItem:(NSString *)selectedItem {
    if (self.switchViewType == PLVECSwitchViewType_Line) {
        self.curlineIndex = selectedIndex;
        if (self.delegate && [self.delegate respondsToSelector:@selector(homePageView:switchPlayLine:)]) {
            [self.delegate homePageView:self switchPlayLine:self.curlineIndex];
        }
    } else if (self.switchViewType == PLVECSwitchViewType_CodeRate) {
        self.curCodeRateIndex = selectedIndex;
        if (self.delegate && [self.delegate respondsToSelector:@selector(homePageView:switchCodeRate:)]) {
            [self.delegate homePageView:self switchCodeRate:selectedItem];
        }
    } else if (self.switchViewType == PLVECSwitchViewType_Speed) {
        self.curSpeedIndex = selectedIndex;
        CGFloat speed = selectedItem.floatValue;
        if (@available(iOS 15.0, *)) {
            speed = MIN(3.0, MAX(0.5, speed));
        } else {
            speed = MIN(2.0, MAX(0.5, speed));
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(homePageView:switchSpeed:)]) {
            [self.delegate homePageView:self switchSpeed:speed]; // PLVPlayerPresenter会自动保存速度
        }
    } else if (self.switchViewType == PLVECSwitchViewType_DelayMode) {
        self.curDelayModeIndex = selectedIndex;
        [self switchToNoDelayWatchMode:selectedIndex == 0];
    }
}

#pragma mark PLVECCardPushButtonViewDelegate

- (void)cardPushButtonView:(PLVECCardPushButtonView *)pushButtonView needOpenInteract:(NSDictionary *)dict {
    if (self.delegate && [self.delegate respondsToSelector:@selector(homePageView:openCardPush:)]) {
        [self.delegate homePageView:self openCardPush:dict];
    }
}

- (void)cardPushButtonView:(PLVECCardPushButtonView *)pushButtonView showStatusChanged:(BOOL)show {
    [self updateLikeViewAnimationLeftShift];
    [self updateUIFrame];
}

- (void)cardPushButtonViewPopupViewDidShow:(PLVECCardPushButtonView *)pushButtonView {
    [self.lotteryWidgetView hidePopupView];
    [self.welfareLotteryWidgetView hidePopupView];
}

#pragma mark PLVECLotteryWidgetViewDelegate
- (void)lotteryWidgetViewDidClickAction:(PLVECLotteryWidgetView *)lotteryWidgetView eventName:(NSString *)eventName {
    if (self.delegate && [self.delegate respondsToSelector:@selector(homePageView:emitInteractEvent:)]) {
        [self.delegate homePageView:self emitInteractEvent:eventName];
    }
}

- (void)lotteryWidgetView:(PLVECLotteryWidgetView *)lotteryWidgetView showStatusChanged:(BOOL)show {
    [self updateUIFrame];
}

- (void)lotteryWidgetViewPopupViewDidShow:(PLVECLotteryWidgetView *)lotteryWidgetView {
    [self.cardPushButtonView hidePopupView];
}

#pragma mark PLVECWelfareLotteryWidgetViewDelegate

- (void)welfareLotteryWidgetViewDidClickAction:(PLVECWelfareLotteryWidgetView *)welfareLotteryWidgetView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(homePageViewWannaShowWelfareLottery:)]) {
        [self.delegate homePageViewWannaShowWelfareLottery:self];
    }
}

- (void)welfareLotteryWidgetView:(PLVECWelfareLotteryWidgetView *)welfareLotteryWidgetView showStatusChanged:(BOOL)show {
    [self updateUIFrame];
    if (self.delegate && [self.delegate respondsToSelector:@selector(homePageView:welfareLotteryWidgetShowStatusChanged:)]) {
        [self.delegate homePageView:self welfareLotteryWidgetShowStatusChanged:show];
    }
}

- (void)welfareLotteryWidgetViewPopupViewDidShow:(PLVECWelfareLotteryWidgetView *)welfareLotteryWidgetView {
    [self.cardPushButtonView hidePopupView];
}

#pragma mark UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if ([[URL scheme] isEqualToString:PLVECHomeSwitchNormalDelayAttributeName]) {
        [self swithDelayLiveClick];
    }
    
    return NO;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    return NO;
}

#pragma mark PLVECSubtitleConfigViewDelegate

- (void)subtitleConfigView:(PLVECSubtitleConfigView *)configView 
    didUpdateSubtitleOriginal:(PLVPlaybackSubtitleModel *)originalSubtitle 
                    translate:(PLVPlaybackSubtitleModel *)translateSubtitle {
    // 使用统一的字幕更新方法
    [self updateSubtitleWithOriginal:originalSubtitle translate:translateSubtitle];
}

@end
