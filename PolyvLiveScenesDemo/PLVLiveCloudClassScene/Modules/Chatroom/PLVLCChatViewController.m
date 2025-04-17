//
//  PLVLCChatViewController.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCChatViewController.h"
#import "PLVLCKeyboardToolView.h"
#import "PLVLCNewMessageView.h"
#import "PLVLCWelcomeView.h"
#import "PLVLCPlaybackNotifyView.h"
#import "PLVLCNotifyMarqueeView.h"
#import "PLVLCRedpackMessageCell.h"
#import "PLVLCSpeakMessageCell.h"
#import "PLVLCLongContentMessageCell.h"
#import "PLVLCImageMessageCell.h"
#import "PLVLCImageEmotionMessageCell.h"
#import "PLVLCQuoteMessageCell.h"
#import "PLVLCRewardMessageCell.h"
#import "PLVLCFileMessageCell.h"
#import "PLVAlbumNavigationController.h"
#import "PLVGiveRewardPresenter.h"
#import "PLVRewardGoodsModel.h"
#import "PLVRewardDisplayManager.h"
#import "PLVRoomDataManager.h"
#import "PLVLCChatroomViewModel.h"
#import "PLVLCChatroomPlaybackViewModel.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFdUtil.h>
#import <PLVFoundationSDK/PLVColorUtil.h>
#import <MJRefresh/MJRefresh.h>
#import "PLVLCUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVToast.h"
#import <PLVFoundationSDK/PLVAuthorizationManager.h>
#import "PLVImagePickerViewController.h"

NSString *PLVLCChatroomOpenBulletinNotification = @"PLVLCChatroomOpenBulletinNotification";

NSString *PLVLCChatroomOpenInteractAppNotification = @"PLVLCChatroomOpenInteractAppNotification";

NSString *PLVLCChatroomOpenRewardViewNotification = @"PLVLCChatroomOpenRewardViewNotification";

NSString *PLVInteractUpdateChatButtonCallbackNotification = @"PLVInteractUpdateChatButtonCallbackNotification";

@interface PLVLCChatViewController ()<
PLVLCKeyboardToolViewDelegate,
PLVLCLikeButtonViewDelegate,
PLVLCCardPushButtonViewDelegate,
PLVLCLotteryWidgetViewDelegate,
PLVLCChatroomViewModelProtocol,
PLVRoomDataManagerProtocol,
PLVLCChatroomPlaybackViewModelDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
UITableViewDelegate,
UITableViewDataSource
>
/// 是否已完成对子视图的布局，默认为 NO，完成布局后为 YES
@property (nonatomic, assign) BOOL hasLayoutSubView;
/// 聊天列表
@property (nonatomic, strong) UITableView *tableView;
/// 聊天室列表上次滚动结束时的contentOffset
@property (nonatomic, assign) CGPoint lastContentOffset;
/// 聊天室列表顶部加载更多控件
@property (nonatomic, strong) MJRefreshNormalHeader *refresher;
/// 新消息提示条幅
@property (nonatomic, strong) PLVLCNewMessageView *receiveNewMessageView;
/// 未读消息条数
@property (nonatomic, assign) NSUInteger newMessageCount;
/// 聊天室置底控件
@property (nonatomic, strong) PLVLCKeyboardToolView *keyboardToolView;
/// 聊天室顶部欢迎横幅
@property (nonatomic, strong) PLVLCWelcomeView *welcomeView;
/// 聊天室顶部回放功能横幅
@property (nonatomic, strong) PLVLCPlaybackNotifyView *notifyView;
/// 聊天室顶部公告横幅
@property (nonatomic, strong) PLVLCNotifyMarqueeView *notifyMarqueeView;
/// 打赏成功提示条幅
@property (nonatomic, strong) PLVRewardDisplayManager *rewardDisplayManager;
/// 聊天室是否处于聊天回放状态，默认为NO
@property (nonatomic, assign) BOOL playbackEnable;
/// 弱引用首页持有的聊天回放viewModel
@property (nonatomic, weak) PLVLCChatroomPlaybackViewModel *playbackViewModel;
@property (nonatomic, strong) UIImageView *bgImageView; // 默认背景图

@end

@implementation PLVLCChatViewController

#pragma mark - UI 布局

- (void)setupUI {
    self.view.backgroundColor = [PLVColorUtil colorFromHexString:@"#202127"];
    [self.view addSubview:self.bgImageView];
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (roomData.menuInfo.transmitMode &&
        roomData.menuInfo.mainRoom) {
        [self.view addSubview:self.notifyView];
        [self.notifyView showNotifyhMessage:PLVLocalizedString(@"已关联其他房间，仅可观看直播内容")];
    } else {
        [self.view addSubview:self.tableView];
        [self.view addSubview:self.likeButtonView];
        [self.view addSubview:self.redpackButtonView];
        [self.view addSubview:self.cardPushButtonView];
        [self.view addSubview:self.welcomeView];
        [self.view addSubview:self.notifyMarqueeView];
        [self.view addSubview:self.receiveNewMessageView];
        [self.view addSubview:self.notifyView];
        [self.view addSubview:self.lotteryWidgetView];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.bgImageView.frame = self.view.bounds;
     
    if (self.hasLayoutSubView) { // 调整布局
        CGFloat height = [self.keyboardToolView getKeyboardToolViewHeight] + P_SafeAreaBottomEdgeInsets();
        [self refreshTableViewFrame];
        
        CGFloat keyboardToolOriginY = CGRectGetHeight(self.view.bounds) - height;
        [self.keyboardToolView changeFrameForNewOriginY:keyboardToolOriginY];

        // iPad分屏尺寸变动，刷新布局
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            // 聊天区布局调整
            [self.tableView reloadData];

            // 键盘宽度调整 内部控件布局调整
            CGRect rect = self.keyboardToolView.frame;
            rect.size.width = CGRectGetWidth(self.view.bounds);
            self.keyboardToolView.frame = rect;
            [self.keyboardToolView updateTextViewAndButton];
        }
        
        [self refreshReceiveNewMessageViewFrame];
        
        if (![self currentIsFullScreen]) {
            [self refreshFloatingButtonViewFrame];
        }
    }
}

