//
//  PLVLCChatViewController.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCChatViewController.h"
#import "PLVKeyboardToolView.h"
#import "PLVLCNewMessageView.h"
#import "PLVLCWelcomeView.h"
#import "PLVLCNotifyMarqueeView.h"
#import "PLVLCSpeakMessageCell.h"
#import "PLVLCImageMessageCell.h"
#import "PLVLCQuoteMessageCell.h"
#import "PLVAlbumNavigationController.h"
#import "PLVPickerController.h"
#import "PLVRoomDataManager.h"
#import "PLVLCChatroomViewModel.h"
#import <PLVLiveScenesSDK/PLVLiveVideoConfig.h>
#import <PolyvFoundationSDK/PLVFdUtil.h>
#import <PolyvFoundationSDK/PLVColorUtil.h>
#import <MJRefresh/MJRefresh.h>
#import "PLVCameraViewController.h"
#import "PLVAlbumTool.h"
#import "PLVLCUtils.h"
#import <PolyvFoundationSDK/PLVAuthorizationManager.h>

NSString *PLVLCChatroomOpenBulletinNotification = @"PLVLCChatroomOpenBulletinNotification";

@interface PLVLCChatViewController ()<
PLVKeyboardToolViewDelegate,
PLVLCLikeButtonViewDelegate,
PLVPickerControllerDelegate,
PLVCameraViewControllerDelegate,
PLVLCChatroomViewModelProtocol,
PLVRoomDataManagerProtocol,
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
@property (nonatomic, strong) PLVKeyboardToolView *keyboardToolView;
/// 聊天室顶部欢迎横幅
@property (nonatomic, strong) PLVLCWelcomeView *welcomeView;
/// 聊天室顶部公告横幅
@property (nonatomic, strong) PLVLCNotifyMarqueeView *notifyMarqueeView;

@property (nonatomic, assign) id<PLVPickerControllerDelegate> delegate;

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
        CGFloat height = PLVKeyboardToolViewHeight + P_SafeAreaBottomEdgeInsets();
        self.tableView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - height);
        
        CGFloat keyboardToolOriginY = CGRectGetHeight(self.view.bounds) - height;
        [self.keyboardToolView changeFrameForNewOriginY:keyboardToolOriginY];
    }
}

- (void)viewDidLayoutSubviews {
    if (!self.hasLayoutSubView) { // 初次布局
        CGFloat height = PLVKeyboardToolViewHeight + P_SafeAreaBottomEdgeInsets();
        CGRect inputRect = CGRectMake(0, CGRectGetHeight(self.view.bounds) - height, CGRectGetWidth(self.view.bounds), height);
        [self.keyboardToolView addAtView:self.view frame:inputRect];
        self.receiveNewMessageView.frame = CGRectMake(0, inputRect.origin.y - 28, CGRectGetWidth(self.view.bounds), 28);
        self.tableView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - height);
                
        [self arrangeTopMarqueeViewFrame];
        
        self.hasLayoutSubView = YES;
        
        [self scrollsToBottom:NO];
    }
    [self refreshLikeButtonViewFrame];
}

- (void)refreshLikeButtonViewFrame{
    CGFloat height = PLVKeyboardToolViewHeight + P_SafeAreaBottomEdgeInsets();
    CGRect inputRect = CGRectMake(0, CGRectGetHeight(self.view.bounds) - height, CGRectGetWidth(self.view.bounds), height);
    self.likeButtonView.frame = CGRectMake(self.view.bounds.size.width - PLVLCLikeButtonViewWidth - 16, inputRect.origin.y - 17 - PLVLCLikeButtonViewHeight, PLVLCLikeButtonViewWidth, PLVLCLikeButtonViewHeight);
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

- (PLVKeyboardToolView *)keyboardToolView {
    if (!_keyboardToolView) {
        _keyboardToolView = [[PLVKeyboardToolView alloc] init];
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
}

- (void)removeObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidChangeStatusBarOrientationNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:PLVLCChatroomFunctionGotNotification
                                                  object:nil];
}

- (void)interfaceOrientationDidChange:(NSNotification *)notification {
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (!fullScreen) {
        [self scrollsToBottom:NO];
    }
}

- (void)gotChatroomFunction:(NSNotification *)notification {
    self.keyboardToolView.enableSendImage = ![PLVRoomDataManager sharedManager].roomData.sendImageDisable;
    self.likeButtonView.hidden = [PLVRoomDataManager sharedManager].roomData.sendLikeDisable;
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
    self.welcomeView.frame = CGRectMake(10, welcomeOriginY, CGRectGetWidth(self.view.bounds) - 10 * 2, 40);
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
    
    PLVCameraViewController *cameraVC = [[PLVCameraViewController alloc] init];
    cameraVC.delegate = self;
    cameraVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.liveRoom presentViewController:cameraVC animated:YES completion:nil];
}

- (void)presentAlertController:(NSString *)message {
    [PLVAlbumTool presentAlertController:message inViewController:self];
}

#pragma mark - PLVRoomDataManagerProtocol

