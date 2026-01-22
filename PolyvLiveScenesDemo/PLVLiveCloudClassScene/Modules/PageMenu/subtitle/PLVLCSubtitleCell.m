//
//  PLVLCSubtitleCell.m
//  PolyvLiveScenesDemo
//
//  Created on 2024.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVLCSubtitleCell.h"
#import "PLVLiveSubtitleTranslation.h"
#import "PLVLiveSubtitleModel.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCSubtitleCell ()

/// 圆角背景容器
@property (nonatomic, strong) UIView *backgroundContainer;

/// 原文标签
@property (nonatomic, strong) UILabel *originLabel;

/// 分割线
@property (nonatomic, strong) UIView *dividerView;

/// 翻译标签
@property (nonatomic, strong) UILabel *translateLabel;

@end

@implementation PLVLCSubtitleCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 如果所有内容都隐藏，隐藏背景容器
    if (self.originLabel.hidden && self.translateLabel.hidden) {
        self.backgroundContainer.hidden = YES;
        return;
    }
    
    self.backgroundContainer.hidden = NO;
    
    CGFloat horizontalMargin = 12.0f;  // 左右边距
    CGFloat verticalMargin = 6.0f;     // 上下边距（cell间距的一半）
    CGFloat innerPadding = 10.0f;      // 背景容器内部边距
    
    CGFloat containerWidth = self.contentView.bounds.size.width - horizontalMargin * 2;
    CGFloat contentWidth = containerWidth - innerPadding * 2;
    
    // 计算背景容器的高度
    CGFloat containerHeight = 0;
    CGFloat yOffset = innerPadding;
    
    // 原文标签
    if (!self.originLabel.hidden) {
        CGSize originSize = [self.originLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
        self.originLabel.frame = CGRectMake(innerPadding, yOffset, contentWidth, originSize.height);
        yOffset += originSize.height;
    }
    
    // 分割线
    if (!self.dividerView.hidden) {
        yOffset += 6.0f;
        self.dividerView.frame = CGRectMake(innerPadding, yOffset, contentWidth, 1.0f);
        yOffset += 1.0f + 6.0f;
    }
    
    // 翻译标签
    if (!self.translateLabel.hidden) {
        CGSize translateSize = [self.translateLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
        self.translateLabel.frame = CGRectMake(innerPadding, yOffset, contentWidth, translateSize.height);
        yOffset += translateSize.height;
    }
    
    containerHeight = yOffset + innerPadding;
    
    // 设置背景容器的frame
    self.backgroundContainer.frame = CGRectMake(horizontalMargin, 
                                               verticalMargin, 
                                               containerWidth, 
                                               containerHeight);
}

#pragma mark - UI Setup

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // 圆角背景容器
    self.backgroundContainer = [[UIView alloc] init];
    self.backgroundContainer.backgroundColor = [UIColor colorWithRed:0x2B/255.0 
                                                               green:0x2C/255.0 
                                                                blue:0x35/255.0 
                                                               alpha:1.0]; // 深灰色背景
    self.backgroundContainer.layer.cornerRadius = 8.0f;
    self.backgroundContainer.layer.masksToBounds = YES;
    [self.contentView addSubview:self.backgroundContainer];
    
    // 原文标签
    self.originLabel = [[UILabel alloc] init];
    self.originLabel.font = [UIFont systemFontOfSize:14];
    self.originLabel.textColor = [UIColor whiteColor];
    self.originLabel.numberOfLines = 0;
    [self.backgroundContainer addSubview:self.originLabel];
    
    // 分割线
    self.dividerView = [[UIView alloc] init];
    self.dividerView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
    [self.backgroundContainer addSubview:self.dividerView];
    
    // 翻译标签
    self.translateLabel = [[UILabel alloc] init];
    self.translateLabel.font = [UIFont systemFontOfSize:14];
    self.translateLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.6]; // 半透明
    self.translateLabel.numberOfLines = 0;
    [self.backgroundContainer addSubview:self.translateLabel];
}

#pragma mark - Public Method

