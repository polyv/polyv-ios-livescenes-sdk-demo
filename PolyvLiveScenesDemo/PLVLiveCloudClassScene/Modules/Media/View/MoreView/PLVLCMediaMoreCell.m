//
//  PLVLCMediaMoreCell.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/9/29.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCMediaMoreCell.h"

#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCMediaMoreCell ()

#pragma mark 数据
@property (nonatomic, strong) PLVLCMediaMoreModel * currentModel;

#pragma mark UI
@property (nonatomic, strong) UIButton * currentSelectedButton;
@property (nonatomic, strong) NSMutableArray <UIButton *> * buttonsArray;
/// view hierarchy
///
/// (PLVLCMediaMoreCell) self
/// └── (UIView) contentView
///     ├── (UILabel) optionTitleLabel
///     ├── (UIButton) optionItemButton
///     ├── (UIButton) ...
///     └── (UIButton) optionItemButton
@property (nonatomic, strong) UILabel * optionTitleLabel;

@end

@implementation PLVLCMediaMoreCell

#pragma mark - [ Life Period ]
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setupData];
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews{
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    
    if (!fullScreen) {
        // 竖屏布局
        CGFloat topPadding = 15.0;
        
        CGFloat leftPaddingScale = 88.0 / 375.0;
        CGFloat leftPadding = leftPaddingScale * viewWidth;
        
        CGFloat controlsHeight = 26.0;
        
        CGFloat optionTitleLabelLeftPaddingForTail = leftPadding - 24.0;
        CGFloat optionTitleLabelWidth = [self.optionTitleLabel sizeThatFits:CGSizeMake(60, controlsHeight)].width;
        CGFloat optionTitleLabelX = optionTitleLabelLeftPaddingForTail - optionTitleLabelWidth;
        self.optionTitleLabel.textAlignment = NSTextAlignmentRight;
        self.optionTitleLabel.frame = CGRectMake(optionTitleLabelX, topPadding, optionTitleLabelWidth, controlsHeight);
        
        UIButton * lastButton;
        for (int i = 0; i < self.buttonsArray.count; i++) {
            UIButton * button = self.buttonsArray[i];
            
            CGFloat buttonsPadding = 16.0;
            CGFloat buttonX = (i == 0 ? leftPadding : CGRectGetMaxX(lastButton.frame) + buttonsPadding);
            CGFloat buttonWidth = [button.titleLabel sizeThatFits:CGSizeMake(100, controlsHeight)].width + (12 * 2);
            if (self.currentModel.optionSpecifiedWidth > 0) {
                buttonWidth = self.currentModel.optionSpecifiedWidth;
            }else if (buttonWidth < 66.0) {
                buttonWidth = 66.0;
            }
            button.frame = CGRectMake(buttonX, topPadding, buttonWidth, controlsHeight);
            lastButton = button;
        }
    }else{
        // 横屏布局
        CGFloat leftPadding = 16.0;
        self.optionTitleLabel.textAlignment = NSTextAlignmentLeft;
        self.optionTitleLabel.frame = CGRectMake(leftPadding, 0, 60, 20);
        
        UIButton * lastButton;
        for (int i = 0; i < self.buttonsArray.count; i++) {
            UIButton * button = self.buttonsArray[i];
            
            CGFloat buttonsPadding = 16.0;
            CGFloat buttonX = (i == 0 ? leftPadding : CGRectGetMaxX(lastButton.frame) + buttonsPadding);
            CGFloat buttonWidth = [button.titleLabel sizeThatFits:CGSizeMake(100, 26.0)].width + (12 * 2);
            if (self.currentModel.optionSpecifiedWidth > 0) {
                buttonWidth = self.currentModel.optionSpecifiedWidth;
            }else if (buttonWidth < 66.0) {
                buttonWidth = 66.0;
            }
            button.frame = CGRectMake(buttonX, 32, buttonWidth, 26.0);
            lastButton = button;
        }
    }
}


#pragma mark - [ Public Methods ]
- (void)setModel:(PLVLCMediaMoreModel *)model{
    /// 隐藏 Buttons
    /// (避免 Tableview 复用导致按钮显示异常)
    for (UIView * subviews in self.contentView.subviews) {
        if ([subviews isKindOfClass:UIButton.class]) {
            subviews.hidden = YES;
        }
    }
    
    self.optionTitleLabel.text = model.optionTitle;
    [self resetCurrentSelectedButton];
    
    /// 创建或复用 Buttons
    if ([PLVFdUtil checkArrayUseable:model.optionItemsArray]) {
        for (int i = 0; i < model.optionItemsArray.count; i++) {
            NSString * optionItemTitle = model.optionItemsArray[i];
            UIButton * button;
            if (i < self.buttonsArray.count) { button = self.buttonsArray[i]; }
            if (button) {
                [button setTitle:optionItemTitle forState:UIControlStateNormal];
            }else{
                button = [self createButtonWithOptionItemTitle:optionItemTitle];
                [self.contentView addSubview:button];
                [self.buttonsArray addObject:button];
            }
            if (model.selectedIndex == i) { self.currentSelectedButton = button; }
            button.hidden = NO;
        }
    }
    
    self.currentModel = model;
}


#pragma mark - [ Private Methods ]
- (void)setupData{
    self.buttonsArray = [[NSMutableArray <UIButton *> alloc] init];
}

- (void)setupUI{
    self.backgroundColor = [UIColor clearColor];
    
    // 添加视图
    [self.contentView addSubview:self.optionTitleLabel];
}

- (UIButton *)createButtonWithOptionItemTitle:(NSString *)optionItemTitle{
    UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:optionItemTitle forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitleColor:PLV_UIColorFromRGB(@"6DA7FF") forState:UIControlStateSelected];
    button.titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:14];
    [button.layer setMasksToBounds:YES];
    [button.layer setCornerRadius:13.0];
    [button.layer setBorderWidth:1.0];
    button.layer.borderColor = [UIColor clearColor].CGColor;
    [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)resetCurrentSelectedButton{
    if (_currentSelectedButton) {
        _currentSelectedButton.selected = NO;
        _currentSelectedButton.layer.borderColor = [UIColor clearColor].CGColor;
        _currentSelectedButton = nil;
    }
}

#pragma mark Setter
- (void)setCurrentSelectedButton:(UIButton *)currentSelectedButton{
    currentSelectedButton.selected = YES;
    currentSelectedButton.layer.borderColor = PLV_UIColorFromRGB(@"6DA7FF").CGColor;
    _currentSelectedButton = currentSelectedButton;
}

#pragma mark Getter
- (UILabel *)optionTitleLabel{
    if (!_optionTitleLabel) {
        _optionTitleLabel = [[UILabel alloc] init];
        _optionTitleLabel.text = @"选项标题";
        _optionTitleLabel.textColor = PLV_UIColorFromRGB(@"C2C2C2");
        _optionTitleLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    }
    return _optionTitleLabel;
}


#pragma mark - [ Event ]
#pragma mark Action
- (void)buttonAction:(UIButton *)button{
    [self resetCurrentSelectedButton];
    
    self.currentSelectedButton = button;
    
    NSInteger buttonIndex = [self.buttonsArray indexOfObject:button];
    self.currentModel.selectedIndex = buttonIndex;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCMediaMoreCell:buttonClickedWithModel:)]) {
        [self.delegate plvLCMediaMoreCell:self buttonClickedWithModel:self.currentModel];
    }
}

@end
