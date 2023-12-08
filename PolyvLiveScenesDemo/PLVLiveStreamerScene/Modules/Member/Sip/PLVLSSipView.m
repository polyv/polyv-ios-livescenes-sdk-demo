//
//  PLVLSSipView.m
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2022/3/25.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSSipView.h"
/// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

/// UI
#import "PLVLSSipIncomingTelegramMemberCell.h"
#import "PLVLSSipCallingMemberCell.h"
#import "PLVLSSipAnsweredMemberCell.h"
#import "PLVLSSipNewIncomingTelegramView.h"

/// 工具
#import "PLVLSUtils.h"
#import "PLVSipLinkMicPresenter.h"
#import "PLVMultiLanguageManager.h"



@interface PLVLSSipView() <
UITableViewDelegate,
UITableViewDataSource,
PLVSipLinkMicPresenterDelegate
>

/// 列表
@property (nonatomic, strong) UITableView *tableView;
/// 来电提醒
@property (nonatomic, strong) PLVLSSipNewIncomingTelegramView *newIncomingTelegramView;

#pragma mark 对象
@property (nonatomic, strong) PLVSipLinkMicPresenter * presenter; // 连麦逻辑处理模块

@end

@implementation PLVLSSipView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initUI];
        self.presenter = [[PLVSipLinkMicPresenter alloc] init];
        self.presenter.delegate = self;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.tableView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
}


#pragma mark - [ Private Method ]

- (void)initUI {
    self.backgroundColor = [UIColor clearColor];
    [self addSubview:self.tableView];
}

#pragma mark Getter & Setter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.estimatedRowHeight = [PLVLSSipCallingMemberCell cellHeight];
        _tableView.rowHeight = [PLVLSSipCallingMemberCell cellHeight];
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return _tableView;
}

- (PLVLSSipNewIncomingTelegramView *)newIncomingTelegramView {
    if (!_newIncomingTelegramView) {
        _newIncomingTelegramView = [[PLVLSSipNewIncomingTelegramView alloc] init];
    }
    return _newIncomingTelegramView;
}


#pragma mark - [ Delegate ]
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.presenter.callInDialsArray.count;
    } else if (section == 1) {
        return self.presenter.callOutDialsArray.count;
    } else if (section == 2) {
        return self.presenter.inLineDialsArray.count;
    } else {
        return 10;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"";
    PLVLSSipMemberBaseCell *cell = nil;
    Class class = UITableViewCell.class;
    NSUInteger section = indexPath.section;
    NSArray *userList;
    if (section == 0) {
        class = PLVLSSipIncomingTelegramMemberCell.class;
        userList = self.presenter.callInDialsArray;
    } else if (section == 1) {
        class = PLVLSSipCallingMemberCell.class;
        userList = self.presenter.callOutDialsArray;
    } else if (section == 2) {
        class = PLVLSSipAnsweredMemberCell.class;
        userList = self.presenter.inLineDialsArray;
    }
    if (indexPath.row >= [userList count]) {
        return [UITableViewCell new];
    }
    
    cellIdentifier = NSStringFromClass(class);
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[class alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    [cell setModel:userList[indexPath.row]];
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 45;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc]init];
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(16, 21, 16, 16)];
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(36, 20, CGRectGetWidth(self.frame) - 32, 17)];
    textLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
    textLabel.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
    textLabel.textAlignment = NSTextAlignmentLeft;
    if (section == 0) {
        textLabel.text = [NSString stringWithFormat:PLVLocalizedString(@"待接通(%zd)"), self.presenter.callInDialsArray.count];
        [imageView setImage:[PLVLSUtils imageForMemberResource:@"plvls_member_sip_incomingTelegram_icon"]];
    } else if (section == 1) {
        textLabel.text = [NSString stringWithFormat:PLVLocalizedString(@"呼叫中(%zd)"), self.presenter.callOutDialsArray.count];
        [imageView setImage:[PLVLSUtils imageForMemberResource:@"plvls_member_sip_calling_icon"]];
    } else if (section == 2) {
        textLabel.text = [NSString stringWithFormat:PLVLocalizedString(@"已接通(%zd)"), self.presenter.inLineDialsArray.count];
        [imageView setImage:[PLVLSUtils imageForMemberResource:@"plvls_member_sip_answered_icon"]];
    }
    [headerView addSubview:imageView];
    [headerView addSubview:textLabel];
    return headerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

#pragma mark - [ Public Method ]

- (void)showNewIncomingTelegramView {
    [self.newIncomingTelegramView show];
}

#pragma mark PLVSipLinkMicPresenterDelegate

- (void)plvSipLinkMicPresenterUserListRefresh:(PLVSipLinkMicPresenter *)presenter {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)plvSipLinkMicPresenterHasNewCallInUser:(PLVSipLinkMicPresenter *)presenter {
    if (self.delegate && [self.delegate respondsToSelector:@selector(newCallingInSipView:)]) {
        [self.delegate newCallingInSipView:self];
    }
}

- (void)plvSipLinkMicPresenterHasNewCallOutUser:(PLVSipLinkMicPresenter *)presenter {
    if (self.delegate && [self.delegate respondsToSelector:@selector(newCallingInSipView:)]) {
        [self.delegate newCallingInSipView:self];
    }
}



@end