- (void)roomDataManager_didLikeCountChanged:(NSUInteger)likeCount {
    self.likeButtonView.likeCount = [PLVRoomDataManager sharedManager].roomData.likeCount;
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
        [self.welcomeView showWelcomeWithNickNmame:string];
    }
}

- (void)chatroomManager_managerMessage:(NSString * )content {
    [self.notifyMarqueeView showNotifyhMessage:content];
    [self arrangeTopMarqueeViewFrame];
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
    } else if ([PLVLCQuoteMessageCell isModelValid:model]) {
        static NSString *quoteMessageCellIdentify = @"PLVLCQuoteMessageCell";
        PLVLCQuoteMessageCell *cell = (PLVLCQuoteMessageCell *)[tableView dequeueReusableCellWithIdentifier:quoteMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCQuoteMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:quoteMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        return cell;
    } else {
        static NSString *cellIdentify = @"cellIdentify";
        UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentify];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentify];
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.backgroundColor = [UIColor clearColor];
        }
        cell.textLabel.text = [model content];
        return cell;
    }
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat cellHeight =  44.0;
    if (indexPath.row >= [[[PLVLCChatroomViewModel sharedViewModel] chatArray] count]) {
        return cellHeight;
    }
    
    PLVChatModel *model = [[PLVLCChatroomViewModel sharedViewModel].chatArray objectAtIndex:indexPath.row];
    if ([PLVLCSpeakMessageCell isModelValid:model]) {
        cellHeight = [PLVLCSpeakMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
    } else if ([PLVLCImageMessageCell isModelValid:model]) {
        cellHeight = [PLVLCImageMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
    } else if ([PLVLCQuoteMessageCell isModelValid:model]) {
        cellHeight = [PLVLCQuoteMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
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

#pragma mark - PLVKeyboardToolView Delegate

- (BOOL)keyboardToolView_shouldInteract:(PLVKeyboardToolView *)toolView {
    return YES;
}

- (void)keyboardToolView:(PLVKeyboardToolView *)toolView popBoard:(BOOL)show {
    NSLog(@"keyboardToolView - popBoard %@", show ? @"YES" : @"NO");
}

- (void)keyboardToolView:(PLVKeyboardToolView *)toolView sendText:(NSString *)text {
    BOOL success = [[PLVLCChatroomViewModel sharedViewModel] sendSpeakMessage:text];
    if (!success) {
        [PLVLCUtils showHUDWithTitle:@"消息发送失败" detail:@"" view:self.view];
    }
}

- (void)keyboardToolView:(PLVKeyboardToolView *)toolView onlyTeacher:(BOOL)on {
    [PLVLCChatroomViewModel sharedViewModel].onlyTeacher = on;
    [self.tableView reloadData];
}

- (void)keyboardToolView_openAlbum:(PLVKeyboardToolView *)toolView {
    [PLVLiveVideoConfig sharedInstance].unableRotate = YES;
    [PLVFdUtil changeDeviceOrientationToPortrait];
    
    PLVPickerController *vctrl = [[PLVPickerController alloc] initWithPickerModer:PickerModerOfNormal];
    vctrl.delegate = self;
    PLVAlbumNavigationController *nav = [[PLVAlbumNavigationController alloc] initWithRootViewController:vctrl];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.liveRoom presentViewController:nav animated:YES completion:nil];
}

- (void)keyboardToolView_openCamera:(PLVKeyboardToolView *)toolView {
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

- (void)keyboardToolView_readBulletin:(PLVKeyboardToolView *)toolView {
    [[NSNotificationCenter defaultCenter] postNotificationName:PLVLCChatroomOpenBulletinNotification object:nil];
}

#pragma mark - PLVLCLikeButtonView Delegate

- (void)didTapLikeButton:(PLVLCLikeButtonView *)likeButtonView {
    [[PLVLCChatroomViewModel sharedViewModel] sendLike];
}

#pragma mark - PLVPickerController Delegate

- (void)pickerController:(PLVPickerController*)pVC uploadImage:(UIImage *)uploadImage {
    BOOL success = [[PLVLCChatroomViewModel sharedViewModel] sendImageMessage:uploadImage];
    if (!success) {
        [PLVLCUtils showHUDWithTitle:@"消息发送失败" detail:@"" view:self.view];
    }
}

- (void)dismissPickerController:(PLVPickerController*)pVC {
    UIViewController *liveRoomVC = (UIViewController *)self.liveRoom;
    [liveRoomVC dismissViewControllerAnimated:YES completion:^{
        [PLVLiveVideoConfig sharedInstance].unableRotate = NO;
    }];
}

#pragma mark - PLVCameraViewControllerDelegate Delegate
- (void)cameraViewController:(PLVCameraViewController *)cameraVC uploadImage:(UIImage *)uploadImage {
    [[PLVLCChatroomViewModel sharedViewModel] sendImageMessage:uploadImage];
}

- (void)dismissCameraViewController:(PLVCameraViewController*)cameraVC {
    UIViewController *liveRoomVC = (UIViewController *)self.liveRoom;
    [liveRoomVC dismissViewControllerAnimated:YES completion:^{
        [PLVLiveVideoConfig sharedInstance].unableRotate = NO;
    }];
}

@end
