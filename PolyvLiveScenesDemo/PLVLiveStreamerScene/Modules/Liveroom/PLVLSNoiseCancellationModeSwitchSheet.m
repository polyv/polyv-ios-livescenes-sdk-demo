//
//  PLVLSNoiseCancellationModeSwitchSheet.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/7/1.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVLSNoiseCancellationModeSwitchSheet.h"
#import "PLVLSBottomSheet.h"
#import "PLVMultiLanguageManager.h"
#import "PLVLSUtils.h"

@interface PLVLSNoiseCancellationModeSwitchButton : UIView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIImageView *selectedImageView;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) PLVBLinkMicNoiseCancellationLevel noiseCancellationLevel;

/// 点击触发
@property (nonatomic, copy) void (^buttonActionBlock) (BOOL selected);

- (instancetype)initWithNoiseCancellationLevel:(PLVBLinkMicNoiseCancellationLevel)noiseCancellationLevel;

@end

@implementation PLVLSNoiseCancellationModeSwitchButton

#pragma mark - [ Life Cycle ]

- (void)layoutSubviews {
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    CGFloat originX = 20.0;
    CGFloat originY = 20.0;
    
    CGFloat titleHeight = self.titleLabel.font.lineHeight;
    self.titleLabel.frame = CGRectMake(originX, originY, width - originX * 2, titleHeight);
    
    originY = CGRectGetMaxY(self.titleLabel.frame) + 8.0;
    self.detailLabel.frame = CGRectMake(originX, originY, width - originX * 2, height - originY);
    [self.detailLabel sizeToFit];
    
    self.selectedImageView.frame = CGRectMake(width - 28, height - 32, 28, 32);
}

#pragma mark - [ Public Method ]

- (instancetype)initWithNoiseCancellationLevel:(PLVBLinkMicNoiseCancellationLevel)noiseCancellationLevel{
    self = [super init];
    if (self) {
        _noiseCancellationLevel = noiseCancellationLevel;
        
        [self initUI];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
        [self addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    _selected = selected;
    self.layer.borderWidth = selected ? 1.0 : 0;
    self.selectedImageView.hidden = !selected;
}

#pragma mark - [ Private Method ]

- (void)initUI {
    self.backgroundColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:0.04];
    self.layer.borderColor = [UIColor colorWithRed:0x43/255.0 green:0x99/255.0 blue:0xff/255.0 alpha:1.0].CGColor;
    self.layer.borderWidth = self.selected ? 1.0 : 0;
    self.layer.cornerRadius = 8.0;
    
    [self addSubview:self.titleLabel];
    [self addSubview:self.detailLabel];
    [self addSubview:self.selectedImageView];
    
    if (self.noiseCancellationLevel == PLVBLinkMicNoiseCancellationLevelAggressive) {
        self.titleLabel.text = PLVLocalizedString(@"人声模式");
        self.detailLabel.text = PLVLocalizedString(@"适合语音通话为主的场景，比如在线会议，语音通话");
    } else if (self.noiseCancellationLevel == PLVBLinkMicNoiseCancellationLevelSoft) {
        self.titleLabel.text = PLVLocalizedString(@"音乐模式");
        self.detailLabel.text = PLVLocalizedString(@"适合需要高保真传输音乐的场景，比如K歌、音乐直播等");
    } else if (self.noiseCancellationLevel == PLVBLinkMicNoiseCancellationLevelDefault) {
        self.titleLabel.text = PLVLocalizedString(@"默认模式");
        self.detailLabel.text = PLVLocalizedString(@"默认的声音音质，如无特殊需求推荐选择");
    }
}

#pragma mark Getter & Setter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1.0];
        _titleLabel.font = [UIFont systemFontOfSize:16];
    }
    return _titleLabel;
}

- (UILabel *)detailLabel {
    if (!_detailLabel) {
        _detailLabel = [[UILabel alloc] init];
        _detailLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:0.6];
        _detailLabel.font = [UIFont systemFontOfSize:14];
        _detailLabel.numberOfLines = 0;
    }
    return _detailLabel;
}

- (UIImageView *)selectedImageView {
    if (!_selectedImageView) {
        _selectedImageView = [[UIImageView alloc] init];
        _selectedImageView.image = [PLVLSUtils imageForLiveroomResource:@"plvls_liveroom_selected_icon"];
        _selectedImageView.hidden = YES;
    }
    return _selectedImageView;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)tapGestureAction:(UITapGestureRecognizer *)tapGesture {
    if (self.buttonActionBlock) {
        self.buttonActionBlock(self.selected);
    }
}