- (void)viewDidLayoutSubviews {
    if (!self.hasLayoutSubView) { // 初次布局
        self.bgImageView.frame = self.view.bounds;
        CGFloat height = [self.keyboardToolView getKeyboardToolViewHeight] + P_SafeAreaBottomEdgeInsets();
        CGRect inputRect = CGRectMake(0, CGRectGetHeight(self.view.bounds) - height, CGRectGetWidth(self.view.bounds), height);
        [self.keyboardToolView addAtView:self.view frame:inputRect];
        self.receiveNewMessageView.frame = CGRectMake(0, inputRect.origin.y - 28, CGRectGetWidth(self.view.bounds), 28);
        [self refreshTableViewFrame];
        self.notifyView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 40);
        
        [self arrangeTopMarqueeViewFrame];
        
        self.hasLayoutSubView = YES;
        
        [self scrollsToBottom:NO];
        [self refreshFloatingButtonViewFrame];
//        [self refreshIarEntranceViewFrame];
    }
}

- (void)refreshFloatingButtonViewFrame {
    CGFloat keyboardToolViewHeight = PLVLCKeyboardToolViewHeight + P_SafeAreaBottomEdgeInsets();
    CGRect keyboardToolViewRect = CGRectMake(0, CGRectGetHeight(self.view.bounds) - keyboardToolViewHeight, CGRectGetWidth(self.view.bounds), keyboardToolViewHeight);
    CGFloat rightPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 20.0 : 16.0; // 右边距
    CGFloat centerPadding = rightPadding + 40.0 / 2.0; // 40pt宽的按钮屏幕右间距为rightPadding，悬浮按钮都跟40pt宽的按钮垂直对齐
    CGFloat buttonYPadding = 12.0; // 悬浮按钮之间垂直间隔17pt
    CGFloat originX = 0;
    CGFloat originY = keyboardToolViewRect.origin.y;
    
    if (!self.likeButtonView.hidden && self.likeButtonView.superview == self.view) {
        originX = self.view.bounds.size.width - centerPadding - PLVLCLikeButtonViewWidth / 2.0;
        originY -= (buttonYPadding + PLVLCLikeButtonViewHeight);
        self.likeButtonView.frame = CGRectMake(originX, originY, PLVLCLikeButtonViewWidth, PLVLCLikeButtonViewHeight);
    }
    
    if (!self.redpackButtonView.hidden && self.redpackButtonView.superview == self.view) {
        originX = self.view.bounds.size.width - centerPadding - PLVLCRedpackButtonViewWidth / 2.0;
        originY -= (buttonYPadding + PLVLCRedpackButtonViewHeight);
        self.redpackButtonView.frame = CGRectMake(originX, originY, PLVLCRedpackButtonViewWidth, PLVLCRedpackButtonViewHeight);
    }
    
    if (!self.cardPushButtonView.hidden && self.cardPushButtonView.superview == self.view) {
        originX = self.view.bounds.size.width - centerPadding - PLVLCCardPushButtonViewWidth / 2.0;
        originY -= (buttonYPadding + PLVLCCardPushButtonViewHeight);
        self.cardPushButtonView.frame = CGRectMake(originX, originY, PLVLCCardPushButtonViewWidth, PLVLCCardPushButtonViewHeight);
    }
    
    if (!self.lotteryWidgetView.hidden && self.lotteryWidgetView.superview == self.view) {
        originX = self.view.bounds.size.width - centerPadding - self.lotteryWidgetView.widgetSize.width / 2.0;
        originY -= (buttonYPadding + self.lotteryWidgetView.widgetSize.height);
        self.lotteryWidgetView.frame = CGRectMake(originX, originY, self.lotteryWidgetView.widgetSize.width, self.lotteryWidgetView.widgetSize.height);
    }
}

- (void)refreshTableViewFrame {
    CGFloat height = [self.keyboardToolView getKeyboardToolViewHeight] + P_SafeAreaBottomEdgeInsets();
    self.tableView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - height);
    
    [PLVLCChatroomViewModel sharedViewModel].tableViewWidthForV = self.tableView.frame.size.width;
}

- (void)refreshReceiveNewMessageViewFrame {
    self.receiveNewMessageView.frame = CGRectMake(0, self.keyboardToolView.frame.origin.y - 28, CGRectGetWidth(self.view.bounds), 28);
}


#pragma mark - Getter & Setter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.allowsSelection = NO;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.mj_header = self.refresher;
    }
    return _tableView;
}

- (MJRefreshNormalHeader *)refresher {
    if (!_refresher) {
        _refresher = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refreshAction:)];
        _refresher.lastUpdatedTimeLabel.hidden = YES;
        _refresher.stateLabel.hidden = YES;
        [_refresher.loadingView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
    }
    return _refresher;
}