- (void)configureWithSubtitle:(PLVLiveSubtitleTranslation *)subtitleTranslation
                   showOrigin:(BOOL)showOrigin
               showTranslation:(BOOL)showTranslation {
    if (!subtitleTranslation) {
        return;
    }
    
    BOOL hasTranslation = subtitleTranslation.translation != nil && 
                         [PLVFdUtil checkStringUseable:subtitleTranslation.translation.text];
    
    // 原文标签显示逻辑
    if (showOrigin && subtitleTranslation.origin) {
        self.originLabel.hidden = NO;
        self.originLabel.text = subtitleTranslation.origin.text;
    } else {
        self.originLabel.hidden = YES;
    }
    
    // 翻译标签显示逻辑
    if (showTranslation && hasTranslation) {
        self.translateLabel.hidden = NO;
        self.translateLabel.text = subtitleTranslation.translation.text;
        
        // 双语模式下翻译半透明，单独翻译时不透明
        if (showOrigin) {
            self.translateLabel.alpha = 0.6f;
        } else {
            self.translateLabel.alpha = 1.0f;
            self.translateLabel.textColor = [UIColor whiteColor]; // 单独显示时用白色
        }
    } else {
        self.translateLabel.hidden = YES;
    }
    
    // 分割线显示逻辑（双语模式且都有内容时显示）
    BOOL showDivider = !self.originLabel.hidden && !self.translateLabel.hidden;
    self.dividerView.hidden = !showDivider;
    
    [self setNeedsLayout];
}

+ (CGFloat)cellHeightWithSubtitle:(PLVLiveSubtitleTranslation *)subtitleTranslation
                       showOrigin:(BOOL)showOrigin
                  showTranslation:(BOOL)showTranslation
                            width:(CGFloat)width {
    if (!subtitleTranslation) {
        return 0;
    }
    
    BOOL hasTranslation = subtitleTranslation.translation != nil && 
                         [PLVFdUtil checkStringUseable:subtitleTranslation.translation.text];
    
    // 判断是否有实际显示的内容
    BOOL hasOriginContent = showOrigin && subtitleTranslation.origin;
    BOOL hasTranslationContent = showTranslation && hasTranslation;
    
    // 如果没有任何内容显示，返回 0 高度
    if (!hasOriginContent && !hasTranslationContent) {
        return 0;
    }
    
    CGFloat horizontalMargin = 12.0f;  // 左右边距
    CGFloat verticalMargin = 6.0f;     // 上下边距（cell间距的一半）
    CGFloat innerPadding = 10.0f;      // 背景容器内部边距
    
    CGFloat containerWidth = width - horizontalMargin * 2;
    CGFloat contentWidth = containerWidth - innerPadding * 2;
    CGFloat totalHeight = verticalMargin; // 顶部边距
    
    CGFloat contentHeight = innerPadding; // 容器内部顶部padding
    
    UIFont *font = [UIFont systemFontOfSize:14];
    
    // 计算原文高度
    if (hasOriginContent) {
        NSString *originText = subtitleTranslation.origin.text;
        CGSize originSize = [originText boundingRectWithSize:CGSizeMake(contentWidth, CGFLOAT_MAX)
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:@{NSFontAttributeName: font}
                                                     context:nil].size;
        contentHeight += originSize.height;
    }
    
    // 计算分割线高度
    if (hasOriginContent && hasTranslationContent) {
        contentHeight += 6.0f + 1.0f + 6.0f; // 上间距 + 线高 + 下间距
    }
    
    // 计算翻译高度
    if (hasTranslationContent) {
        NSString *translateText = subtitleTranslation.translation.text;
        CGSize translateSize = [translateText boundingRectWithSize:CGSizeMake(contentWidth, CGFLOAT_MAX)
                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                        attributes:@{NSFontAttributeName: font}
                                                           context:nil].size;
        contentHeight += translateSize.height;
    }
    
    contentHeight += innerPadding; // 容器内部底部padding
    totalHeight += contentHeight + verticalMargin; // 内容高度 + 底部边距
    
    return totalHeight;
}

@end
