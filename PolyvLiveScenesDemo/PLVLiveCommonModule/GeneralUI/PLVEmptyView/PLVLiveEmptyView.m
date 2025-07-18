//
//  PLVLiveEmptyView.m
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2025/6/25.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVLiveEmptyView.h"
// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static const CGFloat kDefaultIconSize = 60.0;
static const CGFloat kDefaultIconTextSpacing = 16.0;
static const CGFloat kDefaultTextMaxWidth = 200.0;

@interface PLVLiveEmptyView ()

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation PLVLiveEmptyView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupData];
        [self addSubview:self.iconView];
        [self addSubview:self.textLabel];
    }
    return self;
}

#pragma mark - [ Public Method ]

- (void)setEmptyStateWithIcon:(UIImage *)icon text:(NSString *)text {
    self.iconView.image = icon;
    self.textLabel.text = text;
    [self updateLayout];
}

- (void)setSearchNoResultState {
    UIImage *searchIcon = [self searchNoResultIcon];
    NSString *text = @"未找到相关内容";
    [self setEmptyStateWithIcon:searchIcon text:text];
}

- (void)setSearchNoResultStateWithText:(NSString *)text {
    UIImage *searchIcon = [self searchNoResultIcon];
    [self setEmptyStateWithIcon:searchIcon text:text];
}

#pragma mark - [ Private Method ]

- (void)setupData {
    _iconSize = kDefaultIconSize;
    _iconTextSpacing = kDefaultIconTextSpacing;
    _textMaxWidth = kDefaultTextMaxWidth;
    _iconColor = PLV_UIColorFromRGB(@"#8A8A8A");
    _textColor = PLV_UIColorFromRGB(@"#8A8A8A");
    _textFont = [UIFont systemFontOfSize:16];
}

- (void)updateLayout {
    CGFloat centerX = self.bounds.size.width / 2.0;
    CGFloat centerY = self.bounds.size.height / 2.0;
    
    // 计算文本尺寸
    CGSize textSize = [self.textLabel sizeThatFits:CGSizeMake(self.textMaxWidth, MAXFLOAT)];
    
    // 计算总高度（图标 + 间距 + 文本）
    CGFloat totalHeight = self.iconSize + self.iconTextSpacing + textSize.height;
    
    // 图标位置 - 从中心向上偏移
    CGFloat iconY = centerY - totalHeight / 2.0;
    self.iconView.frame = CGRectMake(centerX - self.iconSize / 2.0, iconY, self.iconSize, self.iconSize);
    
    // 文本位置 - 在图标下方
    CGFloat textY = iconY + self.iconSize + self.iconTextSpacing;
    self.textLabel.frame = CGRectMake(centerX - textSize.width / 2.0, textY, textSize.width, textSize.height);
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateLayout];
}

- (void)setIconSize:(CGFloat)iconSize {
    _iconSize = iconSize;
    [self updateLayout];
}

- (void)setIconTextSpacing:(CGFloat)iconTextSpacing {
    _iconTextSpacing = iconTextSpacing;
    [self updateLayout];
}

- (void)setTextMaxWidth:(CGFloat)textMaxWidth {
    _textMaxWidth = textMaxWidth;
    [self updateLayout];
}

- (void)setIconColor:(UIColor *)iconColor {
    _iconColor = iconColor;
    self.iconView.tintColor = iconColor;
}

- (void)setTextColor:(UIColor *)textColor {
    _textColor = textColor;
    self.textLabel.textColor = textColor;
}

- (void)setTextFont:(UIFont *)textFont {
    _textFont = textFont;
    self.textLabel.font = textFont;
    [self updateLayout];
}

#pragma mark - [ Getter ]

- (UIImageView *)iconView {
    if (!_iconView) {
        _iconView = [[UIImageView alloc] init];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.tintColor = self.iconColor;
    }
    return _iconView;
}

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [[UILabel alloc] init];
        _textLabel.font = self.textFont;
        _textLabel.textColor = self.textColor;
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.numberOfLines = 0;
    }
    return _textLabel;
}

#pragma mark - [ Helper Methods ]

- (UIImage *)searchNoResultIcon {
    // 创建一个搜索无结果的图标
    CGSize size = CGSizeMake(self.iconSize, self.iconSize);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, self.iconColor.CGColor);
    CGContextSetLineWidth(context, 2.0);
    
    // 绘制圆形
    CGRect circleRect = CGRectMake(8, 8, size.width - 20, size.height - 20);
    CGContextStrokeEllipseInRect(context, circleRect);
    
    // 绘制手柄
    CGContextMoveToPoint(context, size.width - 12, size.height - 12);
    CGContextAddLineToPoint(context, size.width - 4, size.height - 4);
    CGContextStrokePath(context);
    
    // 绘制斜线表示无结果
    CGContextMoveToPoint(context, 12, size.height - 12);
    CGContextAddLineToPoint(context, size.width - 12, 12);
    CGContextStrokePath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end 