@end

@interface PLVLSNoiseCancellationModeSwitchSheet()

@property (nonatomic, strong) UILabel *sheetTitleLabel; // 弹层顶部标题
@property (nonatomic, strong) UIScrollView *buttonScrollView; // 按钮滚动容器
@property (nonatomic, strong) UIView *buttonContainerView; // 按钮容器视图
@property (nonatomic, strong) PLVLSNoiseCancellationModeSwitchButton *speechModeButton; // 人声模式按钮
@property (nonatomic, strong) PLVLSNoiseCancellationModeSwitchButton *musicModeButton; // 音乐模式按钮
@property (nonatomic, strong) PLVLSNoiseCancellationModeSwitchButton *defaultModeButton; // 默认音质按钮

@end

@implementation PLVLSNoiseCancellationModeSwitchSheet

#pragma mark - [ Life Cycle ]

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL isLandscape = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat contentViewWidth = self.contentView.bounds.size.width;
    CGFloat contentViewHeight = self.contentView.bounds.size.height;
    
    // 标题布局
    CGFloat titleLabelOriginX = isPad ? 56 : 32;
    self.sheetTitleLabel.frame = CGRectMake(titleLabelOriginX, 32, contentViewWidth - titleLabelOriginX * 2, 18);
    
    // 滚动视图布局
    CGFloat scrollViewOriginX = isLandscape ? 32 : (isPad ? 56 : 16);
    CGFloat scrollViewOriginY = 80.0;
    CGFloat scrollViewWidth = contentViewWidth - scrollViewOriginX * 2;
    CGFloat scrollViewHeight = contentViewHeight - scrollViewOriginY - 32; // 预留底部间距
    
    self.buttonScrollView.frame = CGRectMake(scrollViewOriginX, scrollViewOriginY, scrollViewWidth, scrollViewHeight);
    
    // 按钮容器布局
    CGFloat buttonOriginX = 0;
    CGFloat buttonOriginY = 0;
    CGFloat buttonWidth = scrollViewWidth;
    CGFloat buttonHeight = 116.0;
    CGFloat buttonPadding = 12.0;
    
    // 获取所有按钮
    NSArray *buttons = [self allButtons];
    
    // 计算总高度
    CGFloat totalHeight = buttons.count * buttonHeight + (buttons.count - 1) * buttonPadding;
    
    self.buttonContainerView.frame = CGRectMake(0, 0, buttonWidth, totalHeight);
    
    // 布局每个按钮
    for (UIView *button in buttons) {
        button.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonWidth, buttonHeight);
        buttonOriginY += buttonHeight + buttonPadding;
    }
    
    // 设置滚动视图内容大小
    self.buttonScrollView.contentSize = CGSizeMake(buttonWidth, totalHeight);
}

#pragma mark - [ Override ]

- (instancetype)initWithSheetWidth:(CGFloat)sheetWidth {
    self = [super initWithSheetWidth:sheetWidth];
    if (self) {
        [self.contentView addSubview:self.sheetTitleLabel];
        [self.contentView addSubview:self.buttonScrollView];
        [self.buttonScrollView addSubview:self.buttonContainerView];
        
        // 添加按钮到容器中
        [self.buttonContainerView addSubview:self.speechModeButton];
        [self.buttonContainerView addSubview:self.musicModeButton];
        [self.buttonContainerView addSubview:self.defaultModeButton];
        
        // 配置滚动视图
        self.buttonScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
        self.buttonScrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    }
    return self;
}

#pragma mark - [ Public Method ]

- (void)showInView:(UIView *)parentView currentNoiseCancellationLevel:(PLVBLinkMicNoiseCancellationLevel)noiseCancellationLevel {
    if (noiseCancellationLevel == PLVBLinkMicNoiseCancellationLevelAggressive) {
        self.speechModeButton.selected = YES;
        self.musicModeButton.selected = NO;
        self.defaultModeButton.selected = NO;
    } else if (noiseCancellationLevel == PLVBLinkMicNoiseCancellationLevelSoft) {
        self.speechModeButton.selected = NO;
        self.musicModeButton.selected = YES;
        self.defaultModeButton.selected = NO;
    } else if (noiseCancellationLevel == PLVBLinkMicNoiseCancellationLevelDefault) {
        self.speechModeButton.selected = NO;
        self.musicModeButton.selected = NO;
        self.defaultModeButton.selected = YES;
    }
    
    [self showInView:parentView];
}

