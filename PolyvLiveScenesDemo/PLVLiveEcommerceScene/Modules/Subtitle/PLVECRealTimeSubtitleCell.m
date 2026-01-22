//
//  PLVECRealTimeSubtitleCell.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2026/1/20.
//  Copyright © 2026 PLV. All rights reserved.
//

#import "PLVECRealTimeSubtitleCell.h"
#import "PLVLiveSubtitleTranslation.h"
#import "PLVLiveSubtitleModel.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVECRealTimeSubtitleCell ()

/// 圆角背景容器
@property (nonatomic, strong) UIView *backgroundContainer;

/// 原文标签
@property (nonatomic, strong) UILabel *originLabel;

/// 翻译标签
@property (nonatomic, strong) UILabel *translateLabel;

/// 每段字幕之间的分割线（cell 底部）
@property (nonatomic, strong) UIView *segmentDividerView;

@end

@implementation PLVECRealTimeSubtitleCell

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
        self.segmentDividerView.hidden = YES;
        return;
    }
    
    self.backgroundContainer.hidden = NO;
    self.segmentDividerView.hidden = NO;
    
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
    
    // cell 底部分割线：用于每段字幕之间的间隔（原文/译文之间不需要分割线）
    self.segmentDividerView.frame = CGRectMake(horizontalMargin,
                                               CGRectGetHeight(self.contentView.bounds) - 1.0f,
                                               containerWidth,
                                               1.0f);
}

#pragma mark - UI Setup

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // 圆角背景容器
    self.backgroundContainer = [[UIView alloc] init];
    self.backgroundContainer.backgroundColor = [UIColor clearColor];
    self.backgroundContainer.layer.cornerRadius = 8.0f;
    self.backgroundContainer.layer.masksToBounds = YES;
    [self.contentView addSubview:self.backgroundContainer];
    
    // 原文标签
    self.originLabel = [[UILabel alloc] init];
    self.originLabel.font = [UIFont systemFontOfSize:14];
    self.originLabel.textColor = [UIColor whiteColor];
    self.originLabel.numberOfLines = 0;
    [self.backgroundContainer addSubview:self.originLabel];
    
    // 翻译标签
    self.translateLabel = [[UILabel alloc] init];
    self.translateLabel.font = [UIFont systemFontOfSize:14];
    self.translateLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.6]; // 半透明
    self.translateLabel.numberOfLines = 0;
    [self.backgroundContainer addSubview:self.translateLabel];
    
    // 每段字幕之间的分割线（cell 底部）
    self.segmentDividerView = [[UIView alloc] init];
    self.segmentDividerView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
    [self.contentView addSubview:self.segmentDividerView];
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
