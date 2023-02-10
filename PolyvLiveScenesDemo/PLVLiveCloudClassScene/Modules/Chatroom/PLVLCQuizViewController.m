//
//  PLVLCQuizViewController.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/24.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCQuizViewController.h"
#import "PLVRoomDataManager.h"
#import "PLVLCKeyboardToolView.h"
#import "PLVLCNewMessageView.h"
#import "PLVLCQuitSpeakMessageCell.h"
#import "PLVLCChatroomViewModel.h"
#import "PLVLCUtils.h"
#import "PLVLCImageMessageCell.h"

@interface PLVLCQuizViewController ()<
PLVLCKeyboardToolViewDelegate,
PLVLCChatroomViewModelProtocol,
UITableViewDelegate,
UITableViewDataSource
>

/// 是否已完成对子视图的布局，默认为 NO，完成布局后为 YES
@property (nonatomic, assign) BOOL hasLayoutSubView;
/// 聊天列表
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) CGPoint lastContentOffset;
/// 新消息提示条幅
@property (nonatomic, strong) PLVLCNewMessageView *receiveNewMessageView;
/// 聊天室置底控件
@property (nonatomic, strong) PLVLCKeyboardToolView *keyboardToolView;

/// 未读消息条数
@property (nonatomic, assign) NSUInteger newMessageCount;

@end

@implementation PLVLCQuizViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.tableView];
    
    [self.view addSubview:self.receiveNewMessageView];
    
    [[PLVLCChatroomViewModel sharedViewModel] addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [[PLVLCChatroomViewModel sharedViewModel] createAnswerChatModel];
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
    }
}
    
- (void)viewDidLayoutSubviews {
    if (!self.hasLayoutSubView) { // 初次布局
        CGFloat height = PLVLCKeyboardToolViewHeight + P_SafeAreaBottomEdgeInsets();
        CGRect inputRect = CGRectMake(0, CGRectGetHeight(self.view.bounds) - height, CGRectGetWidth(self.view.bounds), height);
        [self.keyboardToolView addAtView:self.view frame:inputRect];
        self.receiveNewMessageView.frame = CGRectMake(0, inputRect.origin.y - 28, CGRectGetWidth(self.view.bounds), 28);
        self.tableView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - height);
        
        self.hasLayoutSubView = YES;
    }
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
    }
    return _tableView;
}

- (PLVLCKeyboardToolView *)keyboardToolView {
    if (!_keyboardToolView) {
        _keyboardToolView = [[PLVLCKeyboardToolView alloc] initWithMode:PLVLCKeyboardToolModeSimple];
        _keyboardToolView.delegate = self;
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

#pragma mark - Action

- (void)readNewMessageAction { // 点击底部未读消息条幅时触发
    [self clearNewMessageCount];
    [self scrollsToBottom:YES];
}

#pragma mark - Private

- (void)scrollsToBottom:(BOOL)animated {
    CGFloat offsetY = self.tableView.contentSize.height - self.tableView.bounds.size.height;
    offsetY = MAX(0, offsetY);
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

#pragma mark - PLVLCKeyboardToolView Delegate

- (BOOL)keyboardToolView_shouldInteract:(PLVLCKeyboardToolView *)toolView {
    return YES;
}

- (void)keyboardToolView:(PLVLCKeyboardToolView *)toolView sendText:(NSString *)text replyModel:(PLVChatModel *)replyModel {
    BOOL success = [[PLVLCChatroomViewModel sharedViewModel] sendQuesstionMessage:text];
    if (!success) {
        [PLVLCUtils showHUDWithTitle:@"消息发送失败" detail:@"" view:self.view];
    }
}

#pragma mark - PLVLCChatroomViewModelProtocol

- (void)chatroomManager_didSendQuestionMessage {
    [self.tableView reloadData];
    [self scrollsToBottom:YES];
    [self clearNewMessageCount];
}

- (void)chatroomManager_didReceiveAnswerMessage {
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

#pragma mark - UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[PLVLCChatroomViewModel sharedViewModel].privateChatArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= [[[PLVLCChatroomViewModel sharedViewModel] privateChatArray] count]) {
        return [UITableViewCell new];
    }
    
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    PLVChatModel *model = [[PLVLCChatroomViewModel sharedViewModel] privateChatArray][indexPath.row];
    
    if ([PLVLCImageMessageCell isModelValid:model]) {
        static NSString *imageMessageCellIdentify = @"PLVLCQuizImageMessageCell";
        PLVLCImageMessageCell *cell = (PLVLCImageMessageCell *)[tableView dequeueReusableCellWithIdentifier:imageMessageCellIdentify];
        if (!cell) {
            cell = [[PLVLCImageMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:imageMessageCellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
        return cell;
    } else if([PLVLCQuitSpeakMessageCell isModelValid:model]) {
        static NSString *cellIdentify = @"PLVLCQuizSpeakMessageCell";
        PLVLCQuitSpeakMessageCell *cell = (PLVLCQuitSpeakMessageCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentify];
        if (!cell) {
            cell = [[PLVLCQuitSpeakMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentify];
        }
        [cell updateWithModel:model loginUserId:roomUser.viewerId cellWidth:self.tableView.frame.size.width];
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
    if (indexPath.row >= [[[PLVLCChatroomViewModel sharedViewModel] privateChatArray] count]) {
        return 0.0;
    }
    
    CGFloat cellHeight = 0.0;
    PLVChatModel *model = [[PLVLCChatroomViewModel sharedViewModel].privateChatArray objectAtIndex:indexPath.row];
    if ([PLVLCImageMessageCell isModelValid:model]) {
        cellHeight = [PLVLCImageMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
    } else if ([PLVLCQuitSpeakMessageCell isModelValid:model]) {
        cellHeight = [PLVLCQuitSpeakMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
    } else {
        cellHeight = 0.0;
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

@end