#pragma mark - [ Private Method ]

// 获取所有按钮的数组
- (NSArray<PLVLSNoiseCancellationModeSwitchButton *> *)allButtons {
    NSMutableArray *buttons = [NSMutableArray array];
    
    // 添加现有按钮
    if (self.defaultModeButton) [buttons addObject:self.defaultModeButton];
    if (self.speechModeButton) [buttons addObject:self.speechModeButton];
    if (self.musicModeButton) [buttons addObject:self.musicModeButton];
    
    // 可以在这里添加新按钮
    
    return [buttons copy];
}

// 动态添加新按钮的方法
- (void)addNewButton:(PLVLSNoiseCancellationModeSwitchButton *)newButton {
    [self.buttonContainerView addSubview:newButton];
    
    // 重新布局
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark Getter

- (UILabel *)sheetTitleLabel {
    if (!_sheetTitleLabel) {
        _sheetTitleLabel = [[UILabel alloc] init];
        _sheetTitleLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
        _sheetTitleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:18];
        _sheetTitleLabel.text = PLVLocalizedString(@"声音音质");
    }
    return _sheetTitleLabel;
}

- (UIScrollView *)buttonScrollView {
    if (!_buttonScrollView) {
        _buttonScrollView = [[UIScrollView alloc] init];
        _buttonScrollView.showsVerticalScrollIndicator = YES;
        _buttonScrollView.showsHorizontalScrollIndicator = NO;
        _buttonScrollView.bounces = YES;
        _buttonScrollView.alwaysBounceVertical = NO;
        _buttonScrollView.backgroundColor = [UIColor clearColor];
    }
    return _buttonScrollView;
}

- (UIView *)buttonContainerView {
    if (!_buttonContainerView) {
        _buttonContainerView = [[UIView alloc] init];
        _buttonContainerView.backgroundColor = [UIColor clearColor];
    }
    return _buttonContainerView;
}

- (PLVLSNoiseCancellationModeSwitchButton *)speechModeButton {
    if (!_speechModeButton) {
        _speechModeButton = [[PLVLSNoiseCancellationModeSwitchButton alloc] initWithNoiseCancellationLevel:PLVBLinkMicNoiseCancellationLevelAggressive];
        __weak typeof(self) weakSelf = self;
        [_speechModeButton setButtonActionBlock:^(BOOL selected) {
            [weakSelf selectNoiseCancellationLevel:PLVBLinkMicNoiseCancellationLevelAggressive selected:selected];
        }];
    }
    return _speechModeButton;
}

- (PLVLSNoiseCancellationModeSwitchButton *)musicModeButton {
    if (!_musicModeButton) {
        _musicModeButton = [[PLVLSNoiseCancellationModeSwitchButton alloc] initWithNoiseCancellationLevel:PLVBLinkMicNoiseCancellationLevelSoft];
        __weak typeof(self) weakSelf = self;
        [_musicModeButton setButtonActionBlock:^(BOOL selected) {
            [weakSelf selectNoiseCancellationLevel:PLVBLinkMicNoiseCancellationLevelSoft selected:selected];
        }];
    }
    return _musicModeButton;
}

- (PLVLSNoiseCancellationModeSwitchButton *)defaultModeButton {
    if (!_defaultModeButton) {
        _defaultModeButton = [[PLVLSNoiseCancellationModeSwitchButton alloc] initWithNoiseCancellationLevel:PLVBLinkMicNoiseCancellationLevelDefault];
        __weak typeof(self) weakSelf = self;
        [_defaultModeButton setButtonActionBlock:^(BOOL selected) {
            [weakSelf selectNoiseCancellationLevel:PLVBLinkMicNoiseCancellationLevelDefault selected:selected];
        }];
    }
    return _defaultModeButton;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)selectNoiseCancellationLevel:(PLVBLinkMicNoiseCancellationLevel)selectedLevel selected:(BOOL)selected {
    [self dismiss];
    
    if (!selected) {
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(noiseCancellationModeSwitchSheet:wannaChangeNoiseCancellationLevel:)]) {
            [self.delegate noiseCancellationModeSwitchSheet:self wannaChangeNoiseCancellationLevel:selectedLevel];
        }
    }
}

@end 
