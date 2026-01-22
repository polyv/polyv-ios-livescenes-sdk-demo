//
//  PLVLCRealTimeSubtitleLanguageSelectView.m
//  PolyvLiveScenesDemo
//
//  Created on 2024.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVLCRealTimeSubtitleLanguageSelectView.h"
#import "PLVLiveRealTimeSubtitleHandler.h"
#import "PLVLCUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFdUtil.h>
#import <PLVFoundationSDK/PLVColorUtil.h>

static CGFloat kRealTimeSubtitleLanguageSelectSheetHeight = 396.0;      // 竖屏时弹窗高度
static CGFloat kRealTimeSubtitleLanguageSelectSheetLandscapeWidth = 375.0; // 横屏时弹窗宽度

/// 语言代码对应的显示名称（使用统一的语言映射方法）
static NSString *LanguageDisplayName(NSString *languageCode) {
    return [PLVLiveRealTimeSubtitleHandler languageNameForCode:languageCode];
}

@interface PLVLCRealTimeSubtitleLanguageSelectView () <UITableViewDataSource, UITableViewDelegate>

/// 数据
@property (nonatomic, strong) NSArray<NSString *> *languages;
@property (nonatomic, copy) NSString *selectedLanguage;

/// UI
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation PLVLCRealTimeSubtitleLanguageSelectView

#pragma mark - Life Cycle

- (instancetype)init {
    return [self initWithSheetHeight:kRealTimeSubtitleLanguageSelectSheetHeight
                 sheetLandscapeWidth:kRealTimeSubtitleLanguageSelectSheetLandscapeWidth];
}

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth {
    self = [super initWithSheetHeight:sheetHeight
                  sheetLandscapeWidth:sheetLandscapeWidth
                      backgroundColor:[UIColor clearColor]];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (CGRectIsEmpty(self.contentView.bounds)) {
        return;
    }
    
    CGFloat contentWidth = CGRectGetWidth(self.contentView.bounds);
    CGFloat contentHeight = CGRectGetHeight(self.contentView.bounds);
    
    // 标题和返回按钮
    self.backButton.frame = CGRectMake(16, 20, 24, 24);
    self.titleLabel.frame = CGRectMake(0, 20, contentWidth, 24);
    
    // 表格视图
    CGFloat tableY = CGRectGetMaxY(self.titleLabel.frame) + 20;
    self.tableView.frame = CGRectMake(0, tableY, contentWidth, contentHeight - tableY - 20);
}

#pragma mark - Private Methods

- (void)setupUI {
    // 设置背景色
    self.contentView.backgroundColor = PLV_UIColorFromRGBA(@"#202127", 1.0);
    [self setSheetCornerRadius:16];
    
    // 返回按钮
    [self.contentView addSubview:self.backButton];
    
    // 标题
    [self.contentView addSubview:self.titleLabel];
    
    // 表格视图
    [self.contentView addSubview:self.tableView];
}

#pragma mark - Public Methods

- (void)setupWithLanguages:(NSArray<NSString *> *)languages 
           selectedLanguage:(NSString *)selectedLanguage {
    self.languages = languages;
    self.selectedLanguage = selectedLanguage;
    [self.tableView reloadData];
}

- (void)showInView:(UIView *)parentView {
    [super showInView:parentView];
}

- (void)hide {
    [self dismiss];
}

- (void)deviceOrientationDidChange {
    [self dismiss];
}

#pragma mark - Event Response

- (void)backButtonAction:(UIButton *)button {
    [self hide];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.languages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"PLVLCRealTimeSubtitleLanguageSelectCell";
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
        checkmarkImageView.image = [PLVLCUtils imageForLiveRoomResource:@"plv_checkbox_selected"];
        if (!checkmarkImageView.image) {
            // 如果没有图片资源，创建一个简单的勾号
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(20, 20), NO, 0);
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(4, 10)];
            [path addLineToPoint:CGPointMake(8, 14)];
            [path addLineToPoint:CGPointMake(16, 6)];
            [PLV_UIColorFromRGB(@"#4399FF") setStroke];
            path.lineWidth = 2;
            [path stroke];
            checkmarkImageView.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        checkmarkImageView.tag = 100;
        [cell.contentView addSubview:checkmarkImageView];
        
        // 设置约束
        checkmarkImageView.frame = CGRectMake(0, 0, 20, 20);
        cell.accessoryView = checkmarkImageView;
    }
    
    NSString *languageCode = self.languages[indexPath.row];
    NSString *displayName = LanguageDisplayName(languageCode);
    cell.textLabel.text = displayName;
    
    // 更新选中状态
    BOOL isSelected = [languageCode isEqualToString:self.selectedLanguage];
    UIImageView *checkmarkImageView = (UIImageView *)cell.accessoryView;
    checkmarkImageView.hidden = !isSelected;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *selectedLanguage = self.languages[indexPath.row];
    self.selectedLanguage = selectedLanguage;
    
    // 更新UI
    [self.tableView reloadData];
    
    // 回调
    if (self.selectionHandler) {
        self.selectionHandler(selectedLanguage);
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
        _titleLabel.text = PLVLocalizedString(@"字幕语言");
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont boldSystemFontOfSize:18];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setImage:[PLVLCUtils imageForLiveRoomResource:@"plv_back_btn"] forState:UIControlStateNormal];
        if (!_backButton.currentImage) {
            // 如果没有图片资源，设置一个返回文字
            [_backButton setTitle:@"<" forState:UIControlStateNormal];
            [_backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
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
