//
//  PLVLSSettingSheetCell.m
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/5.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSSettingSheetCell.h"

// 选项按钮 tag 常量
static int kOptionButtonTagConst = 100;
// 选项按钮最大宽度，屏幕尺寸不足时根据屏幕尺寸进行缩减
static float kOptionButtonMaxWidth = 78.0;

@interface PLVLSSettingSheetCell ()

@property (nonatomic, strong) UILabel *titleLabel; // 左侧标题控件
@property (nonatomic, strong) NSArray <UIButton *> *optionsButton; // 选项按钮数组，只初始化一次
@property (nonatomic, strong) UIView *selectedView; // 选中选项底下蓝色圆点

@property (nonatomic, assign) NSInteger selectedIndex; // 选中索引，初始值为 -1

@end

@implementation PLVLSSettingSheetCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        
        [self.contentView addSubview:self.titleLabel];
        self.selectedIndex = -1;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.titleLabel.frame = CGRectMake(0, 0, 55, 30);
    
    CGFloat originX = 55;
    CGFloat buttonWidth = kOptionButtonMaxWidth;
    CGFloat leftWidth = self.contentView.bounds.size.width - originX;
    if (leftWidth < [self.optionsButton count] * kOptionButtonMaxWidth) {
        buttonWidth = floor(leftWidth / self.optionsButton.count);
    }
    CGFloat buttonHeight = self.titleLabel.bounds.size.height;
    for (int i = 0; i < [self.optionsButton count]; i++) {
        CGFloat buttonOriginX = originX + i * buttonWidth;
        UIButton *button = self.optionsButton[i];
        button.frame = CGRectMake(buttonOriginX, 0, buttonWidth, buttonHeight);
    }
    
    if (self.selectedIndex != -1) {
        self.selectedView.frame = CGRectMake(originX + self.selectedIndex * buttonWidth + (buttonWidth - 4) / 2.0, 25, 4, 4);
    }
}

#pragma mark - Getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:12];
        _titleLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
    }
    return _titleLabel;
}

- (UIView *)selectedView {
    if (!_selectedView) {
        _selectedView = [[UIView alloc] init];
        _selectedView.layer.cornerRadius = 2;
        _selectedView.layer.masksToBounds = YES;
        _selectedView.backgroundColor = [UIColor colorWithRed:0x43/255.0 green:0x99/255.0 blue:0xff/255.0 alpha:1];
    }
    return _selectedView;
}

#pragma mark - Action

- (void)optionButtonAction:(id)sender {
    UIButton *button = (UIButton *)sender;
    if (button.selected) {
        return;
    }
    
    NSInteger buttonIndex = button.tag - kOptionButtonTagConst;
    if (self.didSelectedAtIndex) {
        self.didSelectedAtIndex(buttonIndex);
    }
    
    for (int i = 0; i < [self.optionsButton count]; i++) {
        UIButton *button = self.optionsButton[i];
        button.selected = (i == buttonIndex);
    }
    self.selectedIndex = buttonIndex;
    
    if (!self.selectedView.superview) {
        [self.contentView addSubview:self.selectedView];
    }
    CGFloat buttonWidth = button.frame.size.width;
    self.selectedView.frame = CGRectMake(button.frame.origin.x + (buttonWidth - 4) / 2.0, 25, 4, 4);
}

#pragma mark - Public

- (void)setTitle:(NSString *)title optionsArray:(NSArray <NSString *> *)optionsArray selectedIndex:(NSInteger)selectedIndex {
    if (!title || ![title isKindOfClass:[NSString class]]) {
        title = @"";
    }
    self.titleLabel.text = title;
    [self updateOptions:optionsArray selectedIndex:selectedIndex];
}

- (void)updateOptions:(NSArray <NSString *> *)options selectedIndex:(NSInteger)selectedIndex {
    if (!options || ![options isKindOfClass:[NSArray class]]) {
        return;
    }
    
    if (!self.optionsButton) { // 设置选项只初始化一次就不再改变，cell不做复用
        NSMutableArray *buttonMuArray = [[NSMutableArray alloc] initWithCapacity:[options count]];
        for (int i = 0; i < [options count]; i++) {
            NSString *option = options[i];
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.tag = i + kOptionButtonTagConst;
            button.titleLabel.font = [UIFont systemFontOfSize:14];
            [button setTitle:option forState:UIControlStateNormal];
            UIColor *normalColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
            UIColor *selectedColor = [UIColor colorWithRed:0x43/255.0 green:0x99/255.0 blue:0xff/255.0 alpha:1];
            [button setTitleColor:normalColor forState:UIControlStateNormal];
            [button setTitleColor:selectedColor forState:UIControlStateSelected];
            [button addTarget:self action:@selector(optionButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            [buttonMuArray addObject:button];
            [self.contentView addSubview:button];
        }
        self.optionsButton = [buttonMuArray copy];
    }
    
    if (selectedIndex < 0 || selectedIndex >= [self.optionsButton count] ||
        self.selectedIndex == selectedIndex) {
        return;
    }
    
    if (self.selectedIndex == -1) {
        [self.contentView addSubview:self.selectedView];
    }
    
    for (int i = 0; i < [self.optionsButton count]; i++) {
        UIButton *button = self.optionsButton[i];
        button.selected = (i == selectedIndex);
    }
    self.selectedIndex = selectedIndex;
}

+ (CGFloat)cellHeight {
    return 30 + 15;
}
@end
