//
//  PLVChatroomView.m
//  PolyvLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECChatroomView.h"
#import "PLVECNewMessageView.h"
#import "PLVECWelcomView.h"
#import "PLVECChatCell.h"
#import "PLVECUtils.h"
#import "PLVECChatroomViewModel.h"
#import "PLVRoomDataManager.h"
#import <MJRefresh/MJRefresh.h>

#define TEXT_MAX_COUNT 200

#define KEYPATH_CONTENTSIZE @"contentSize"

@interface PLVECChatroomView () <
UITextViewDelegate,
UITableViewDelegate,
UITableViewDataSource,
PLVECChatroomViewModelProtocol
>

/// 聊天列表
@property (nonatomic, strong) UITableView *tableView;
/// 聊天室列表顶部加载更多控件
@property (nonatomic, strong) MJRefreshNormalHeader *refresher;
/// 新消息提示条幅
@property (nonatomic, strong) PLVECNewMessageView *receiveNewMessageView;

@property (nonatomic, strong) PLVECWelcomView *welcomView;
@property (nonatomic, assign) CGRect originWelcomViewFrame;

@property (nonatomic, strong) UIView *tableViewBackgroundView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, assign) BOOL observingTableView;

@property (nonatomic, strong) UIView *textAreaView;

@property (nonatomic, strong) UIView *tapView;
@property (nonatomic, strong) UITextView *textView;

@end

@implementation PLVECChatroomView

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserveTableView];
}

- (instancetype)init {
    self = [self initWithFrame:CGRectZero];
    if (self) {
        [[PLVECChatroomViewModel sharedViewModel] setup];
        [PLVECChatroomViewModel sharedViewModel].delegate = self;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        
        self.observingTableView = NO;
        [self observeTableView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        
        self.welcomView = [[PLVECWelcomView alloc] init];
        self.welcomView.hidden = YES;
        [self addSubview:self.welcomView];
        
        // 渐变蒙层
        self.gradientLayer = [CAGradientLayer layer];
        self.gradientLayer.startPoint = CGPointMake(0, 0);
        self.gradientLayer.endPoint = CGPointMake(0, 0.1);
        self.gradientLayer.colors = @[(__bridge id)[UIColor.clearColor colorWithAlphaComponent:0].CGColor, (__bridge id)[UIColor.clearColor colorWithAlphaComponent:1.0].CGColor];
        self.gradientLayer.locations = @[@(0), @(1.0)];
        self.gradientLayer.rasterizationScale = UIScreen.mainScreen.scale;
        
        self.tableViewBackgroundView = [[UIView alloc] init];
        [self addSubview:self.tableViewBackgroundView];
        self.tableViewBackgroundView.layer.mask = self.gradientLayer;
        
        self.tableView = [[UITableView alloc] init];
        self.tableView.backgroundColor = [UIColor clearColor];
        self.tableView.scrollEnabled = NO;
        self.tableView.allowsSelection =  NO;
        self.tableView.showsVerticalScrollIndicator = NO;
        self.tableView.showsHorizontalScrollIndicator = NO;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.estimatedRowHeight = 0;
        self.tableView.estimatedSectionFooterHeight = 0;
        self.tableView.estimatedSectionHeaderHeight = 0;
        self.tableView.mj_header = self.refresher;
        [self.tableViewBackgroundView addSubview:self.tableView];
        
        self.receiveNewMessageView = [[PLVECNewMessageView alloc] init];
        self.receiveNewMessageView.hidden = YES;
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(readNewMessageAction)];
        [self.receiveNewMessageView addGestureRecognizer:gesture];
        [self addSubview:self.receiveNewMessageView];
        
        self.textAreaView = [[UIView alloc] init];
        self.textAreaView.layer.cornerRadius = 20.0;
        self.textAreaView.layer.masksToBounds = YES;
        self.textAreaView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        [self addSubview:self.textAreaView];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(textAreaViewTapAction)];
        [self.textAreaView addGestureRecognizer:tapGesture];
        
        UIImageView *leftImgView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 16, 16)];
        leftImgView.image = [PLVECUtils imageForWatchResource:@"plv_chat_img"];
        [self.textAreaView addSubview:leftImgView];
        
        UILabel *placeholderLB = [[UILabel alloc] initWithFrame:CGRectMake(30, 9, 130, 14)];
        placeholderLB.text = @"跟大家聊点什么吧～";
        placeholderLB.font = [UIFont systemFontOfSize:14];
        placeholderLB.textColor = [UIColor colorWithWhite:1.0 alpha:0.6];
        [self.textAreaView addSubview:placeholderLB];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat tableViewHeight = 156;
    self.textAreaView.frame = CGRectMake(15, CGRectGetHeight(self.bounds)-15-32, 165, 32);
    self.tableViewBackgroundView.frame = CGRectMake(15, CGRectGetMinY(self.textAreaView.frame)-tableViewHeight-15, 234, tableViewHeight);
    self.gradientLayer.frame = self.tableViewBackgroundView.bounds;
    self.welcomView.frame = CGRectMake(-258, CGRectGetMinY(self.tableViewBackgroundView.frame)-22-15, 258, 22);
    self.originWelcomViewFrame = self.welcomView.frame;
    
    CGFloat tvbBottom = self.tableViewBackgroundView.frame.origin.y + tableViewHeight;
    self.receiveNewMessageView.frame = CGRectMake(15, tvbBottom - 24, 86, 24);
}

