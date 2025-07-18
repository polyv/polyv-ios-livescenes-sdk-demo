//
//  PLVLiveSearchBar.m
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2025/6/25.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVLiveSearchBar.h"
// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static const CGFloat kSearchBarHeight = 36.0;
static const CGFloat kSearchIconSize = 16.0;
static const CGFloat kClearButtonSize = 20.0;
static const CGFloat kHorizontalPadding = 12.0;
static const CGFloat kIconPadding = 8.0;
static const NSTimeInterval kDefaultDebounceDelay = 1.0;

@interface PLVLiveSearchBar () <UITextFieldDelegate>

/// UI组件
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIImageView *searchIconView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *clearButton;

/// 数据
@property (nonatomic, copy) NSString *searchText;
@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, assign) NSTimeInterval debounceDelay;

/// 防抖定时器
@property (nonatomic, strong) NSTimer *debounceTimer;

@end

@implementation PLVLiveSearchBar

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupData];
        [self addSubview:self.backgroundView];
        [self.backgroundView addSubview:self.searchIconView];
        [self.backgroundView addSubview:self.textField];
        [self.backgroundView addSubview:self.clearButton];
    }
    return self;
}

- (void)dealloc {
    [self invalidateDebounceTimer];
}

#pragma mark - [ Public Method ]

- (void)setSearchText:(NSString *)searchText {
    _searchText = [searchText copy];
    self.textField.text = searchText;
    [self updateClearButtonVisibility];
}

- (void)clearSearchText {
    [self setSearchText:@""];
    [self invalidateDebounceTimer];
    if ([self.delegate respondsToSelector:@selector(searchBar:didChangeSearchText:)]) {
        [self.delegate searchBar:self didChangeSearchText:@""];
    }
}

- (void)beginEditing {
    [self.textField becomeFirstResponder];
}

- (void)endEditing {
    [self.textField resignFirstResponder];
}

- (void)setDebounceDelay:(NSTimeInterval)delay {
    _debounceDelay = delay;
}

#pragma mark - [ Private Method ]

- (void)setupData {
    _debounceDelay = kDefaultDebounceDelay;
    _showsClearButton = YES;
    _placeholder = @"搜索";
    _backgroundColor = PLV_UIColorFromRGB(@"#2A2A2A");
    _textColor = PLV_UIColorFromRGB(@"#F0F1F5");
    _placeholderColor = PLV_UIColorFromRGB(@"#8A8A8A");
    _iconColor = PLV_UIColorFromRGB(@"#8A8A8A");
    _cornerRadius = kSearchBarHeight / 2.0;
}

- (void)updateLayout {
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    // 背景视图
    self.backgroundView.frame = CGRectMake(0, 0, width, height);
    
    // 搜索图标
    CGFloat iconX = kHorizontalPadding;
    CGFloat iconY = (height - kSearchIconSize) / 2.0;
    self.searchIconView.frame = CGRectMake(iconX, iconY, kSearchIconSize, kSearchIconSize);
    
    // 清除按钮
    CGFloat clearButtonX = width - kHorizontalPadding - kClearButtonSize;
    CGFloat clearButtonY = (height - kClearButtonSize) / 2.0;
    self.clearButton.frame = CGRectMake(clearButtonX, clearButtonY, kClearButtonSize, kClearButtonSize);
    
    // 文本输入框
    CGFloat textFieldX = iconX + kSearchIconSize + kIconPadding;
    CGFloat textFieldWidth = clearButtonX - textFieldX - kIconPadding;
    self.textField.frame = CGRectMake(textFieldX, 0, textFieldWidth, height);
}

- (void)updateClearButtonVisibility {
    BOOL shouldShow = self.showsClearButton && [PLVFdUtil checkStringUseable:self.searchText];
    self.clearButton.hidden = !shouldShow;
}

- (void)invalidateDebounceTimer {
    [self.debounceTimer invalidate];
    self.debounceTimer = nil;
}

- (void)scheduleDebounceTimer {
    [self invalidateDebounceTimer];
    
    if ([PLVFdUtil checkStringUseable:self.searchText]) {
        self.debounceTimer = [NSTimer scheduledTimerWithTimeInterval:self.debounceDelay
                                                              target:self
                                                            selector:@selector(debounceTimerFired)
                                                            userInfo:nil
                                                             repeats:NO];
    }
}

- (void)debounceTimerFired {
    if ([self.delegate respondsToSelector:@selector(searchBar:didChangeSearchText:)]) {
        [self.delegate searchBar:self didChangeSearchText:self.searchText];
    }
}

#pragma mark - [ Actions ]

- (void)clearButtonTapped:(UIButton *)sender {
    [self clearSearchText];
    
    if ([self.delegate respondsToSelector:@selector(searchBarDidTapClearButton:)]) {
        [self.delegate searchBarDidTapClearButton:self];
    }
}

