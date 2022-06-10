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
#import "PLVLCNotifyMarqueeView.h"
#import "PLVLCSpeakMessageCell.h"
#import "PLVLCImageMessageCell.h"
#import "PLVLCImageEmotionMessageCell.h"
#import "PLVLCQuoteMessageCell.h"
#import "PLVLCRewardMessageCell.h"
#import "PLVAlbumNavigationController.h"
#import "PLVGiveRewardPresenter.h"
#import "PLVRewardGoodsModel.h"
#import "PLVRewardDisplayManager.h"
#import "PLVRoomDataManager.h"
#import "PLVLCChatroomViewModel.h"
#import <PLVLiveScenesSDK/PLVLiveVideoConfig.h>
#import <PLVFoundationSDK/PLVFdUtil.h>
#import <PLVFoundationSDK/PLVColorUtil.h>
#import <MJRefresh/MJRefresh.h>
#import "PLVLCUtils.h"
#import <PLVFoundationSDK/PLVAuthorizationManager.h>
#import <PLVImagePickerController/PLVImagePickerController.h>

NSString *PLVLCChatroomOpenBulletinNotification = @"PLVLCChatroomOpenBulletinNotification";

NSString *PLVLCChatroomOpenInteractAppNotification = @"PLVLCChatroomOpenInteractAppNotification";

NSString *PLVLCChatroomOpenRewardViewNotification = @"PLVLCChatroomOpenRewardViewNotification";

NSString *PLVInteractUpdateChatButtonCallbackNotification = @"PLVInteractUpdateChatButtonCallbackNotification";

@interface PLVLCChatViewController ()<
PLVLCKeyboardToolViewDelegate,
PLVLCLikeButtonViewDelegate,
PLVLCChatroomViewModelProtocol,
PLVRoomDataManagerProtocol,
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
/// 聊天室顶部公告横幅
@property (nonatomic, strong) PLVLCNotifyMarqueeView *notifyMarqueeView;
/// 打赏成功提示条幅
@property (nonatomic, strong) PLVRewardDisplayManager *rewardDisplayManager;

@end

@implementation PLVLCChatViewController

#pragma mark - UI 布局

- (void)setupUI {
    self.view.backgroundColor = [PLVColorUtil colorFromHexString:@"#202127"];
    
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.likeButtonView];
    [self.view addSubview:self.welcomeView];
    [self.view addSubview:self.notifyMarqueeView];
    [self.view addSubview:self.receiveNewMessageView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
     
    if (self.hasLayoutSubView) { // 调整布局
        CGFloat height = PLVLCKeyboardToolViewHeight + P_SafeAreaBottomEdgeInsets();
        self.tableView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - height);
        
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
        
        self.receiveNewMessageView.frame = CGRectMake(0, self.keyboardToolView.frame.origin.y - 28, CGRectGetWidth(self.view.bounds), 28);
        
        if (![self currentIsFullScreen]) {
            [self refreshLikeButtonViewFrame];
        }
    }
}

- (void)viewDidLayoutSubviews {
    if (!self.hasLayoutSubView) { // 初次布局
        CGFloat height = PLVLCKeyboardToolViewHeight + P_SafeAreaBottomEdgeInsets();
        CGRect inputRect = CGRectMake(0, CGRectGetHeight(self.view.bounds) - height, CGRectGetWidth(self.view.bounds), height);
        [self.keyboardToolView addAtView:self.view frame:inputRect];
        self.receiveNewMessageView.frame = CGRectMake(0, inputRect.origin.y - 28, CGRectGetWidth(self.view.bounds), 28);
        self.tableView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - height);
                
        [self arrangeTopMarqueeViewFrame];
        
        self.hasLayoutSubView = YES;
        
        [self scrollsToBottom:NO];
        
        [self refreshLikeButtonViewFrame];
    }
}