- (PLVLCKeyboardToolView *)keyboardToolView {
    if (!_keyboardToolView) {
        _keyboardToolView = [[PLVLCKeyboardToolView alloc] init];
        _keyboardToolView.delegate = self;
        _keyboardToolView.hiddenBulletin = ([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Playback);
        if ([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Playback) { //回放时不支持发言
            [_keyboardToolView changePlaceholderText:PLVLocalizedString(@"聊天室暂时关闭")];
        }
    }
    return _keyboardToolView;
}

- (PLVLCNewMessageView *)receiveNewMessageView {
    if (!_receiveNewMessageView) {
        _receiveNewMessageView = [[PLVLCNewMessageView alloc] init];
        _receiveNewMessageView.hidden = YES;
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(readNewMessageAction)];
        [_receiveNewMessageView addGestureRecognizer:gesture];
    }
    return _receiveNewMessageView;
}

- (PLVLCLikeButtonView *)likeButtonView {
    if (!_likeButtonView) {
        _likeButtonView = [[PLVLCLikeButtonView alloc] init];
        _likeButtonView.likeCount = [PLVRoomDataManager sharedManager].roomData.likeCount;
        _likeButtonView.delegate = self;
    }
    return _likeButtonView;
}

- (PLVLCRedpackButtonView *)redpackButtonView {
    if (!_redpackButtonView) {
        _redpackButtonView = [[PLVLCRedpackButtonView alloc] init];
    }
    return _redpackButtonView;
}

- (PLVLCCardPushButtonView *)cardPushButtonView {
    if (!_cardPushButtonView) {
        _cardPushButtonView = [[PLVLCCardPushButtonView alloc] init];
        _cardPushButtonView.delegate = self;
    }
    return _cardPushButtonView;
}

- (PLVLCWelcomeView *)welcomeView {
    if (!_welcomeView) {
        _welcomeView = [[PLVLCWelcomeView alloc] init];
    }
    return _welcomeView;
}

- (PLVLCPlaybackNotifyView *)notifyView {
    if (!_notifyView) {
        _notifyView = [[PLVLCPlaybackNotifyView alloc] init];
    }
    return _notifyView;
}

- (PLVLCNotifyMarqueeView *)notifyMarqueeView {
    if (!_notifyMarqueeView) {
        _notifyMarqueeView = [[PLVLCNotifyMarqueeView alloc] init];
    }
    return _notifyMarqueeView;
}

- (PLVLCLotteryWidgetView *)lotteryWidgetView {
    if (!_lotteryWidgetView) {
        _lotteryWidgetView = [[PLVLCLotteryWidgetView alloc] init];
        _lotteryWidgetView.delegate = self;
    }
    return _lotteryWidgetView;
}

- (PLVRewardDisplayManager *)rewardDisplayManager {
    if (!_rewardDisplayManager) {
        _rewardDisplayManager = [[PLVRewardDisplayManager alloc] initWithLiveType:PLVRewardDisplayManagerTypeLC];
        _rewardDisplayManager.superView = self.view;
    }
    return _rewardDisplayManager;
}

- (UIImageView *)bgImageView {
    if (!_bgImageView) {
        NSString *chatBackgroundImage = [PLVRoomDataManager sharedManager].roomData.menuInfo.chatBackgroundImage;
        _bgImageView = [[UIImageView alloc] init];
        _bgImageView.contentMode = UIViewContentModeScaleAspectFill;
        _bgImageView.layer.masksToBounds = YES;
        if ([PLVFdUtil checkStringUseable:chatBackgroundImage]) {
            if ([chatBackgroundImage hasPrefix:@"//"]) {
                chatBackgroundImage = [@"https:" stringByAppendingString:chatBackgroundImage];
            }
            
            int opacity = [PLVRoomDataManager sharedManager].roomData.menuInfo.chatBackgroundImageOpacity.intValue;
            if (opacity> 0 && opacity <= 50) {
                NSString *opacityString = [NSString stringWithFormat:@"?x-oss-process=image/blur,r_%d,s_%d", opacity, opacity];
                chatBackgroundImage = [chatBackgroundImage stringByAppendingString:opacityString];
            }
            
            [_bgImageView sd_setImageWithURL:[NSURL URLWithString:chatBackgroundImage]];
            _bgImageView.hidden = NO;
        } else {
            _bgImageView.hidden = YES;
        }
    }
    return _bgImageView;
}

- (BOOL)enableReward {
    return self.keyboardToolView.enableReward;
}

#pragma mark - Action

- (void)refreshAction:(MJRefreshNormalHeader *)refreshHeader {
    if (self.playbackEnable) {
        [self.playbackViewModel loadMoreMessages];
    } else {
        [[PLVLCChatroomViewModel sharedViewModel] loadHistory];
    }
}

- (void)readNewMessageAction { // 点击底部未读消息条幅时触发
    [self clearNewMessageCount];
    [self scrollsToBottom:YES];
}

#pragma mark - NSNotification

- (void)addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(interfaceOrientationDidChange:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(gotChatroomFunction:)
                                                 name:PLVLCChatroomFunctionGotNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(interactUpdateChatButtonCallback:) name:PLVInteractUpdateChatButtonCallbackNotification
                                               object:nil];
}

- (void)removeObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidChangeStatusBarOrientationNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:PLVLCChatroomFunctionGotNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:PLVInteractUpdateChatButtonCallbackNotification
                                                  object:nil];
}

- (void)interfaceOrientationDidChange:(NSNotification *)notification {
    if (![self currentIsFullScreen]) {
        [self scrollsToBottom:NO];
    }
}

- (void)gotChatroomFunction:(NSNotification *)notification {
    self.keyboardToolView.enableSendImage = ![PLVRoomDataManager sharedManager].roomData.sendImageDisable;
    self.likeButtonView.hidden = [PLVRoomDataManager sharedManager].roomData.sendLikeDisable;
}

- (void)interactUpdateChatButtonCallback:(NSNotification *)notification {
    NSDictionary *dict = notification.userInfo;
    NSArray *buttonDataArray = PLV_SafeArraryForDictKey(dict, @"dataArray");
    [self.keyboardToolView updateChatButtonDataArray:buttonDataArray];
}

#pragma mark - Public Method

