//
//  PLVECSubtitleTranslationSelectView.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/10/10.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVECSubtitleTranslationSelectView.h"
#import "PLVECUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFdUtil.h>
#import <PLVFoundationSDK/PLVColorUtil.h>

@interface PLVECSubtitleTranslationSelectView () <UITableViewDataSource, UITableViewDelegate>

/// 数据
@property (nonatomic, strong) NSArray<PLVPlaybackSubtitleModel *> *subtitleList;
@property (nonatomic, strong) PLVPlaybackSubtitleModel *selectedModel;

/// UI
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation PLVECSubtitleTranslationSelectView

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat contentWidth = CGRectGetWidth(self.bounds);
    CGFloat contentHeight = CGRectGetHeight(self.bounds);
    
    // 标题和返回按钮
    self.backButton.frame = CGRectMake(16, 20, 24, 24);
    self.titleLabel.frame = CGRectMake(0, 20, contentWidth, 24);
    
    // 表格视图
    CGFloat tableY = CGRectGetMaxY(self.titleLabel.frame) + 20;
    self.tableView.frame = CGRectMake(0, tableY, contentWidth, contentHeight - tableY - 20);
}

#pragma mark - Private Methods

- (void)setupUI {
    // 返回按钮
    [self addSubview:self.backButton];
    
    // 标题
    [self addSubview:self.titleLabel];
    
    // 表格视图
    [self addSubview:self.tableView];
}

#pragma mark - Public Methods

- (void)setupWithSubtitleList:(NSArray<PLVPlaybackSubtitleModel *> *)subtitleList 
                selectedModel:(PLVPlaybackSubtitleModel *)selectedModel {
    self.subtitleList = subtitleList;
    self.selectedModel = selectedModel;
    [self.tableView reloadData];
}

- (void)showInView:(UIView *)parentView {
    if (!parentView) return;
    
    [parentView addSubview:self];
    self.hidden = NO;
}

- (void)hide {
    self.hidden = YES;
    [self removeFromSuperview];
}

#pragma mark - Event Response

- (void)backButtonAction:(UIButton *)button {
    [self hide];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.subtitleList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"PLVECSubtitleTranslationSelectCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // 设置文本样式
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        
        // 添加选中状态图标
        UIImageView *checkmarkImageView = [[UIImageView alloc] init];
        checkmarkImageView.image = [PLVECUtils imageForWatchResource:@"plv_checkbox_selected"];
        checkmarkImageView.tag = 100;
        [cell.contentView addSubview:checkmarkImageView];
        
        // 设置约束
        checkmarkImageView.frame = CGRectMake(0, 0, 20, 20);
        cell.accessoryView = checkmarkImageView;
    }
    
    PLVPlaybackSubtitleModel *model = self.subtitleList[indexPath.row];
    cell.textLabel.text = PLVLocalizedString(model.language);
    
    // 更新选中状态
    BOOL isSelected = [model isEqual:self.selectedModel];
    UIImageView *checkmarkImageView = (UIImageView *)cell.accessoryView;
    checkmarkImageView.hidden = !isSelected;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PLVPlaybackSubtitleModel *selectedModel = self.subtitleList[indexPath.row];
    self.selectedModel = selectedModel;
    
    // 更新UI
    [self.tableView reloadData];
    
    // 回调
    if (self.selectionHandler) {
        self.selectionHandler(selectedModel);
    }
    
    // 延迟隐藏，让用户看到选中效果
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hide];
    });
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

#pragma mark - Getter & Setter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = PLVLocalizedString(@"翻译字幕");
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont boldSystemFontOfSize:18];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setImage:[PLVECUtils imageForWatchResource:@"plv_back_btn"] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.separatorColor = PLV_UIColorFromRGBA(@"#FFFFFF", 0.1);
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.showsVerticalScrollIndicator = NO;
        
        // 设置表格头部和底部视图
        _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 10)];
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 10)];
    }
    return _tableView;
}

@end
