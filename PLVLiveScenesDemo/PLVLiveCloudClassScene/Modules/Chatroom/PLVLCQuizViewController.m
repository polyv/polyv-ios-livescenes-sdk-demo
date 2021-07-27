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
#import "PLVLCSpeakMessageCell.h"
#import "PLVLCChatroomViewModel.h"
#import "PLVLCUtils.h"

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

- (void)keyboardToolView:(PLVLCKeyboardToolView *)toolView sendText:(NSString *)text {
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
    static NSString *cellIdentify = @"cellIdentify";
    PLVLCSpeakMessageCell *cell = (PLVLCSpeakMessageCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentify];
    if (!cell) {
        cell = [[PLVLCSpeakMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentify];
    }
    PLVChatModel *model = [[PLVLCChatroomViewModel sharedViewModel].privateChatArray objectAtIndex:indexPath.row];
    [cell updateWithModel:model loginUserId:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId cellWidth:self.tableView.frame.size.width];
    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLVChatModel *model = [[PLVLCChatroomViewModel sharedViewModel].privateChatArray objectAtIndex:indexPath.row];
    CGFloat cellHeight = [PLVLCSpeakMessageCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
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