- (instancetype)initWithLiveRoom:(UIViewController *)liveRoom {
    self = [super init];
    if (self) {
        [[PLVRoomDataManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        [[PLVRoomDataManager sharedManager].roomData requestChannelFunctionSwitch];
        
        self.liveRoom = liveRoom;
    
        [self setupUI];
        
        // 增加NSNotification监听
        [self addObserver];
        
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        self.playbackEnable = roomData.menuInfo.chatInputDisable && roomData.videoType == PLVChannelVideoType_Playback;
        if (!self.playbackEnable) {
            [[PLVLCChatroomViewModel sharedViewModel] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        }
    }
    return self;
}

- (void)resumeFloatingButtonViewLayout {
    [self.view insertSubview:self.likeButtonView belowSubview:self.receiveNewMessageView];
    [self.view insertSubview:self.redpackButtonView belowSubview:self.receiveNewMessageView];
    [self.view insertSubview:self.cardPushButtonView belowSubview:self.receiveNewMessageView];
    [self.view insertSubview:self.lotteryWidgetView belowSubview:self.receiveNewMessageView];
    
    [self refreshFloatingButtonViewFrame];
}

- (void)updatePlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)playbackViewModel {
    self.playbackViewModel = playbackViewModel;
    [self.playbackViewModel addUIDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (void)leaveLiveRoom {
    [self.cardPushButtonView leaveLiveRoom];
}

- (void)startCardPush:(BOOL)start cardPushInfo:(NSDictionary *)dict callback:(void (^)(BOOL show))callback  {
    __weak typeof(self) weakSelf = self;
    [self.cardPushButtonView startCardPush:start cardPushInfo:dict callback:^(BOOL show) {
        callback ? callback(show) : nil;
        [weakSelf refreshFloatingButtonViewFrame];
    }];
}

- (void)updateLotteryWidgetViewInfo:(NSArray *)dataArray {
    if ([PLVFdUtil checkArrayUseable:dataArray]) {
        [self.lotteryWidgetView updateLotteryWidgetInfo:dataArray.firstObject];
    } else {
        [self.lotteryWidgetView hideWidgetView];
    }
}

#pragma mark - Private Method

- (void)arrangeTopMarqueeViewFrame {
    self.notifyMarqueeView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 40);
    CGFloat welcomeOriginY = self.notifyMarqueeView.hidden ? 0 : 40;
    self.welcomeView.frame = CGRectMake(0, welcomeOriginY, CGRectGetWidth(self.view.bounds), 24);
}

- (void)scrollsToBottom:(BOOL)animated {
    CGFloat offsetY = self.tableView.contentSize.height - self.tableView.bounds.size.height;
    if (offsetY < 0.0) {
        offsetY = 0.0;
    }
    [self.tableView setContentOffset:CGPointMake(0.0, offsetY) animated:animated];
}

- (void)addNewMessageCount {
    self.newMessageCount ++;
    [self.receiveNewMessageView updateMeesageCount:self.newMessageCount];
    [self.receiveNewMessageView show];
}

- (void)clearNewMessageCount {
    if (self.newMessageCount == 0) {
        return ;
    }
    self.newMessageCount = 0;
    [self.receiveNewMessageView hidden];
}

- (void)openCamera {
    [PLVLiveVideoConfig sharedInstance].unableRotate = YES;
    [PLVFdUtil changeDeviceOrientationToPortrait];
    
    UIImagePickerController *cameraVC = [[UIImagePickerController alloc] init];
    cameraVC.delegate = self;
    cameraVC.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self.liveRoom presentViewController:cameraVC animated:YES completion:nil];
}

- (void)presentAlertController:(NSString *)message {
    [PLVAuthorizationManager showAlertWithTitle:nil message:message viewController:self];
}

- (BOOL)currentIsFullScreen {
    return [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
}

// 数据源数目
- (NSInteger)dataCount {
    NSInteger count = 0;
    if (self.playbackEnable) {
        count = [self.playbackViewModel.chatArray count];
    } else {
        count = [[[PLVLCChatroomViewModel sharedViewModel] chatArray] count];
    }
    return count;
}

// 根据indexPath得到数据模型
- (PLVChatModel *)modelAtIndexPath:(NSIndexPath *)indexPath {
    PLVChatModel *model = nil;
    if (self.playbackEnable) {
        if (self.playbackViewModel.chatArray.count > indexPath.row) {
            model = self.playbackViewModel.chatArray[indexPath.row];
        }
    } else {
        if ([[PLVLCChatroomViewModel sharedViewModel] chatArray].count > indexPath.row) {
            model = [[PLVLCChatroomViewModel sharedViewModel] chatArray][indexPath.row];
        }
    }
    return model;
}

// 点击超长文本消息(超过200字符）的【复制】按钮时调用
- (void)pasteFullContentWithModel:(PLVChatModel *)model {
    if ([model isOverLenMsg] && ![PLVFdUtil checkStringUseable:model.overLenContent]) {
        if (!self.playbackEnable) { // 重放时接口返回的消息包含全部文本，不存在超长问题
            [[PLVLCChatroomViewModel sharedViewModel].presenter overLengthSpeakMessageWithMsgId:model.msgId callback:^(NSString * _Nullable content) {
                if (content) {
                    model.overLenContent = content;
                    [UIPasteboard generalPasteboard].string = content;
                    [PLVToast showToastWithMessage:PLVLocalizedString(@"复制成功") inView:self.view afterDelay:3.0];
                }
            }];
        }
    } else {
        NSString *pasteString = [model isOverLenMsg] ? model.overLenContent : model.content;
        if (pasteString) {
            [UIPasteboard generalPasteboard].string = pasteString;
            [PLVToast showToastWithMessage:PLVLocalizedString(@"复制成功") inView:self.view afterDelay:3.0];
        }
    }
}

// 点击超长文本消息(超过500字符）的【更多】按钮时调用
- (void)alertToShowFullContentWithModel:(PLVChatModel *)model {
    __weak typeof(self) weakSelf = self;
    if ([model isOverLenMsg] && ![PLVFdUtil checkStringUseable:model.overLenContent]) {
        if (!self.playbackEnable) { // 重放时接口返回的消息包含全部文本，不存在超长问题
            [[PLVLCChatroomViewModel sharedViewModel].presenter overLengthSpeakMessageWithMsgId:model.msgId callback:^(NSString * _Nullable content) {
                if (content) {
                    model.overLenContent = content;
                    [weakSelf notifyDelegateToAlertChatModel:model];
                }
            }];
        }
    } else {
        NSString *content = [model isOverLenMsg] ? model.overLenContent : model.content;
        if (content) {
            [self notifyDelegateToAlertChatModel:model];
        }
    }
}

- (void)notifyDelegateToAlertChatModel:(PLVChatModel *)model {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(plvLCChatViewController:alertLongContentMessage:)]) {
        [self.delegate plvLCChatViewController:self alertLongContentMessage:model];
    }
}

- (void)didTapReplyMenuItem:(PLVChatModel *)model {
    [self.keyboardToolView replyChatModel:model];
}
     
- (void)didTapRedpackModel:(PLVChatModel *)model {
    [[PLVLCChatroomViewModel sharedViewModel] checkRedpackStateWithChatModel:model];
}

- (void)trackLogAction {
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (fullScreen) {
        return;
    }
    
    NSMutableArray *muArray = [[NSMutableArray alloc] initWithCapacity:self.tableView.indexPathsForVisibleRows.count];
    for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
        CGRect cellRect = [self.tableView rectForRowAtIndexPath:indexPath];
        if (cellRect.origin.y >= self.tableView.contentOffset.y &&
            cellRect.origin.y + cellRect.size.height <= self.tableView.contentOffset.y + self.tableView.frame.size.height) {
            PLVChatModel *model = [self modelAtIndexPath:indexPath];
            if ([PLVLCRedpackMessageCell isModelValid:model]) {
                id message = model.message;
                PLVRedpackMessage *redpackMessage = (PLVRedpackMessage *)message;
                [muArray addObject:redpackMessage];
            }
        }
    }
    
    NSArray *currentVisibleRedpackMessages = [muArray copy];
    if ([currentVisibleRedpackMessages count] > 0) {
        [self trackLog:currentVisibleRedpackMessages];
    }
}