#pragma mark - Getter

- (UIView *)tapView {
    if (!_tapView) {
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        
        _tapView = [[UIView alloc] initWithFrame:window.bounds];
        _tapView.backgroundColor = [UIColor clearColor];
        [window addSubview:_tapView];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapViewAction)];
        [_tapView addGestureRecognizer:tapGesture];
    }
    return _tapView;
}

- (UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc] init];
        _textView.frame = CGRectMake(0, CGRectGetHeight(self.tapView.bounds)-46, CGRectGetWidth(self.tapView.bounds), 46);
        _textView.delegate = self;
        _textView.textColor = [UIColor colorWithWhite:51/255.0 alpha:1];
        _textView.textContainerInset = UIEdgeInsetsMake(10, 8, 10, 8);
        _textView.font = [UIFont systemFontOfSize:14.0];
        _textView.backgroundColor = UIColor.whiteColor;
        _textView.showsVerticalScrollIndicator = NO;
        _textView.showsHorizontalScrollIndicator = NO;
        _textView.returnKeyType = UIReturnKeySend;
        [self.tapView addSubview:_textView];
    }
    return _textView;
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

#pragma mark - Action

- (void)textAreaViewTapAction {
    if (!self.textView.isFirstResponder) {
        self.textView.hidden = NO;
        [self.textView becomeFirstResponder];
    }
}

- (void)tapViewAction {
    [self.tapView setHidden:YES];
    [self.textView setHidden:YES];
    if (self.textView.isFirstResponder) {
        [self.textView resignFirstResponder];
    }
}

- (void)refreshAction:(MJRefreshNormalHeader *)refreshHeader {
    [[PLVECChatroomViewModel sharedViewModel] loadHistory];
}

- (void)readNewMessageAction { // 点击底部未读消息条幅时触发
    [self.receiveNewMessageView hidden];
    [self scrollsToBottom];
}

#pragma mark - KVO

