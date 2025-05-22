//
//  PLVLiveScenesSubtitleView.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/4/24.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVLiveScenesSubtitleView.h"
#import "PLVLiveScenesSubtitleManager.h"
#import "PLVLiveScenesSubtitleViewModel.h"
#import "PLVLiveScenesSubtitleParser.h"

static const CGFloat kHorizontalPadding = 12.0f;  // 水平内边距
static const CGFloat kVerticalPadding = 4.0f;     // 垂直内边距
static const CGFloat kLabelSpacing = 4.0f;        // 标签间距
static const CGFloat kBottomPadding= 24.0f;       // 底部安全边距

@interface PLVLiveScenesSubtitleView ()

@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel2;
@property (nonatomic, strong) UILabel *subtitleTopLabel;
@property (nonatomic, strong) UILabel *subtitleTopLabel2;
@property (nonatomic, strong) UIView *subtitleBackgroundView;

@property (nonatomic, strong) PLVLiveScenesSubtitleManager *subtitleManager;

// 字幕样式1
@property (nonatomic, assign) CGFloat subtitleFontSize1;
@property (nonatomic, strong) UIColor *subtitleTextColor1;

// 字幕样式2
@property (nonatomic, assign) CGFloat subtitleFontSize2;
@property (nonatomic, strong) UIColor *subtitleTextColor2;

@property (nonatomic, strong) UIColor *subtitleBackgroundColor;

// 字幕内容
@property (nonatomic, copy) NSString *subtitleContent1;
@property (nonatomic, copy) NSString *subtitleContent2;

// 是否使用双字幕模式
@property (nonatomic, assign) BOOL dualSubtitleMode;

@end

@implementation PLVLiveScenesSubtitleView

#pragma mark - Life Cycle

- (instancetype)initBackgroundColor:(UIColor *)backgroundColor
                        fontSize1:(CGFloat)fontSize1
                       textColor1:(UIColor *)textColor1 
                        fontSize2:(CGFloat)fontSize2
                       textColor2:(UIColor *)textColor2 {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _subtitleFontSize1 = fontSize1;
        _subtitleTextColor1 = textColor1;
        _subtitleFontSize2 = fontSize2;
        _subtitleTextColor2 = textColor2;
        _subtitleBackgroundColor = backgroundColor;
        _dualSubtitleMode = YES;
        self.userInteractionEnabled = NO;
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateSubtitleLayout];
}

#pragma mark - Setup

- (void)setupUI {
    // 设置视图背景色
    [self addSubview:self.subtitleBackgroundView];
    [self addSubview:self.subtitleLabel];
    [self addSubview:self.subtitleLabel2];
}

#pragma mark - Private Methods

- (UIView *)subtitleBackgroundView {
    if (!_subtitleBackgroundView) {
        _subtitleBackgroundView = [[UIView alloc] init];
        _subtitleBackgroundView.backgroundColor = self.subtitleBackgroundColor;
        _subtitleBackgroundView.layer.cornerRadius = 4.0f;
        _subtitleBackgroundView.layer.masksToBounds = YES;
    }
    return _subtitleBackgroundView;
}

- (UILabel *)subtitleLabel {
    if (!_subtitleLabel) {
        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.textAlignment = NSTextAlignmentCenter;
        _subtitleLabel.numberOfLines = 0;
        _subtitleLabel.backgroundColor = [UIColor clearColor];
    }
    return _subtitleLabel;
}

- (UILabel *)subtitleLabel2 {
    if (!_subtitleLabel2) {
        _subtitleLabel2 = [[UILabel alloc] init];
        _subtitleLabel2.textAlignment = NSTextAlignmentCenter;
        _subtitleLabel2.numberOfLines = 0;
        _subtitleLabel2.backgroundColor = [UIColor clearColor];
    }
    return _subtitleLabel2;
}

- (UILabel *)subtitleTopLabel {
    if (!_subtitleTopLabel) {
        _subtitleTopLabel = [[UILabel alloc] init];
        _subtitleTopLabel.textAlignment = NSTextAlignmentCenter;
        _subtitleTopLabel.numberOfLines = 0;
        _subtitleTopLabel.backgroundColor = [UIColor clearColor];
    }
    return _subtitleTopLabel;
}

- (UILabel *)subtitleTopLabel2 {
    if (!_subtitleTopLabel2) {
        _subtitleTopLabel2 = [[UILabel alloc] init];
        _subtitleTopLabel2.textAlignment = NSTextAlignmentCenter;
        _subtitleTopLabel2.numberOfLines = 0;
        _subtitleTopLabel2.backgroundColor = [UIColor clearColor];;
    }
    return _subtitleTopLabel2;
}

- (CGSize)calculateLabelSize:(UILabel *)label withWidth:(CGFloat)width {
    CGSize constraintSize = CGSizeMake(width, CGFLOAT_MAX);
    NSAttributedString *attributedText = label.attributedText ?: nil;
    
    CGRect textRect = [attributedText boundingRectWithSize:constraintSize
                                                   options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                                   context:nil];
    
    return CGSizeMake(ceil(textRect.size.width), ceil(textRect.size.height));
}