- (void)trackLog:(NSArray <PLVRedpackMessage *> *)redpackMessages {
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    NSMutableArray *muArray = [[NSMutableArray alloc] initWithCapacity:redpackMessages.count];
    for (PLVRedpackMessage *redpackMessage in redpackMessages) {
        NSString *repackTypeString = (redpackMessage.type == PLVRedpackMessageTypeAliPassword) ? @"alipay_password_official_normal" : @"";
        NSDictionary *eventInfo = @{
            @"repackType": repackTypeString,
            @"redpackId" : redpackMessage.redpackId,
            @"exposureTime" : @(lround(interval))
        };
        [muArray addObject:eventInfo];
    }
    
    [[PLVWLogReporterManager sharedManager] reportTrackWithEventId:@"user_read_redpack" eventType:@"show" specInformationArray:[muArray copy]];
}

#pragma mark - PLVRoomDataManagerProtocol

- (void)roomDataManager_didLikeCountChanged:(NSUInteger)likeCount {
    [self.likeButtonView setupLikeAnimationWithCount:[PLVRoomDataManager sharedManager].roomData.likeCount];
}

#pragma mark - PLVLCChatroomViewModelProtocol

- (void)chatroomManager_didSendMessage:(PLVChatModel *)model {
    [self.tableView reloadData];
    [self scrollsToBottom:YES];
    [self clearNewMessageCount];
}

- (void)chatroomManager_didReceiveMessages:(NSArray <PLVChatModel *> *)modelArray {
    // 如果距离底部5内都算底部
    BOOL isBottom = (self.tableView.contentSize.height
                     - self.tableView.contentOffset.y
                     - self.tableView.bounds.size.height) <= 5;
    
    [self.tableView reloadData];
    if (@available(iOS 13.0, *)) {
        [[UIMenuController sharedMenuController] hideMenu];
    } else {
        [[UIMenuController sharedMenuController]  setMenuVisible:NO];
    }
    
    if (isBottom) { // tableview显示在最底部
        [self clearNewMessageCount];
        [self scrollsToBottom:YES];
    } else {
        // 统计未读消息数
        [self addNewMessageCount];
    }
}

- (void)chatroomManager_didMessageDeleted {
    [self.tableView reloadData];
    if (@available(iOS 13.0, *)) {
        [[UIMenuController sharedMenuController] hideMenu];
    } else {
        [[UIMenuController sharedMenuController]  setMenuVisible:NO];
    }
}

- (void)chatroomManager_didSendProhibitMessage {
    [self.tableView reloadData];
}

- (void)chatroomManager_loadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
    [self.refresher endRefreshing];
    [self.tableView reloadData];
    if (noMore) {
        [self.refresher removeFromSuperview];
    }
    if (first) {
        [self scrollsToBottom:NO];
    } else {
        [self.tableView scrollsToTop];
    }
}

- (void)chatroomManager_loadHistoryFailure {
    [self.refresher endRefreshing];
    [PLVLCUtils showHUDWithTitle:PLVLocalizedString(@"历史记录获取失败") detail:@"" view:self.view];
}

- (void)chatroomManager_loginUsers:(NSArray <PLVChatUser *> * _Nullable )userArray {
    if ([PLVRoomDataManager sharedManager].roomData.welcomeShowDisable) {
        return;
    }
    
    NSString *string = @"";
    if (!userArray) {
        string = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerName;
    }
    
    if (userArray && [userArray count] > 0) {
        if ([userArray count] >= 10) {
            NSMutableString *mutableString = [[NSMutableString alloc] init];
            for (int i = 0; i < 3; i++) {
                PLVChatUser *user = userArray[i];
                if (user.userName && user.userName.length > 0) {
                    [mutableString appendFormat:@"%@、", user.userName];
                }
            }
            if (mutableString.length > 1) {
                string = [[mutableString copy] substringToIndex:mutableString.length - 1];
                string = [NSString stringWithFormat:PLVLocalizedString(@"%@等%zd人"), string, [userArray count]];
            }
        } else {
            PLVChatUser *user = userArray[0];
            string = user.userName;
        }
    }
    
    if (string.length > 0) {
        [self arrangeTopMarqueeViewFrame];
        [self.welcomeView showWelcomeWithNickName:string];
    }
}

- (void)chatroomManager_managerMessage:(NSString * )content {
    [self.notifyMarqueeView showNotifyhMessage:content];
    [self arrangeTopMarqueeViewFrame];
}


- (void)chatroomManager_loadImageEmotionSuccess:(NSArray<NSDictionary *> *)dictArray {
    self.keyboardToolView.imageEmotions = dictArray;
}

- (void)chatroomManager_loadImageEmotionFailure {
    [PLVLCUtils showHUDWithTitle:PLVLocalizedString(@"图片表情数据获取失败") detail:@"" view:self.view];
}