- (void)refreshLikeButtonViewFrame{
    CGFloat height = PLVLCKeyboardToolViewHeight + P_SafeAreaBottomEdgeInsets();
    CGRect inputRect = CGRectMake(0, CGRectGetHeight(self.view.bounds) - height, CGRectGetWidth(self.view.bounds), height);
    CGFloat rightPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 20.0 : 16.0; // 右边距
    self.likeButtonView.frame = CGRectMake(self.view.bounds.size.width - PLVLCLikeButtonViewWidth - rightPadding, inputRect.origin.y - 17 - PLVLCLikeButtonViewHeight, PLVLCLikeButtonViewWidth, PLVLCLikeButtonViewHeight);
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
        _keyboardToolView.hiddenBulletin = ([PLVRoomDataManager sharedManager].roomData.videoType != PLVChannelVideoType_Live);
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

- (PLVLCWelcomeView *)welcomeView {
    if (!_welcomeView) {
        _welcomeView = [[PLVLCWelcomeView alloc] init];
    }
    return _welcomeView;
}

- (PLVLCNotifyMarqueeView *)notifyMarqueeView {
    if (!_notifyMarqueeView) {
        _notifyMarqueeView = [[PLVLCNotifyMarqueeView alloc] init];
    }
    return _notifyMarqueeView;
}

- (PLVRewardDisplayManager *)rewardDisplayManager {
    if (!_rewardDisplayManager) {
        _rewardDisplayManager = [[PLVRewardDisplayManager alloc] init];
        _rewardDisplayManager.superView = self.view;
    }
    return _rewardDisplayManager;
}

#pragma mark - Action

- (void)refreshAction:(MJRefreshNormalHeader *)refreshHeader {
    [[PLVLCChatroomViewModel sharedViewModel] loadHistory];
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
        
        [[PLVLCChatroomViewModel sharedViewModel] addDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return self;
}

- (void)resumeLikeButtonViewLayout {
    [self.view insertSubview:self.likeButtonView belowSubview:self.receiveNewMessageView];
    [self refreshLikeButtonViewFrame];
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
    [PLVLCUtils showHUDWithTitle:@"历史记录获取失败" detail:@"" view:self.view];
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
                string = [NSString stringWithFormat:@"%@等%zd人", string, [userArray count]];
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
    [PLVLCUtils showHUDWithTitle:@"图片表情数据获取失败" detail:@"" view:self.view];
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

#pragma mark - UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[PLVLCChatroomViewModel sharedViewModel] chatArray] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [[[PLVLCChatroomViewModel sharedViewModel] chatArray] count]) {
        return [UITableViewCell new];
    }
    
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    PLVChatModel *model = [[PLVLCChatroomViewModel sharedViewModel] chatArray][indexPath.row];
    
    if ([PLVLCSpeakMessageCell isModelValid:model]) {
        static NSString *speakMessageCellIdentify = @"PLVLCSpeakMessageCell";
        PLVLCSpeakMessageCell *cell = (PLVLCSpeakMessageCell *)[tableView dequeueReusableCellWithIdentifier:speakMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCSpeakMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:speakMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        return cell;
    } else if ([PLVLCImageMessageCell isModelValid:model]) {
        static NSString *imageMessageCellIdentify = @"PLVLCImageMessageCell";
        PLVLCImageMessageCell *cell = (PLVLCImageMessageCell *)[tableView dequeueReusableCellWithIdentifier:imageMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCImageMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:imageMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        return cell;
    } else if ([PLVLCImageEmotionMessageCell isModelValid:model]) {
        static NSString *imageMessageCellIdentify = @"PLVLCImageEmotionMessageCell";
        PLVLCImageEmotionMessageCell *cell = (PLVLCImageEmotionMessageCell *)[tableView dequeueReusableCellWithIdentifier:imageMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCImageEmotionMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:imageMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        return cell;
    } else if ([PLVLCQuoteMessageCell isModelValid:model]) {
        static NSString *quoteMessageCellIdentify = @"PLVLCQuoteMessageCell";
        PLVLCQuoteMessageCell *cell = (PLVLCQuoteMessageCell *)[tableView dequeueReusableCellWithIdentifier:quoteMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCQuoteMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:quoteMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        return cell;
    } else if ([PLVLCRewardMessageCell isModelValid:model]) {
        static NSString *rewardMessageCellIdentify = @"PLVLCRewardCell";
        PLVLCRewardMessageCell *cell = (PLVLCRewardMessageCell *)[tableView dequeueReusableCellWithIdentifier:rewardMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCRewardMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:rewardMessageCellIdentify];
        }
        [cell updateWithModel:model cellWidth:self.tableView.frame.size.width];
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
    if (indexPath.row >= [[[PLVLCChatroomViewModel sharedViewModel] chatArray] count]) {
        return 0;
    }
    
    CGFloat cellHeight = 44.0;
    
    PLVChatModel *model = [[PLVLCChatroomViewModel sharedViewModel].chatArray objectAtIndex:indexPath.row];
    if ([PLVLCSpeakMessageCell isModelValid:model]) {
        cellHeight = [PLVLCSpeakMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
    } else if ([PLVLCImageMessageCell isModelValid:model]) {
        cellHeight = [PLVLCImageMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
    } else if ([PLVLCImageEmotionMessageCell isModelValid:model]) {
        cellHeight = [PLVLCImageEmotionMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
    } else if ([PLVLCQuoteMessageCell isModelValid:model]) {
        cellHeight = [PLVLCQuoteMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
    } else if ([PLVLCRewardMessageCell isModelValid:model]) {
        cellHeight = [PLVLCRewardMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
    } else {
        cellHeight = 0;
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
}

#pragma mark - PLVLCKeyboardToolView Delegate

- (BOOL)keyboardToolView_shouldInteract:(PLVLCKeyboardToolView *)toolView {
    return YES;
}

- (void)keyboardToolView:(PLVLCKeyboardToolView *)toolView popBoard:(BOOL)show {
    NSLog(@"keyboardToolView - popBoard %@", show ? @"YES" : @"NO");
  
}

- (void)keyboardToolView:(PLVLCKeyboardToolView *)toolView sendText:(NSString *)text {
    BOOL success = [[PLVLCChatroomViewModel sharedViewModel] sendSpeakMessage:text];
    if (!success) {
        [PLVLCUtils showHUDWithTitle:@"消息发送失败" detail:@"" view:self.view];
    }
}

- (void)keyboardToolView:(PLVLCKeyboardToolView *)toolView
      sendImageEmotionId:(NSString *)imageId
                imageUrl:(nonnull NSString *)imageUrl {
    BOOL success = [[PLVLCChatroomViewModel sharedViewModel]
                    sendImageEmotionId:imageId
                    imageUrl:imageUrl];
    if (!success) {
        [PLVLCUtils showHUDWithTitle:@"图片表情消息发送失败" detail:@"" view:self.view];
    }
}

- (void)keyboardToolView:(PLVLCKeyboardToolView *)toolView onlyTeacher:(BOOL)on {
    [PLVLCChatroomViewModel sharedViewModel].onlyTeacher = on;
    [self.tableView reloadData];
}

- (void)keyboardToolView_openAlbum:(PLVLCKeyboardToolView *)toolView {
    PLVImagePickerController *vctrl = [[PLVImagePickerController alloc]
                                       initWithMaxImagesCount:1 columnNumber:4 delegate:nil];;
    vctrl.view.backgroundColor = [PLVColorUtil colorFromHexString:@"#1A1B1F"];
    vctrl.showSelectBtn = YES;
    vctrl.allowTakeVideo = NO;
    vctrl.allowPickingVideo = NO;
    vctrl.allowTakePicture = NO;
    vctrl.allowPickingOriginalPhoto = NO;
    vctrl.showPhotoCannotSelectLayer = YES;
    vctrl.cannotSelectLayerColor = [UIColor colorWithWhite:1.0 alpha:0.6];
    
    vctrl.iconThemeColor = [PLVColorUtil colorFromHexString:@"#366BEE"];
    vctrl.oKButtonTitleColorNormal = UIColor.whiteColor;
    vctrl.naviTitleColor = [UIColor colorWithWhite:0.6 alpha:1];
    vctrl.naviTitleFont = [UIFont systemFontOfSize:14.0];
    vctrl.barItemTextColor = [PLVColorUtil colorFromHexString:@"#366BEE"];
    vctrl.barItemTextFont = [UIFont systemFontOfSize:14.0];
    vctrl.naviBgColor = [PLVColorUtil colorFromHexString:@"#1A1B1F"];
    
    [vctrl setPhotoPickerPageUIConfigBlock:^(UICollectionView *collectionView, UIView *bottomToolBar, UIButton *previewButton, UIButton *originalPhotoButton, UILabel *originalPhotoLabel, UIButton *doneButton, UIImageView *numberImageView, UILabel *numberLabel, UIView *divideLine) {
        divideLine.hidden = YES;
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.backgroundColor = [PLVColorUtil colorFromHexString:@"#1A1B1F"];
        bottomToolBar.backgroundColor = [PLVColorUtil colorFromHexString:@"#1A1B1F"];
        bottomToolBar.layer.shadowColor = [UIColor colorWithRed:10/255.0 green:10/255.0 blue:17/255.0 alpha:1.0].CGColor;
        bottomToolBar.layer.shadowOffset = CGSizeMake(0,-1);
        bottomToolBar.layer.shadowOpacity = 1;
        bottomToolBar.layer.shadowRadius = 0;

        UIResponder *nextResponder = [collectionView nextResponder];
        if ([nextResponder isKindOfClass:UIView.class]) {
            [(UIView *)nextResponder setBackgroundColor:[PLVColorUtil colorFromHexString:@"#1A1B1F"]];
        }
    }];
    [vctrl setPhotoPickerPageDidLayoutSubviewsBlock:^(UICollectionView *collectionView, UIView *bottomToolBar, UIButton *previewButton, UIButton *originalPhotoButton, UILabel *originalPhotoLabel, UIButton *doneButton, UIImageView *numberImageView, UILabel *numberLabel, UIView *divideLine) {
        previewButton.hidden = YES;

        doneButton.layer.cornerRadius = 14.0;
        doneButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#366BEE"];
        doneButton.frame = CGRectMake(CGRectGetMinX(doneButton.frame)-74.0/2, (CGRectGetHeight(doneButton.bounds)-28.0)/2, 74.0, 28.0);
    }];

    [vctrl setPhotoPickerPageDidRefreshStateBlock:^(UICollectionView *collectionView, UIView *bottomToolBar, UIButton *previewButton, UIButton *originalPhotoButton, UILabel *originalPhotoLabel, UIButton *doneButton, UIImageView *numberImageView, UILabel *numberLabel, UIView *divideLine) {
        numberLabel.hidden = YES;
        numberImageView.hidden = YES;
    }];

    [vctrl setAlbumCellDidLayoutSubviewsBlock:^(PLVAlbumCell *cell, UIImageView *posterImageView, UILabel *titleLabel) {
        titleLabel.textColor = UIColor.lightGrayColor;
        [(UITableViewCell *)cell setBackgroundColor:UIColor.clearColor];
        [(UITableViewCell *)cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        UIResponder *nextResponder = [(UITableViewCell *)cell nextResponder];
        if ([nextResponder isKindOfClass:UIView.class]) {
            [(UIView *)nextResponder setBackgroundColor:[PLVColorUtil colorFromHexString:@"#1A1B1F"]];
        }
        nextResponder = nextResponder.nextResponder;
        if ([nextResponder isKindOfClass:UIView.class]) {
            [(UIView *)nextResponder setBackgroundColor:[PLVColorUtil colorFromHexString:@"#1A1B1F"]];
        }
    }];

    [vctrl setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
        if ([photos isKindOfClass:NSArray.class]) {
            BOOL success = [[PLVLCChatroomViewModel sharedViewModel] sendImageMessage:photos.firstObject];
            if (!success) {
                [PLVLCUtils showHUDWithTitle:@"消息发送失败" detail:@"" view:self.view];
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
            [weakSelf performSelector:@selector(presentAlertController:) withObject:@"你没开通访问相机的权限，如要开通，请移步到:设置->隐私->相机 开启" afterDelay:0.1];
        } break;
        case PLVAuthorizationStatusNotDetermined: {
            [PLVAuthorizationManager requestAuthorizationWithType:PLVAuthorizationTypeMediaVideo completion:^(BOOL granted) {
                if (granted) {
                    [weakSelf openCamera];
                }else {
                    [weakSelf performSelector:@selector(presentAlertController:) withObject:@"你没开通访问相机的权限，如要开通，请移步到:设置->隐私->相机 开启" afterDelay:0.1];
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

#pragma mark - PLVLCLikeButtonView Delegate

- (void)didTapLikeButton:(PLVLCLikeButtonView *)likeButtonView {
    [[PLVLCChatroomViewModel sharedViewModel] sendLike];
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