- (void)updateSubtitleLayout {
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    CGFloat contentWidth = viewWidth - (kHorizontalPadding * 2);
    CGFloat currentY = viewHeight - kVerticalPadding - kBottomPadding;
    CGFloat totalHeight = 0;
    CGFloat totalWidth = 0;
    
    // 计算主标签大小和位置
    if (self.subtitleLabel.attributedText && self.subtitleLabel.attributedText.length > 0) {
        CGSize mainLabelSize = [self calculateLabelSize:self.subtitleLabel withWidth:contentWidth];
        currentY -= mainLabelSize.height;
        self.subtitleLabel.frame = CGRectMake((viewWidth - mainLabelSize.width) * 0.5, 
                                             currentY, 
                                             mainLabelSize.width, 
                                             mainLabelSize.height);
        totalWidth = mainLabelSize.width;
        
        if (self.subtitleLabel2.attributedText && self.subtitleLabel2.attributedText.length > 0) {
            currentY -= kLabelSpacing;
        }
    }
    
    // 计算副标签大小和位置
    if (self.subtitleLabel2.attributedText && self.subtitleLabel2.attributedText.length > 0) {
        CGSize subLabelSize = [self calculateLabelSize:self.subtitleLabel2 withWidth:contentWidth];
        currentY -= subLabelSize.height;
        self.subtitleLabel2.frame = CGRectMake((viewWidth - subLabelSize.width) * 0.5, 
                                              currentY, 
                                              subLabelSize.width, 
                                              subLabelSize.height);
        totalWidth = MAX(totalWidth, subLabelSize.width);
    }
    
    // 更新背景视图frame
    if ((self.subtitleLabel.attributedText && self.subtitleLabel.attributedText.length > 0) ||
        (self.subtitleLabel2.attributedText && self.subtitleLabel2.attributedText.length > 0)) {
        currentY -= kVerticalPadding;
        totalHeight = viewHeight - currentY - kBottomPadding;
        totalWidth += kHorizontalPadding * 2;
        self.subtitleBackgroundView.frame = CGRectMake((viewWidth - totalWidth) * 0.5, 
                                                     currentY, 
                                                     totalWidth, 
                                                     totalHeight);
        self.subtitleBackgroundView.hidden = NO;
    } else {
        self.subtitleBackgroundView.hidden = YES;
    }
}

#pragma mark - Public Methods

- (void)update {
    // 更新字幕视图
    [self setupSubtitleManager];
}

- (void)showSubtilesWithPlaytime:(NSTimeInterval)playtime {
    if (self.subtitleManager) {
        [self.subtitleManager showSubtitleWithTime:playtime];
        [self updateSubtitleLayout];
    }
}

- (void)setSubtitleContent:(NSString *)subtitleContent {
    _subtitleContent1 = subtitleContent;
    _subtitleContent2 = nil;

    // 设置字幕内容后更新字幕管理器
    [self setupSubtitleManager];
}

- (void)setSubtitleContent1:(NSString *)subtitleContent1 subtitleContent2:(NSString *)subtitleContent2 {
    _subtitleContent1 = subtitleContent1;
    _subtitleContent2 = subtitleContent2;
    
    // 设置字幕内容后更新字幕管理器
    [self setupSubtitleManager];
}

#pragma mark - Private Methods

- (void)setupSubtitleManager {
    // 检查字幕内容
    if ((!self.subtitleContent1 || self.subtitleContent1.length == 0) &&
        (!self.subtitleContent2 || self.subtitleContent2.length == 0)) {
        self.hidden = YES;
        return;
    }
    self.hidden = NO;

    // 创建字幕样式1
    PLVLiveScenesSubtitleItemStyle *style1 = [PLVLiveScenesSubtitleItemStyle styleWithTextColor:self.subtitleTextColor1
                                                                                           bold:NO
                                                                                         italic:NO
                                                                                backgroundColor:[UIColor clearColor]
                                                                                       fontSize:self.subtitleFontSize1];

    // 创建字幕样式2
    PLVLiveScenesSubtitleItemStyle *style2 = [PLVLiveScenesSubtitleItemStyle styleWithTextColor:self.subtitleTextColor2
                                                                                           bold:NO
                                                                                         italic:NO
                                                                                backgroundColor:[UIColor clearColor]
                                                                                       fontSize:self.subtitleFontSize2];

    // 创建字幕管理器
    NSError *error1 = nil;
    NSError *error2 = nil;

    self.subtitleManager = [PLVLiveScenesSubtitleManager managerWithSubtitle:self.subtitleContent1
                                                                       style:style1
                                                                       error:&error1
                                                                   subtitle2:self.subtitleContent2
                                                                      style2:style2
                                                                      error2:&error2
                                                                       label:self.subtitleLabel
                                                                    topLabel:self.subtitleTopLabel
                                                                      label2:self.subtitleLabel2
                                                                   topLabel2:self.subtitleTopLabel2];

    if (error1) {
        NSLog(@"第一字幕解析错误: %@", error1.localizedDescription);
    }

    if (error2) {
        NSLog(@"第二字幕解析错误: %@", error2.localizedDescription);
    }
}

@end