- (void)chatroomManager_rewardSuccess:(NSDictionary *)modelDict {
    if (![PLVLCChatroomViewModel sharedViewModel].hideRewardDisplay) {
        NSInteger num = [modelDict[@"goodNum"] integerValue];
        NSString *unick = modelDict[@"unick"];
        PLVRewardGoodsModel *model = [PLVRewardGoodsModel modelWithSocketObject:modelDict];
        [self.rewardDisplayManager addGoodsShowWithModel:model goodsNum:num personName:unick];
    }
}

- (void)chatroomManager_loadRewardEnable:(BOOL)enable payWay:payWay rewardModelArray:(NSArray *)modelArray pointUnit:(NSString *)pointUnit {
    /// 回放场景不支持礼物打赏
    if ([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Live) {
        self.keyboardToolView.enableReward = enable;
        [self.keyboardToolView updateTextViewAndButton];
    }
}

- (void)chatroomManager_showDelayRedpackWithType:(PLVRedpackMessageType)type delayTime:(NSInteger)delayTime {
    if (type != PLVRedpackMessageTypeAliPassword) {
        return;
    }
    
    BOOL showFirst = (self.redpackButtonView.hidden == YES);
    [self.redpackButtonView showWithRedpackMessageType:type delayTime:delayTime];
    if (showFirst) {
        [self refreshFloatingButtonViewFrame];
    }
}

- (void)chatroomManager_hideDelayRedpack {
    [self.redpackButtonView dismiss];
    [self refreshFloatingButtonViewFrame];
}

- (void)chatroomManager_closeRoom:(BOOL)closeRoom {
    [self.keyboardToolView changeCloseRoomStatus:closeRoom];
}

- (void)chatroomManager_focusMode:(BOOL)focusMode {
    [self.keyboardToolView changeFocusMode:focusMode];
}

- (void)chatroomManager_didRedpackStateChanged {
    [self.tableView reloadData];
}

#pragma mark - PLVLCChatroomPlaybackViewModelDelegate

- (void)clearMessageForPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel {
    [self.tableView reloadData];
}

- (void)loadMessageInfoSuccess:(BOOL)success playbackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel {
    NSString *content = success ? PLVLocalizedString(@"聊天室重放功能已开启，将会显示历史消息") : PLVLocalizedString(@"回放消息正在准备中，可稍等刷新查看");
    [self.notifyView showNotifyhMessage:content];
}

- (void)didReceiveNewMessagesForChatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel {
    // 如果距离底部5内都算底部
    BOOL isBottom = (self.tableView.contentSize.height
                     - self.tableView.contentOffset.y
                     - self.tableView.bounds.size.height) <= 5;
    
    [self.tableView reloadData];
    
    if (isBottom) { // tableview显示在最底部
        [self clearNewMessageCount];
        [self scrollsToBottom:YES];
    } else {
        // 统计未读消息数
        [self addNewMessageCount];
    }
}

- (void)didMessagesRefreshedForChatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel {
    [self.tableView reloadData];
    [self clearNewMessageCount];
    [self scrollsToBottom:YES];
}

- (void)didLoadMoreHistoryMessagesForChatroomPlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)viewModel {
    [self.refresher endRefreshing];
    [self.tableView reloadData];
}

