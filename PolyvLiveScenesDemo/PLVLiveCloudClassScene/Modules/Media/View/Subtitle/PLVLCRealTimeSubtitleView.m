//
//  PLVLCRealTimeSubtitleView.m
//  PolyvLiveScenesDemo
//

#import "PLVLCRealTimeSubtitleView.h"

// 布局参数（和回放字幕视图保持一致）
static const CGFloat kHorizontalPadding = 12.0f;  // 水平内边距（标签到背景边缘）
static const CGFloat kVerticalPadding = 4.0f;     // 垂直内边距
static const CGFloat kSideMargin = 20.0f;         // 左右边距（背景到屏幕边缘）
static const CGFloat kBottomPadding = 24.0f;      // 底部安全边距
static const CGFloat kCornerRadius = 4.0f;        // 圆角

@interface PLVLCRealTimeSubtitleView ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *subtitleLabel;      // 字幕标签（最多显示2行）

@end

@implementation PLVLCRealTimeSubtitleView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 创建容器视图（背景）
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    self.containerView.layer.cornerRadius = kCornerRadius;
    self.containerView.layer.masksToBounds = YES;
    [self addSubview:self.containerView];
    
    // 创建字幕标签（只显示一条，最多2行）
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.textColor = [UIColor whiteColor];
    self.subtitleLabel.font = [UIFont systemFontOfSize:16];
    self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
    self.subtitleLabel.numberOfLines = 2; // 最多2行，超出不显示
    [self addSubview:self.subtitleLabel];
    
    self.hidden = YES;
    self.userInteractionEnabled = NO; // 不拦截触摸事件
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    
    // 可用宽度 = 视图宽度 - 左右边距 - 背景内边距
    CGFloat maxWidth = viewWidth - (kSideMargin * 2) - (kHorizontalPadding * 2);
    
    // 计算字幕标签大小（最多2行）
    if (self.subtitleLabel.text.length > 0) {
        CGSize labelSize = [self.subtitleLabel sizeThatFits:CGSizeMake(maxWidth, CGFLOAT_MAX)];
        
        // 设置背景视图frame
        CGFloat containerWidth = labelSize.width + kHorizontalPadding * 2;
        CGFloat containerHeight = labelSize.height + kVerticalPadding * 2;
        CGFloat containerY = viewHeight - kBottomPadding - containerHeight;
        CGFloat containerX = (viewWidth - containerWidth) * 0.5;
        
        self.containerView.frame = CGRectMake(containerX, 
                                             containerY, 
                                             containerWidth, 
                                             containerHeight);
        
        // 设置标签frame（相对于背景视图居中）
        self.subtitleLabel.frame = CGRectMake(containerX + kHorizontalPadding, 
                                             containerY + kVerticalPadding, 
                                             labelSize.width, 
                                             labelSize.height);
        
        self.containerView.hidden = NO;
    } else {
        self.containerView.hidden = YES;
    }
}

#pragma mark - Public Methods

- (void)updateRealTimeSubtitle:(nullable PLVLiveSubtitleModel *)subtitle {
    if (!subtitle || subtitle.text.length == 0) {
        self.hidden = YES;
        return;
    }
    
    self.hidden = NO;
    
    // 截取最后2行显示（如果文本超过2行）
    NSString *displayText = [self keepLastTwoLines:subtitle.text];
    self.subtitleLabel.text = displayText;
    
    [self setNeedsLayout];
}

#pragma mark - Private Methods

/// 保留文本的最后2行（如果超过2行）
- (NSString *)keepLastTwoLines:(NSString *)text {
    if (text.length == 0) {
        return text;
    }
    
    // 计算可用宽度
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    if (viewWidth == 0) {
        viewWidth = [UIScreen mainScreen].bounds.size.width;
    }
    CGFloat maxWidth = viewWidth - (kSideMargin * 2) - (kHorizontalPadding * 2);
    
    // 使用NSLayoutManager计算文本的行数和每行范围
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:text 
                                                             attributes:@{NSFontAttributeName: self.subtitleLabel.font}];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(maxWidth, CGFLOAT_MAX)];
    textContainer.lineFragmentPadding = 0;
    textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    
    // 强制布局
    [layoutManager ensureLayoutForTextContainer:textContainer];
    
    // 计算总行数和每行的字符范围
    NSUInteger numberOfLines = 0;
    NSUInteger numberOfGlyphs = [layoutManager numberOfGlyphs];
    NSMutableArray<NSValue *> *lineRanges = [NSMutableArray array];
    
    for (NSUInteger index = 0; index < numberOfGlyphs; numberOfLines++) {
        NSRange lineGlyphRange;
        [layoutManager lineFragmentRectForGlyphAtIndex:index effectiveRange:&lineGlyphRange];
        
        // 转换为字符范围
        NSRange lineCharRange = [layoutManager characterRangeForGlyphRange:lineGlyphRange actualGlyphRange:NULL];
        [lineRanges addObject:[NSValue valueWithRange:lineCharRange]];
        
        index = NSMaxRange(lineGlyphRange);
    }
    
    // 如果不超过2行，直接返回原文本
    if (numberOfLines <= 2) {
        return text;
    }
    
    // 超过2行，截取最后2行
    NSUInteger startLineIndex = numberOfLines - 2;
    NSRange lastTwoLinesRange = NSMakeRange(0, 0);
    
    if (startLineIndex < lineRanges.count) {
        NSRange firstLineRange = [lineRanges[startLineIndex] rangeValue];
        NSRange lastLineRange = [lineRanges[lineRanges.count - 1] rangeValue];
        
        lastTwoLinesRange = NSMakeRange(firstLineRange.location, 
                                        NSMaxRange(lastLineRange) - firstLineRange.location);
    }
    
    // 返回最后2行的文本
    if (lastTwoLinesRange.location + lastTwoLinesRange.length <= text.length) {
        return [text substringWithRange:lastTwoLinesRange];
    }
    
    return text;
}

@end