#pragma mark - [ UITextFieldDelegate ]

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.isEditing = YES;
    
    if ([self.delegate respondsToSelector:@selector(searchBarDidBeginEditing:)]) {
        [self.delegate searchBarDidBeginEditing:self];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.isEditing = NO;
    
    if ([self.delegate respondsToSelector:@selector(searchBarDidEndEditing:)]) {
        [self.delegate searchBarDidEndEditing:self];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    _searchText = [newText copy];
    
    [self updateClearButtonVisibility];
    
    // 当搜索文本为空时，立即触发回调，不依赖防抖定时器
    if (![PLVFdUtil checkStringUseable:newText]) {
        [self invalidateDebounceTimer];
        if ([self.delegate respondsToSelector:@selector(searchBar:didChangeSearchText:)]) {
            [self.delegate searchBar:self didChangeSearchText:newText];
        }
    } else {
        [self scheduleDebounceTimer];
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [self clearSearchText];
    return NO;
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateLayout];
}

- (void)setPlaceholder:(NSString *)placeholder {
    _placeholder = [placeholder copy];
    self.textField.placeholder = placeholder;
    
    // 设置占位符颜色
    if (placeholder) {
        NSAttributedString *attributedPlaceholder = [[NSAttributedString alloc] 
            initWithString:placeholder 
            attributes:@{NSForegroundColorAttributeName: self.placeholderColor}];
        self.textField.attributedPlaceholder = attributedPlaceholder;
    }
}

- (void)setShowsClearButton:(BOOL)showsClearButton {
    _showsClearButton = showsClearButton;
    [self updateClearButtonVisibility];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    self.backgroundView.backgroundColor = backgroundColor;
}

- (void)setTextColor:(UIColor *)textColor {
    _textColor = textColor;
    self.textField.textColor = textColor;
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    _placeholderColor = placeholderColor;
    
    // 重新设置占位符颜色
    if (self.placeholder) {
        NSAttributedString *attributedPlaceholder = [[NSAttributedString alloc] 
            initWithString:self.placeholder 
            attributes:@{NSForegroundColorAttributeName: placeholderColor}];
        self.textField.attributedPlaceholder = attributedPlaceholder;
    }
}

- (void)setIconColor:(UIColor *)iconColor {
    _iconColor = iconColor;
    self.searchIconView.tintColor = iconColor;
    self.clearButton.tintColor = iconColor;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    self.backgroundView.layer.cornerRadius = cornerRadius;
}

#pragma mark - [ Getter ]

- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
        _backgroundView.backgroundColor = self.backgroundColor;
        _backgroundView.layer.cornerRadius = self.cornerRadius;
        _backgroundView.layer.masksToBounds = YES;
    }
    return _backgroundView;
}

- (UIImageView *)searchIconView {
    if (!_searchIconView) {
        _searchIconView = [[UIImageView alloc] init];
        _searchIconView.image = [self searchIconImage];
        _searchIconView.contentMode = UIViewContentModeScaleAspectFit;
        _searchIconView.tintColor = self.iconColor;
    }
    return _searchIconView;
}

- (UITextField *)textField {
    if (!_textField) {
        _textField = [[UITextField alloc] init];
        _textField.delegate = self;
        _textField.backgroundColor = [UIColor clearColor];
        _textField.textColor = self.textColor;
        _textField.font = [UIFont systemFontOfSize:16];
        _textField.placeholder = self.placeholder;
        _textField.returnKeyType = UIReturnKeySearch;
        _textField.clearButtonMode = UITextFieldViewModeNever;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _textField.spellCheckingType = UITextSpellCheckingTypeNo;
        
        // 设置占位符颜色
        if (self.placeholder) {
            NSAttributedString *attributedPlaceholder = [[NSAttributedString alloc] 
                initWithString:self.placeholder 
                attributes:@{NSForegroundColorAttributeName: self.placeholderColor}];
            _textField.attributedPlaceholder = attributedPlaceholder;
        }
    }
    return _textField;
}

- (UIButton *)clearButton {
    if (!_clearButton) {
        _clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_clearButton setImage:[self clearIconImage] forState:UIControlStateNormal];
        _clearButton.tintColor = self.iconColor;
        [_clearButton addTarget:self action:@selector(clearButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        _clearButton.hidden = YES;
    }
    return _clearButton;
}

#pragma mark - [ Helper Methods ]

- (UIImage *)searchIconImage {
    // 创建一个搜索图标
    CGSize size = CGSizeMake(kSearchIconSize, kSearchIconSize);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, self.iconColor.CGColor);
    CGContextSetLineWidth(context, 1.5);
    
    // 绘制圆形
    CGRect circleRect = CGRectMake(2, 2, size.width - 6, size.height - 6);
    CGContextStrokeEllipseInRect(context, circleRect);
    
    // 绘制手柄
    CGContextMoveToPoint(context, size.width - 4, size.height - 4);
    CGContextAddLineToPoint(context, size.width - 1, size.height - 1);
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *)clearIconImage {
    // 创建一个清除图标
    CGSize size = CGSizeMake(kClearButtonSize, kClearButtonSize);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, self.iconColor.CGColor);
    CGContextSetLineWidth(context, 1.5);
    
    // 绘制X
    CGContextMoveToPoint(context, 4, 4);
    CGContextAddLineToPoint(context, size.width - 4, size.height - 4);
    CGContextMoveToPoint(context, size.width - 4, 4);
    CGContextAddLineToPoint(context, 4, size.height - 4);
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end 