#pragma mark - UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self dataCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [self dataCount]) {
        return [UITableViewCell new];
    }
    
    __weak typeof(self) weakSelf = self;
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    BOOL quoteReplyEnabled = [PLVRoomDataManager sharedManager].roomData.menuInfo.quoteReplyEnabled;
    PLVChatModel *model = [self modelAtIndexPath:indexPath];
    
    if ([PLVLCSpeakMessageCell isModelValid:model]) {
        static NSString *speakMessageCellIdentify = @"PLVLCSpeakMessageCell";
        PLVLCSpeakMessageCell *cell = (PLVLCSpeakMessageCell *)[tableView dequeueReusableCellWithIdentifier:speakMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCSpeakMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:speakMessageCellIdentify];
            cell.allowReply = !self.playbackEnable && quoteReplyEnabled;
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        [cell setReplyHandler:^(PLVChatModel *model) {
            [weakSelf didTapReplyMenuItem:model];
        }];
        return cell;
    } else if ([PLVLCLongContentMessageCell isModelValid:model]) {
        static NSString *LongContentMessageCellIdentify = @"PLVLCLongContentMessageCell";
        PLVLCLongContentMessageCell *cell = (PLVLCLongContentMessageCell *)[tableView dequeueReusableCellWithIdentifier:LongContentMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCLongContentMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LongContentMessageCellIdentify];
            cell.allowReply = !self.playbackEnable && quoteReplyEnabled;
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        [cell setReplyHandler:^(PLVChatModel *model) {
            [weakSelf didTapReplyMenuItem:model];
        }];
        [cell setCopButtonHandler:^{
            [weakSelf pasteFullContentWithModel:model];
        }];
        [cell setFoldButtonHandler:^{
            [weakSelf alertToShowFullContentWithModel:model];
        }];
        return cell;
    } else if ([PLVLCImageMessageCell isModelValid:model]) {
        static NSString *imageMessageCellIdentify = @"PLVLCImageMessageCell";
        PLVLCImageMessageCell *cell = (PLVLCImageMessageCell *)[tableView dequeueReusableCellWithIdentifier:imageMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCImageMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:imageMessageCellIdentify];
            cell.allowReply = !self.playbackEnable && quoteReplyEnabled;
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        [cell setReplyHandler:^(PLVChatModel *model) {
            [weakSelf didTapReplyMenuItem:model];
        }];
        return cell;
    } else if ([PLVLCImageEmotionMessageCell isModelValid:model]) {
        static NSString *imageMessageCellIdentify = @"PLVLCImageEmotionMessageCell";
        PLVLCImageEmotionMessageCell *cell = (PLVLCImageEmotionMessageCell *)[tableView dequeueReusableCellWithIdentifier:imageMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCImageEmotionMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:imageMessageCellIdentify];
            cell.allowReply = !self.playbackEnable && quoteReplyEnabled;
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        [cell setReplyHandler:^(PLVChatModel *model) {
            [weakSelf didTapReplyMenuItem:model];
        }];
        return cell;
    } else if ([PLVLCQuoteMessageCell isModelValid:model]) {
        static NSString *quoteMessageCellIdentify = @"PLVLCQuoteMessageCell";
        PLVLCQuoteMessageCell *cell = (PLVLCQuoteMessageCell *)[tableView dequeueReusableCellWithIdentifier:quoteMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCQuoteMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:quoteMessageCellIdentify];
            cell.allowReply = !self.playbackEnable && quoteReplyEnabled;
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        [cell setReplyHandler:^(PLVChatModel *model) {
            [weakSelf didTapReplyMenuItem:model];
        }];
        return cell;
    } else if ([PLVLCRewardMessageCell isModelValid:model]) {
        static NSString *rewardMessageCellIdentify = @"PLVLCRewardCell";
        PLVLCRewardMessageCell *cell = (PLVLCRewardMessageCell *)[tableView dequeueReusableCellWithIdentifier:rewardMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCRewardMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:rewardMessageCellIdentify];
        }
        [cell updateWithModel:model cellWidth:self.tableView.frame.size.width];
        return cell;
    } else if ([PLVLCFileMessageCell isModelValid:model]) {
        static NSString *fileMessageCellIdentify = @"PLVLCFileMessageCell";
        PLVLCFileMessageCell *cell = (PLVLCFileMessageCell *)[tableView dequeueReusableCellWithIdentifier:fileMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCFileMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:fileMessageCellIdentify];
        }
        CGFloat fileMessageCellWidth = self.likeButtonView.frame.origin.x - 8;// 气泡保证不遮挡点赞按钮
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:fileMessageCellWidth];
        return cell;
    } else if ([PLVLCRedpackMessageCell isModelValid:model]) {
        static NSString *redpackMessageCellIdentify = @"PLVLCRedpackMessageCell";
        PLVLCRedpackMessageCell *cell = (PLVLCRedpackMessageCell *)[tableView dequeueReusableCellWithIdentifier:redpackMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCRedpackMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:redpackMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        [cell setTapRedpackHandler:^(PLVChatModel * _Nonnull model) {
            [weakSelf didTapRedpackModel:model];
        }];
        return cell;
    } else {
        static NSString *cellIdentify = @"cellIdentify";
        UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentify];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentify];
        }
        return cell;
    }
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [self dataCount]) {
        return 0;
    }
    
    CGFloat cellHeight = 0.0;
    
    PLVChatModel *model = [self modelAtIndexPath:indexPath];
    if ([PLVLCSpeakMessageCell isModelValid:model]) {
        if (model.cellHeightForV == 0.0) {
            model.cellHeightForV = [PLVLCSpeakMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForV;
    } else if ([PLVLCLongContentMessageCell isModelValid:model]) {
        if (model.cellHeightForV == 0.0) {
            model.cellHeightForV = [PLVLCLongContentMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForV;
    } else if ([PLVLCImageMessageCell isModelValid:model]) {
        if (model.cellHeightForV == 0.0) {
            model.cellHeightForV = [PLVLCImageMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForV;
    } else if ([PLVLCImageEmotionMessageCell isModelValid:model]) {
        if (model.cellHeightForV == 0.0) {
            model.cellHeightForV = [PLVLCImageEmotionMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForV;
    } else if ([PLVLCQuoteMessageCell isModelValid:model]) {
        if (model.cellHeightForV == 0.0) {
            model.cellHeightForV = [PLVLCQuoteMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForV;
    } else if ([PLVLCRewardMessageCell isModelValid:model]) {
        if (model.cellHeightForV == 0.0) {
            model.cellHeightForV = [PLVLCRewardMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForV;
    } else if ([PLVLCFileMessageCell isModelValid:model]) {
        if (model.cellHeightForV == 0.0) {
            model.cellHeightForV = [PLVLCFileMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForV;
    } else if ([PLVLCRedpackMessageCell isModelValid:model]) {
        if (model.cellHeightForV == 0.0) {
            model.cellHeightForV = [PLVLCRedpackMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
        }
        cellHeight = model.cellHeightForV;
    }
    
    return cellHeight;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    BOOL up = scrollView.contentOffset.y < self.lastContentOffset.y;
    if (self.lastContentOffset.y <= 0 && scrollView.contentOffset.y <= 0) {
        up = YES;
    }
    self.lastContentOffset = scrollView.contentOffset;
    if (!up) {
        [self clearNewMessageCount];
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(trackLogAction) object:nil];
    [self performSelector:@selector(trackLogAction) withObject:nil afterDelay:1];
}

#pragma mark - PLVLCKeyboardToolView Delegate

- (BOOL)keyboardToolView_shouldInteract:(PLVLCKeyboardToolView *)toolView {
    return [PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Live; // 聊天回放时，不支持发言以及打赏、送礼等互动
}

- (void)keyboardToolView:(PLVLCKeyboardToolView *)toolView popBoard:(BOOL)show {
    NSLog(@"keyboardToolView - popBoard %@", show ? @"YES" : @"NO");
}

- (void)keyboardToolView:(PLVLCKeyboardToolView *)toolView sendText:(NSString *)text replyModel:(PLVChatModel *)replyModel {
    BOOL success = [[PLVLCChatroomViewModel sharedViewModel] sendSpeakMessage:text replyChatModel:replyModel];
    if (!success) {
        [PLVLCUtils showHUDWithTitle:PLVLocalizedString(@"消息发送失败") detail:@"" view:self.view];
    }
}

- (void)keyboardToolView:(PLVLCKeyboardToolView *)toolView
      sendImageEmotionId:(NSString *)imageId
                imageUrl:(nonnull NSString *)imageUrl {
    BOOL success = [[PLVLCChatroomViewModel sharedViewModel]
                    sendImageEmotionId:imageId
                    imageUrl:imageUrl];
    if (!success) {
        [PLVLCUtils showHUDWithTitle:PLVLocalizedString(@"图片表情消息发送失败") detail:@"" view:self.view];
    }
}

- (void)keyboardToolView:(PLVLCKeyboardToolView *)toolView onlyTeacher:(BOOL)on {
    [PLVLCChatroomViewModel sharedViewModel].onlyTeacher = on;
    [self.tableView reloadData];
}

- (void)keyboardToolView_openAlbum:(PLVLCKeyboardToolView *)toolView {
    PLVImagePickerViewController *vctrl = [[PLVImagePickerViewController alloc] initWithColumnNumber:4];

    [vctrl setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
        if ([photos isKindOfClass:NSArray.class]) {
            BOOL success = [[PLVLCChatroomViewModel sharedViewModel] sendImageMessage:photos.firstObject];
            if (!success) {
                [PLVLCUtils showHUDWithTitle:PLVLocalizedString(@"消息发送失败") detail:@"" view:self.view];
            }
        }
    }];
    [self.liveRoom presentViewController:vctrl animated:YES completion:nil];
}

- (void)keyboardToolView_openCamera:(PLVLCKeyboardToolView *)toolView {
    __weak typeof(self) weakSelf = self;
    PLVAuthorizationStatus status = [PLVAuthorizationManager authorizationStatusWithType:PLVAuthorizationTypeMediaVideo];
    switch (status) {
        case PLVAuthorizationStatusAuthorized: {
            [weakSelf openCamera];
        } break;
        case PLVAuthorizationStatusDenied:
        case PLVAuthorizationStatusRestricted:
        {
            [weakSelf performSelector:@selector(presentAlertController:) withObject:PLVLocalizedString(@"你没开通访问相机的权限，如要开通，请移步到:设置->隐私->相机 开启") afterDelay:0.1];
        } break;
        case PLVAuthorizationStatusNotDetermined: {
            [PLVAuthorizationManager requestAuthorizationWithType:PLVAuthorizationTypeMediaVideo completion:^(BOOL granted) {
                if (granted) {
                    [weakSelf openCamera];
                }else {
                    [weakSelf performSelector:@selector(presentAlertController:) withObject:PLVLocalizedString(@"你没开通访问相机的权限，如要开通，请移步到:设置->隐私->相机 开启") afterDelay:0.1];
                }
            }];
        } break;
        default:
            break;
    }
}

- (void)keyboardToolView_readBulletin:(PLVLCKeyboardToolView *)toolView {
    [[NSNotificationCenter defaultCenter] postNotificationName:PLVLCChatroomOpenBulletinNotification object:nil];
}

- (void)keyboardToolView_openInteractApp:(PLVLCKeyboardToolView *)moreView eventName:(NSString *)eventName {
    if ([PLVFdUtil checkStringUseable:eventName]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:PLVLCChatroomOpenInteractAppNotification object:eventName];
    }
}

- (void)keyboardToolView_openReward:(PLVLCKeyboardToolView *)toolView {
    [[NSNotificationCenter defaultCenter] postNotificationName:PLVLCChatroomOpenRewardViewNotification object:nil];
}

- (void)keyboardToolView:(PLVLCKeyboardToolView *)moreView switchLanguageMode:(NSInteger)languageMode {
    [PLVFdUtil showAlertWithTitle:nil 
                          message:PLVLocalizedString(@"PLVAlertSwitchLanguageTips")
                   viewController:[PLVFdUtil getCurrentViewController]
                cancelActionTitle:PLVLocalizedString(@"取消")
                cancelActionStyle:UIAlertActionStyleDefault
                cancelActionBlock:nil
               confirmActionTitle:PLVLocalizedString(@"PLVAlertConfirmTitle")
               confirmActionStyle:UIAlertActionStyleDestructive
               confirmActionBlock:^(UIAlertAction * _Nonnull action) {
        [[PLVMultiLanguageManager sharedManager] updateLanguage:MAX(MIN(languageMode, PLVMultiLanguageModeEN), PLVMultiLanguageModeSyetem)];
    }];
}

- (void)keyboardToolView_showIarEntranceView:(PLVLCKeyboardToolView *)iarEntranceView show:(BOOL)show {
    CGRect rect = self.keyboardToolView.frame;
    if (show) {
        rect.size.height += 36;
    } else {
        rect.size.height -= 36;
    }
    self.keyboardToolView.frame = rect;
    [self.keyboardToolView updateTextViewAndButton];
    [self.view layoutIfNeeded];
}

#pragma mark - PLVLCLikeButtonView Delegate

- (void)didTapLikeButton:(PLVLCLikeButtonView *)likeButtonView {
    [[PLVLCChatroomViewModel sharedViewModel] sendLike];
}

#pragma mark - PLVLCCardPushButtonViewDelegate

- (void)cardPushButtonView:(PLVLCCardPushButtonView *)pushButtonView needOpenInteract:(NSDictionary *)dict {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCChatViewController:needOpenInteract:)]) {
        [self.delegate plvLCChatViewController:self needOpenInteract:dict];
    }
}

- (void)cardPushButtonViewPopupViewDidShow:(PLVLCCardPushButtonView *)pushButtonView {
    [self.lotteryWidgetView hidePopupView];
}

#pragma mark - PLVLCLotteryWidgetViewDelegate

- (void)lotteryWidgetViewDidClickAction:(PLVLCLotteryWidgetView *)lotteryWidgetView eventName:(NSString *)eventName {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCChatViewController:emitInteractEvent:)]) {
        [self.delegate plvLCChatViewController:self emitInteractEvent:eventName];
    }
}

- (void)lotteryWidgetView:(PLVLCLotteryWidgetView *)lotteryWidgetView showStatusChanged:(BOOL)show {
    [self refreshFloatingButtonViewFrame];
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCChatViewController:lotteryWidgetShowStatusChanged:)]) {
        [self.delegate plvLCChatViewController:self lotteryWidgetShowStatusChanged:show];
    }
}

- (void)lotteryWidgetViewPopupViewDidShow:(PLVLCLotteryWidgetView *)lotteryWidgetView {
    [self.cardPushButtonView hidePopupView];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
    [[PLVLCChatroomViewModel sharedViewModel] sendImageMessage:image];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