- (void)observeTableView {
    if (!self.observingTableView) {
        self.observingTableView = YES;
        [self.tableView addObserver:self forKeyPath:KEYPATH_CONTENTSIZE options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)removeObserveTableView {
    if (self.observingTableView) {
        self.observingTableView = NO;
        [self.tableView removeObserver:self forKeyPath:KEYPATH_CONTENTSIZE];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([object isKindOfClass:UITableView.class] && [keyPath isEqualToString:KEYPATH_CONTENTSIZE]) {
        CGFloat contentHeight = self.tableView.contentSize.height;
        if (contentHeight < CGRectGetHeight(self.tableViewBackgroundView.bounds)) {
            [UIView animateWithDuration:0.2 animations:^{
                CGRect newFrame = CGRectMake(0, CGRectGetHeight (self.tableViewBackgroundView.bounds)-contentHeight, CGRectGetWidth(self.tableViewBackgroundView.bounds), contentHeight);
                self.tableView.frame = newFrame;
            }];
        } else if (CGRectGetHeight(self.tableViewBackgroundView.bounds) > 0) {
            self.tableView.scrollEnabled = YES;
            self.tableView.frame = self.tableViewBackgroundView.bounds;
            [self removeObserveTableView];
        }
    }
}

#pragma mark - Notifications

- (void)keyboardWillShow:(NSNotification *)notification {
    if (!self.textView.isFirstResponder) {
        return;
    }
    
    [self followKeyboardAnimated:notification.userInfo show:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if (!self.textView.isFirstResponder) {
        return;
    }
    
    [self followKeyboardAnimated:notification.userInfo show:NO];
}

#pragma mark - PLVECChatroomViewModelProtocol

- (void)chatroomManager_didSendMessage {
    [self.tableView reloadData];
    [self scrollsToBottom];
}

- (void)chatroomManager_didReceiveMessages {
    // 如果距离底部5内都算底部
    BOOL isBottom = (self.tableView.contentSize.height
                     - self.tableView.contentOffset.y
                     - self.tableView.bounds.size.height) <= 5;
    
    [self.tableView reloadData];
    
    if (isBottom) { // tableview显示在最底部
        [self.receiveNewMessageView hidden];
        [self scrollsToBottom];
    } else {
        // 显示未读消息提示
        [self.receiveNewMessageView show];
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
        [self scrollsToBottom];
    } else {
        [self.tableView scrollsToTop];
    }
}

- (void)chatroomManager_loadHistoryFailure {
    [self.refresher endRefreshing];
    [PLVECUtils showHUDWithTitle:@"聊天记录获取失败" detail:@"" view:self];
}

#pragma mark 显示欢迎语

- (void)chatroomManager_loginUsers:(NSArray <PLVChatUser *> * _Nullable )userArray {
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
        NSString *welcomeMessage = [NSString stringWithFormat:@"欢迎 %@ 进入直播间", string];
        [self showWelcomeWithMessage:welcomeMessage];
    }
}

- (void)showWelcomeWithMessage:(NSString *)welcomeMessage {
    if (!self.welcomView.hidden) {
        [self shutdownWelcomView];
    }
    
    self.welcomView.hidden = NO;
    
    CGFloat duration = 2.0;
    self.welcomView.messageLB.text = welcomeMessage;
    [UIView animateWithDuration:1.0 animations:^{
       CGRect newFrame = self.welcomView.frame;
       newFrame.origin.x = 0;
       self.welcomView.frame = newFrame;
    }];

    SEL shutdownWelcomView = @selector(shutdownWelcomView);
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:shutdownWelcomView object:nil];
    [self performSelector:shutdownWelcomView withObject:nil afterDelay:duration];
}

- (void)shutdownWelcomView {
    self.welcomView.hidden = YES;
    self.welcomView.frame = self.originWelcomViewFrame;
}

#pragma mark - UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[PLVECChatroomViewModel sharedViewModel].chatArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentify = @"cellIdentify";
    PLVECChatCell *cell = (PLVECChatCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentify];
    if (!cell) {
        cell = [[PLVECChatCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentify];
    }
    PLVChatModel *model = [[PLVECChatroomViewModel sharedViewModel].chatArray objectAtIndex:indexPath.row];
    [cell updateWithModel:model cellWidth:self.tableView.frame.size.width];
    return cell;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLVChatModel *model = [[PLVECChatroomViewModel sharedViewModel].chatArray objectAtIndex:indexPath.row];
    CGFloat cellHeight = [PLVECChatCell cellHeightWithModel:model cellWidth:self.tableView.frame.size.width];
    return cellHeight;
}

#pragma mark - Private

- (void)sendMessage {
    if (self.textView.text.length > 0) {
        [self tapViewAction];
        BOOL success = [[PLVECChatroomViewModel sharedViewModel] sendSpeakMessage:self.textView.text];
        if (!success) {
            [PLVECUtils showHUDWithTitle:@"消息发送失败" detail:@"" view:self];
        }
        self.textView.text = @"";
    }
}

- (void)followKeyboardAnimated:(NSDictionary *)userInfo show:(BOOL)show {
    [self.tapView setHidden:!show];

    CGRect keyBoardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    double duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    duration = MAX(0.3, duration);
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGRect newFrame = self.textView.frame;
        newFrame.origin.y = CGRectGetMinY(keyBoardFrame) - CGRectGetHeight(newFrame);
        self.textView.frame = newFrame;
    } completion:^(BOOL finished) {
        if (!show) {
            self.textView.hidden = YES;
        }
    }];
}

- (void)scrollsToBottom {
    CGFloat offsetY = self.tableView.contentSize.height - self.tableView.bounds.size.height;
    offsetY = MAX(0, offsetY);
    [self.tableView setContentOffset:CGPointMake(0.0, offsetY) animated:YES];
}

#pragma mark - <UITextViewDelegate>

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    // Prevent crashing undo bug
    if(range.location + range.length > textView.text.length) {
        return NO;
    }
    
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        [self sendMessage];
        return NO;
    }
    
    // 当前文本框字符长度（中英文、表情键盘上表情为一个字符，系统emoji为两个字符）
    NSUInteger newLength = textView.attributedText.length + text.length - range.length;
    if (newLength > TEXT_MAX_COUNT) {
        NSLog(@"输入字数超限！");
        return NO;
    }
    
    return YES;
}

@end
