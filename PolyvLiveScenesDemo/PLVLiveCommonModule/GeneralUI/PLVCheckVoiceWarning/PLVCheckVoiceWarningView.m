//
//  PLVCheckVoiceWarningView.m
//  PolyvLiveScenesDemo
//
//  Created by POLYV on 2026/6/1.
//  Copyright © 2026 PLV. All rights reserved.
//

#import "PLVCheckVoiceWarningView.h"
#import "PLVCheckVoiceWarningModel.h"
#import "PLVMultiLanguageManager.h"

#import <PLVFoundationSDK/PLVFoundationSDK.h>

static CGFloat const kPLVCheckVoiceToastMinHeight = 136.0;
static CGFloat const kPLVCheckVoiceToastMaxHeight = 170.0;
static CGFloat const kPLVCheckVoiceToastMaxWidth = 560.0;
static CGFloat const kPLVCheckVoiceSheetMaxPortraitHeight = 560.0;
static CGFloat const kPLVCheckVoiceToastContentLineHeight = 22.0;
static NSInteger const kPLVCheckVoiceToastContentMaxLines = 3;
static CGFloat const kPLVCheckVoiceWarningIconViewport = 24.0;
static CGFloat const kPLVCheckVoiceWarningIconBackgroundSize = 44.0;
static CGFloat const kPLVCheckVoiceWarningIconTriangleSize = 40.0;
static CGFloat const kPLVCheckVoiceWarningIconExclamationSize = 34.0;
static NSString * const kPLVCheckVoiceWarningCellIdentifier = @"PLVCheckVoiceWarningCellIdentifier";

static CGPoint PLVCheckVoiceWarningIconPoint(CGRect rect, CGFloat x, CGFloat y) {
    return CGPointMake(CGRectGetMinX(rect) + CGRectGetWidth(rect) * x / kPLVCheckVoiceWarningIconViewport,
                       CGRectGetMinY(rect) + CGRectGetHeight(rect) * y / kPLVCheckVoiceWarningIconViewport);
}

static CGRect PLVCheckVoiceWarningIconRect(CGRect rect, CGFloat x, CGFloat y, CGFloat width, CGFloat height) {
    return CGRectMake(CGRectGetMinX(rect) + CGRectGetWidth(rect) * x / kPLVCheckVoiceWarningIconViewport,
                      CGRectGetMinY(rect) + CGRectGetHeight(rect) * y / kPLVCheckVoiceWarningIconViewport,
                      CGRectGetWidth(rect) * width / kPLVCheckVoiceWarningIconViewport,
                      CGRectGetHeight(rect) * height / kPLVCheckVoiceWarningIconViewport);
}

static CGPoint PLVCheckVoiceWarningInterpolatePoint(CGPoint fromPoint, CGPoint toPoint, CGFloat progress) {
    return CGPointMake(fromPoint.x + (toPoint.x - fromPoint.x) * progress,
                       fromPoint.y + (toPoint.y - fromPoint.y) * progress);
}

static UIBezierPath *PLVCheckVoiceWarningTrianglePath(CGRect iconRect) {
    CGPoint topPoint = PLVCheckVoiceWarningIconPoint(iconRect, 12.0, 2.8);
    CGPoint leftPoint = PLVCheckVoiceWarningIconPoint(iconRect, 1.8, 20.8);
    CGPoint rightPoint = PLVCheckVoiceWarningIconPoint(iconRect, 22.2, 20.8);
    CGPoint topLeftPoint = PLVCheckVoiceWarningInterpolatePoint(topPoint, leftPoint, 0.22);
    CGPoint topRightPoint = PLVCheckVoiceWarningInterpolatePoint(topPoint, rightPoint, 0.22);
    CGPoint leftTopPoint = PLVCheckVoiceWarningInterpolatePoint(leftPoint, topPoint, 0.18);
    CGPoint leftRightPoint = PLVCheckVoiceWarningInterpolatePoint(leftPoint, rightPoint, 0.18);
    CGPoint rightLeftPoint = PLVCheckVoiceWarningInterpolatePoint(rightPoint, leftPoint, 0.18);
    CGPoint rightTopPoint = PLVCheckVoiceWarningInterpolatePoint(rightPoint, topPoint, 0.18);

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:topLeftPoint];
    [path addQuadCurveToPoint:topRightPoint controlPoint:topPoint];
    [path addLineToPoint:rightTopPoint];
    [path addQuadCurveToPoint:rightLeftPoint controlPoint:rightPoint];
    [path addLineToPoint:leftRightPoint];
    [path addQuadCurveToPoint:leftTopPoint controlPoint:leftPoint];
    [path closePath];
    return path;
}

static UIBezierPath *PLVCheckVoiceWarningExclamationPath(CGRect iconRect) {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path appendPath:[UIBezierPath bezierPathWithRoundedRect:PLVCheckVoiceWarningIconRect(iconRect, 10.85, 6.80, 2.30, 8.60)
                                             cornerRadius:CGRectGetWidth(iconRect) * 1.15 / kPLVCheckVoiceWarningIconViewport]];
    [path appendPath:[UIBezierPath bezierPathWithOvalInRect:PLVCheckVoiceWarningIconRect(iconRect, 10.85, 16.20, 2.30, 2.30)]];
    return path;
}

@interface PLVCheckVoiceWarningCell : UITableViewCell

@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIView *riskIconView;
@property (nonatomic, strong) UILabel *riskLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UILabel *typeTitleLabel;
@property (nonatomic, strong) UILabel *typeLabel;
@property (nonatomic, strong) UILabel *levelTitleLabel;
@property (nonatomic, strong) UILabel *levelLabel;

- (void)updateWithModel:(PLVCheckVoiceWarningModel *)model;
+ (CGFloat)cellHeightWithModel:(PLVCheckVoiceWarningModel *)model width:(CGFloat)width;

@end

@implementation PLVCheckVoiceWarningCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self.contentView addSubview:self.cardView];
        [self.cardView addSubview:self.timeLabel];
        [self.cardView addSubview:self.riskIconView];
        [self.cardView addSubview:self.riskLabel];
        [self.cardView addSubview:self.contentLabel];
        [self.cardView addSubview:self.typeTitleLabel];
        [self.cardView addSubview:self.typeLabel];
        [self.cardView addSubview:self.levelTitleLabel];
        [self.cardView addSubview:self.levelLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat width = CGRectGetWidth(self.contentView.bounds);
    self.cardView.frame = CGRectMake(0, 10, width, CGRectGetHeight(self.contentView.bounds) - 16);

    CGFloat padding = 20;
    CGFloat timeWidth = 64;
    CGFloat contentX = padding + timeWidth + 8;
    CGFloat contentWidth = CGRectGetWidth(self.cardView.bounds) - contentX - padding;
    self.timeLabel.frame = CGRectMake(padding, 20, timeWidth, 24);
    self.riskIconView.frame = CGRectMake(contentX, 15, 32, 32);
    self.riskLabel.frame = CGRectMake(CGRectGetMaxX(self.riskIconView.frame) + 10, 18, contentWidth - 42, 26);

    CGFloat contentY = 58;
    CGFloat contentHeight = [PLVCheckVoiceWarningCell contentHeightWithText:self.contentLabel.text width:contentWidth font:self.contentLabel.font];
    self.contentLabel.frame = CGRectMake(contentX, contentY, contentWidth, contentHeight);

    CGFloat typeTitleY = CGRectGetMaxY(self.contentLabel.frame) + 18;
    self.typeTitleLabel.frame = CGRectMake(contentX, typeTitleY, contentWidth, 20);
    self.typeLabel.frame = CGRectMake(contentX, CGRectGetMaxY(self.typeTitleLabel.frame) + 6, contentWidth, 22);
    self.levelTitleLabel.frame = CGRectMake(contentX, CGRectGetMaxY(self.typeLabel.frame) + 16, contentWidth, 20);
    self.levelLabel.frame = CGRectMake(contentX, CGRectGetMaxY(self.levelTitleLabel.frame) + 6, contentWidth, 22);
    [self layoutRiskIconLayers];
}

- (void)updateWithModel:(PLVCheckVoiceWarningModel *)model {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:model.timestamp];
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"HH:mm:ss";
    });

    self.timeLabel.text = [formatter stringFromDate:date];
    self.riskLabel.text = model.riskLevelText;
    self.riskLabel.textColor = model.riskColor;
    self.contentLabel.text = [NSString stringWithFormat:@"“%@”", model.content ?: @""];
    self.typeLabel.text = [PLVFdUtil checkStringUseable:model.type] ? model.type : PLVLocalizedString(@"自定义敏感词");
    self.levelLabel.text = model.riskLevelText;
    self.levelLabel.textColor = model.riskColor;
}

+ (CGFloat)cellHeightWithModel:(PLVCheckVoiceWarningModel *)model width:(CGFloat)width {
    CGFloat padding = 20;
    CGFloat timeWidth = 64;
    CGFloat contentX = padding + timeWidth + 8;
    CGFloat contentWidth = width - contentX - padding;
    NSString *content = [NSString stringWithFormat:@"“%@”", model.content ?: @""];
    UIFont *contentFont = [UIFont fontWithName:@"PingFangSC-Semibold" size:16];
    if (!contentFont) {
        contentFont = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    }
    CGFloat contentHeight = [self contentHeightWithText:content width:contentWidth font:contentFont];
    CGFloat cardHeight = 58 + contentHeight + 18 + 20 + 6 + 22 + 16 + 20 + 6 + 22 + 24;
    return MAX(220, cardHeight + 16);
}

+ (CGFloat)contentHeightWithText:(NSString *)text width:(CGFloat)width font:(UIFont *)font {
    if (width <= 0 || ![PLVFdUtil checkStringUseable:text]) {
        return 22;
    }
    UIFont *textFont = font ?: [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    CGRect rect = [text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                  attributes:@{NSFontAttributeName: textFont}
                                     context:nil];
    return MAX(22, ceil(CGRectGetHeight(rect)));
}

- (void)layoutRiskIconLayers {
    CAShapeLayer *backgroundLayer = [self.riskIconView.layer valueForKey:@"PLVWarningIconBackgroundLayer"];
    if (!backgroundLayer) {
        backgroundLayer = [CAShapeLayer layer];
        backgroundLayer.fillColor = PLV_UIColorFromRGBA(@"#FF3B30", 0.18).CGColor;
        [self.riskIconView.layer setValue:backgroundLayer forKey:@"PLVWarningIconBackgroundLayer"];
        [self.riskIconView.layer addSublayer:backgroundLayer];
    }

    CAShapeLayer *triangleLayer = [self.riskIconView.layer valueForKey:@"PLVWarningTriangleLayer"];
    if (!triangleLayer) {
        triangleLayer = [CAShapeLayer layer];
        triangleLayer.fillColor = PLV_UIColorFromRGB(@"#FF3B30").CGColor;
        [self.riskIconView.layer setValue:triangleLayer forKey:@"PLVWarningTriangleLayer"];
        [self.riskIconView.layer addSublayer:triangleLayer];
    }

    CAShapeLayer *exclamationLayer = [self.riskIconView.layer valueForKey:@"PLVWarningExclamationLayer"];
    if (!exclamationLayer) {
        exclamationLayer = [CAShapeLayer layer];
        exclamationLayer.fillColor = [UIColor whiteColor].CGColor;
        [self.riskIconView.layer setValue:exclamationLayer forKey:@"PLVWarningExclamationLayer"];
        [self.riskIconView.layer addSublayer:exclamationLayer];
    }

    CGRect bounds = self.riskIconView.bounds;
    CGRect backgroundRect = bounds;
    CGFloat triangleSize = CGRectGetWidth(bounds) * kPLVCheckVoiceWarningIconTriangleSize / kPLVCheckVoiceWarningIconBackgroundSize;
    CGFloat exclamationSize = CGRectGetWidth(bounds) * kPLVCheckVoiceWarningIconExclamationSize / kPLVCheckVoiceWarningIconBackgroundSize;
    CGRect triangleRect = CGRectMake((CGRectGetWidth(bounds) - triangleSize) / 2.0,
                                     (CGRectGetHeight(bounds) - triangleSize) / 2.0 - 3,
                                     triangleSize,
                                     triangleSize);
    CGRect exclamationRect = CGRectMake((CGRectGetWidth(bounds) - exclamationSize) / 2.0,
                                        (CGRectGetHeight(bounds) - exclamationSize) / 2.0 - 2,
                                        exclamationSize,
                                        exclamationSize);
    backgroundLayer.path = [UIBezierPath bezierPathWithOvalInRect:backgroundRect].CGPath;
    triangleLayer.path = [PLVCheckVoiceWarningTrianglePath(triangleRect) CGPath];
    exclamationLayer.path = [PLVCheckVoiceWarningExclamationPath(exclamationRect) CGPath];
}

- (UIView *)cardView {
    if (!_cardView) {
        _cardView = [[UIView alloc] init];
        _cardView.backgroundColor = PLV_UIColorFromRGBA(@"#232832", 0.94);
        _cardView.layer.cornerRadius = 8;
        _cardView.clipsToBounds = YES;
    }
    return _cardView;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [self labelWithFont:[UIFont fontWithName:@"PingFangSC-Regular" size:14] color:PLV_UIColorFromRGBA(@"#FFFFFF", 0.6)];
    }
    return _timeLabel;
}

- (UILabel *)riskLabel {
    if (!_riskLabel) {
        _riskLabel = [self labelWithFont:[UIFont fontWithName:@"PingFangSC-Semibold" size:14] color:PLV_UIColorFromRGB(@"#FF4D4F")];
    }
    return _riskLabel;
}

- (UIView *)riskIconView {
    if (!_riskIconView) {
        _riskIconView = [[UIView alloc] init];
        _riskIconView.backgroundColor = [UIColor clearColor];
        _riskIconView.userInteractionEnabled = NO;
    }
    return _riskIconView;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [self labelWithFont:[UIFont fontWithName:@"PingFangSC-Semibold" size:16] color:PLV_UIColorFromRGB(@"#FF4D4F")];
        _contentLabel.numberOfLines = 0;
        _contentLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _contentLabel.adjustsFontSizeToFitWidth = NO;
    }
    return _contentLabel;
}

- (UILabel *)typeTitleLabel {
    if (!_typeTitleLabel) {
        _typeTitleLabel = [self labelWithFont:[UIFont fontWithName:@"PingFangSC-Regular" size:14] color:PLV_UIColorFromRGBA(@"#FFFFFF", 0.45)];
        _typeTitleLabel.text = PLVLocalizedString(@"风险类型");
    }
    return _typeTitleLabel;
}

- (UILabel *)typeLabel {
    if (!_typeLabel) {
        _typeLabel = [self labelWithFont:[UIFont fontWithName:@"PingFangSC-Regular" size:15] color:PLV_UIColorFromRGB(@"#FFFFFF")];
    }
    return _typeLabel;
}

- (UILabel *)levelTitleLabel {
    if (!_levelTitleLabel) {
        _levelTitleLabel = [self labelWithFont:[UIFont fontWithName:@"PingFangSC-Regular" size:14] color:PLV_UIColorFromRGBA(@"#FFFFFF", 0.45)];
        _levelTitleLabel.text = PLVLocalizedString(@"风险等级");
    }
    return _levelTitleLabel;
}

- (UILabel *)levelLabel {
    if (!_levelLabel) {
        _levelLabel = [self labelWithFont:[UIFont fontWithName:@"PingFangSC-Semibold" size:15] color:PLV_UIColorFromRGB(@"#FF4D4F")];
    }
    return _levelLabel;
}

- (UILabel *)labelWithFont:(UIFont *)font color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] init];
    label.font = font;
    label.textColor = color;
    label.numberOfLines = 1;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.75;
    return label;
}

@end

@interface PLVCheckVoiceWarningView ()<
UITableViewDataSource,
UITableViewDelegate
>

@property (nonatomic, strong) NSMutableArray<PLVCheckVoiceWarningModel *> *warningModels;
@property (nonatomic, copy) NSArray<PLVCheckVoiceWarningModel *> *sheetDisplayModels;
@property (nonatomic, strong) UIView *toastView;
@property (nonatomic, strong) UILabel *toastTitleLabel;
@property (nonatomic, strong) UILabel *toastContentLabel;
@property (nonatomic, strong) UILabel *toastRiskLabel;
@property (nonatomic, strong) UIButton *toastCloseButton;
@property (nonatomic, strong) UIButton *toastDetailButton;
@property (nonatomic, strong) UILabel *toastDetailArrowLabel;
@property (nonatomic, strong) UIView *sheetMaskView;
@property (nonatomic, strong) UIView *sheetContentView;
@property (nonatomic, strong) UILabel *sheetTitleLabel;
@property (nonatomic, strong) UIView *sheetGrabberView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *scrollHintLabel;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, assign) NSInteger toastNewWarningCountSinceLastDetail;

@end

@implementation PLVCheckVoiceWarningView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.warningModels = [[NSMutableArray alloc] init];
        [self addSubview:self.toastView];
        [self addSubview:self.sheetMaskView];
        [self.sheetMaskView addSubview:self.sheetContentView];
        [self.sheetContentView addSubview:self.sheetGrabberView];
        [self.sheetContentView addSubview:self.sheetTitleLabel];
        [self.sheetContentView addSubview:self.tableView];
        [self.sheetContentView addSubview:self.scrollHintLabel];
        [self.sheetContentView addSubview:self.confirmButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateLayoutForParentView];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.hidden || self.alpha <= 0.01 || !self.userInteractionEnabled) {
        return nil;
    }
    
    if (!self.sheetMaskView.hidden) {
        return [super hitTest:point withEvent:event];
    }
    
    if (!self.toastView.hidden) {
        CGPoint toastPoint = [self convertPoint:point toView:self.toastView];
        if ([self.toastView pointInside:toastPoint withEvent:event]) {
            return [super hitTest:point withEvent:event];
        }
    }
    
    return nil;
}

- (void)receiveWarningModels:(NSArray<PLVCheckVoiceWarningModel *> *)warningModels {
    if (![PLVFdUtil checkArrayUseable:warningModels]) {
        return;
    }
    
    [self.warningModels addObjectsFromArray:warningModels];
    self.toastNewWarningCountSinceLastDetail += warningModels.count;
    
    PLVCheckVoiceWarningModel *latestModel = warningModels.lastObject;
    [self showToastWithModel:latestModel];
}

- (void)updateLayoutForParentView {
    CGRect bounds = self.bounds;
    if (CGRectIsEmpty(bounds)) {
        return;
    }
    
    BOOL landscape = CGRectGetWidth(bounds) > CGRectGetHeight(bounds);
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = self.safeAreaInsets;
    }
    
    CGFloat toastWidth = MIN(CGRectGetWidth(bounds) - safeAreaInsets.left - safeAreaInsets.right - 32, kPLVCheckVoiceToastMaxWidth);
    CGFloat toastX = safeAreaInsets.left + 16;
    if (landscape) {
        toastWidth = MIN(CGRectGetWidth(bounds) * 0.44, kPLVCheckVoiceToastMaxWidth);
        toastX = safeAreaInsets.left + 24;
    }
    CGFloat toastHeight = [self currentToastHeightForWidth:toastWidth];
    self.toastView.frame = CGRectMake(toastX, safeAreaInsets.top + (landscape ? 64 : 118), toastWidth, toastHeight);
    [self layoutToastSubviews];
    
    self.sheetMaskView.frame = bounds;
    CGFloat sheetWidth = CGRectGetWidth(bounds);
    CGFloat sheetHeight = MIN(CGRectGetHeight(bounds) * 0.66, kPLVCheckVoiceSheetMaxPortraitHeight);
    CGFloat sheetX = 0;
    CGFloat sheetY = CGRectGetHeight(bounds) - sheetHeight;
    if (landscape) {
        sheetWidth = CGRectGetWidth(bounds) * 0.44;
        sheetHeight = CGRectGetHeight(bounds) - safeAreaInsets.top - safeAreaInsets.bottom;
        sheetX = CGRectGetWidth(bounds) - safeAreaInsets.right - sheetWidth;
        sheetY = safeAreaInsets.top;
    }
    self.sheetContentView.frame = CGRectMake(sheetX, sheetY, sheetWidth, sheetHeight);
    [self layoutSheetSubviews];
}

#pragma mark - Action

- (void)closeToastButtonAction {
    [self hideToast];
}

- (void)showDetailButtonAction {
    self.toastNewWarningCountSinceLastDetail = 0;
    [self showSheet];
}

- (void)confirmButtonAction {
    [self hideSheet];
}

#pragma mark - Toast

- (void)showToastWithModel:(PLVCheckVoiceWarningModel *)model {
    if (!model) {
        return;
    }
    
    BOOL toastVisible = !self.toastView.hidden && self.toastView.alpha > 0.01;
    self.toastTitleLabel.text = [NSString stringWithFormat:PLVLocalizedString(@"检测到%@内容"), model.riskLevelText];
    self.toastContentLabel.text = [NSString stringWithFormat:@"“%@”", model.content ?: @""];
    self.toastRiskLabel.text = model.riskLevelText;
    self.toastRiskLabel.textColor = model.riskColor;
    self.toastRiskLabel.backgroundColor = [model.riskColor colorWithAlphaComponent:0.14];
    [self updateToastDetailButtonTitle];
    
    self.userInteractionEnabled = YES;
    self.toastView.hidden = NO;
    if (toastVisible) {
        [UIView animateWithDuration:0.2 animations:^{
            [self updateLayoutForParentView];
        }];
    } else {
        [self updateLayoutForParentView];
        self.toastView.alpha = 0;
        [UIView animateWithDuration:0.2 animations:^{
            self.toastView.alpha = 1;
        }];
    }
}

- (void)hideToast {
    [UIView animateWithDuration:0.2 animations:^{
        self.toastView.alpha = 0;
    } completion:^(BOOL finished) {
        if (self.toastView.alpha <= 0.01) {
            self.toastView.hidden = YES;
            [self updateInteractionEnabled];
        }
    }];
}

- (void)updateToastDetailButtonTitle {
    NSString *title = PLVLocalizedString(@"查看本次提醒");
    if (self.toastNewWarningCountSinceLastDetail > 1) {
        title = [NSString stringWithFormat:@"%@ (%@)", title, @(self.toastNewWarningCountSinceLastDetail)];
    }
    [self.toastDetailButton setTitle:title forState:UIControlStateNormal];
}

- (CGFloat)currentToastHeightForWidth:(CGFloat)width {
    CGFloat contentHeight = [self toastContentHeightForWidth:width];
    CGFloat dynamicHeight = 54 + contentHeight + 48;
    return MIN(kPLVCheckVoiceToastMaxHeight, MAX(kPLVCheckVoiceToastMinHeight, dynamicHeight));
}

- (CGFloat)toastContentHeightForWidth:(CGFloat)width {
    CGFloat textX = 68;
    CGFloat riskLabelWidth = 72;
    CGFloat riskLabelRight = 18;
    CGFloat contentWidth = width - riskLabelRight - riskLabelWidth - textX - 18;
    if (contentWidth <= 0) {
        return kPLVCheckVoiceToastContentLineHeight;
    }

    NSString *text = self.toastContentLabel.text;
    if (![PLVFdUtil checkStringUseable:text]) {
        return kPLVCheckVoiceToastContentLineHeight;
    }

    CGSize maxSize = CGSizeMake(contentWidth, CGFLOAT_MAX);
    CGRect textRect = [text boundingRectWithSize:maxSize
                                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                      attributes:@{NSFontAttributeName: self.toastContentLabel.font}
                                         context:nil];
    NSInteger lineCount = (NSInteger)ceil(CGRectGetHeight(textRect) / kPLVCheckVoiceToastContentLineHeight);
    lineCount = MAX(1, MIN(kPLVCheckVoiceToastContentMaxLines, lineCount));
    return lineCount * kPLVCheckVoiceToastContentLineHeight;
}

- (void)layoutToastSubviews {
    CGFloat width = CGRectGetWidth(self.toastView.bounds);
    CGFloat height = CGRectGetHeight(self.toastView.bounds);
    CGFloat padding = 16;
    CGFloat contentHeight = [self toastContentHeightForWidth:width];
    self.toastCloseButton.frame = CGRectMake(width - 44, 8, 36, 36);
    CGFloat textX = 68;
    CGFloat riskLabelWidth = 72;
    CGFloat riskLabelRight = 18;
    CGFloat riskLabelX = width - riskLabelRight - riskLabelWidth;
    self.toastTitleLabel.frame = CGRectMake(textX, 20, width - textX - 48, 26);
    self.toastRiskLabel.frame = CGRectMake(riskLabelX, 56, riskLabelWidth, 28);
    self.toastContentLabel.frame = CGRectMake(textX, 54, riskLabelX - textX - 18, contentHeight);
    CGSize detailTextSize = [self.toastDetailButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: self.toastDetailButton.titleLabel.font}];
    CGFloat detailButtonWidth = MIN(156, MAX(124, ceil(detailTextSize.width) + 32));
    CGFloat detailButtonHeight = 30;
    self.toastDetailButton.frame = CGRectMake(width - padding - detailButtonWidth, height - 44, detailButtonWidth, detailButtonHeight);
    self.toastDetailButton.layer.cornerRadius = detailButtonHeight / 2.0;
    self.toastDetailArrowLabel.bounds = CGRectMake(0, 0, 20, detailButtonHeight);
    self.toastDetailArrowLabel.center = CGPointMake(detailButtonWidth - 14, detailButtonHeight / 2.0);
    
    CAShapeLayer *iconBackgroundLayer = [self.toastView.layer valueForKey:@"PLVWarningIconBackgroundLayer"];
    if (!iconBackgroundLayer) {
        iconBackgroundLayer = [CAShapeLayer layer];
        iconBackgroundLayer.fillColor = PLV_UIColorFromRGBA(@"#FF3B30", 0.18).CGColor;
        [self.toastView.layer setValue:iconBackgroundLayer forKey:@"PLVWarningIconBackgroundLayer"];
        [self.toastView.layer addSublayer:iconBackgroundLayer];
    }

    CAShapeLayer *warningLayer = [self.toastView.layer valueForKey:@"PLVWarningLayer"];
    if (!warningLayer) {
        warningLayer = [CAShapeLayer layer];
        warningLayer.fillColor = PLV_UIColorFromRGB(@"#FF3B30").CGColor;
        [self.toastView.layer setValue:warningLayer forKey:@"PLVWarningLayer"];
        [self.toastView.layer addSublayer:warningLayer];
    }
    
    CAShapeLayer *exclamationLayer = [self.toastView.layer valueForKey:@"PLVWarningExclamationLayer"];
    if (!exclamationLayer) {
        exclamationLayer = [CAShapeLayer layer];
        exclamationLayer.fillColor = [UIColor whiteColor].CGColor;
        [self.toastView.layer setValue:exclamationLayer forKey:@"PLVWarningExclamationLayer"];
        [self.toastView.layer addSublayer:exclamationLayer];
    }

    CGRect backgroundRect = CGRectMake(padding - 6, 22, kPLVCheckVoiceWarningIconBackgroundSize, kPLVCheckVoiceWarningIconBackgroundSize);
    CGFloat triangleOriginX = CGRectGetMidX(backgroundRect) - kPLVCheckVoiceWarningIconTriangleSize / 2.0;
    CGFloat triangleOriginY = CGRectGetMidY(backgroundRect) - kPLVCheckVoiceWarningIconTriangleSize / 2.0 - 4;
    CGFloat exclamationOriginX = CGRectGetMidX(backgroundRect) - kPLVCheckVoiceWarningIconExclamationSize / 2.0;
    CGFloat exclamationOriginY = CGRectGetMidY(backgroundRect) - kPLVCheckVoiceWarningIconExclamationSize / 2.0 - 2;
    CGRect triangleRect = CGRectMake(triangleOriginX, triangleOriginY, kPLVCheckVoiceWarningIconTriangleSize, kPLVCheckVoiceWarningIconTriangleSize);
    CGRect exclamationRect = CGRectMake(exclamationOriginX, exclamationOriginY, kPLVCheckVoiceWarningIconExclamationSize, kPLVCheckVoiceWarningIconExclamationSize);
    iconBackgroundLayer.path = [UIBezierPath bezierPathWithOvalInRect:backgroundRect].CGPath;
    warningLayer.path = [PLVCheckVoiceWarningTrianglePath(triangleRect) CGPath];
    exclamationLayer.path = [PLVCheckVoiceWarningExclamationPath(exclamationRect) CGPath];
}

#pragma mark - Sheet

- (void)showSheet {
    self.toastView.hidden = YES;
    self.toastView.alpha = 0;
    self.sheetDisplayModels = [self currentDisplayModels];
    [self updateSheetHeader];
    [self.tableView reloadData];
    self.sheetMaskView.hidden = NO;
    self.sheetMaskView.alpha = 0;
    self.userInteractionEnabled = YES;
    [self updateLayoutForParentView];
    
    CGRect finalFrame = self.sheetContentView.frame;
    CGRect startFrame = finalFrame;
    startFrame.origin.y = CGRectGetHeight(self.bounds);
    self.sheetContentView.frame = startFrame;
    [UIView animateWithDuration:0.25 animations:^{
        self.sheetMaskView.alpha = 1;
        self.sheetContentView.frame = finalFrame;
    } completion:^(BOOL finished) {
        if ([self.tableView numberOfRowsInSection:0] > 0) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
        [self updateScrollHintVisibilityAnimated:NO];
    }];
}

- (void)hideSheet {
    CGRect finalFrame = self.sheetContentView.frame;
    finalFrame.origin.y = CGRectGetHeight(self.bounds);
    [UIView animateWithDuration:0.25 animations:^{
        self.sheetMaskView.alpha = 0;
        self.sheetContentView.frame = finalFrame;
    } completion:^(BOOL finished) {
        self.sheetMaskView.hidden = YES;
        self.sheetDisplayModels = nil;
        [self.tableView reloadData];
        [self updateInteractionEnabled];
    }];
}

- (void)layoutSheetSubviews {
    CGFloat width = CGRectGetWidth(self.sheetContentView.bounds);
    CGFloat height = CGRectGetHeight(self.sheetContentView.bounds);
    BOOL landscape = CGRectGetWidth(self.bounds) > CGRectGetHeight(self.bounds);
    CGFloat padding = landscape ? 20 : 24;
    CGFloat titleY = landscape ? 16 : 56;
    CGFloat tableY = landscape ? 60 : 108;
    CGFloat confirmBottom = landscape ? 14 : 72;
    CGFloat hintSpacing = landscape ? 24 : 34;
    CGFloat tableHintSpacing = landscape ? 4 : 10;

    self.sheetGrabberView.hidden = landscape;
    self.sheetGrabberView.frame = CGRectMake((width - 46) / 2.0, 12, 46, 5);
    self.sheetTitleLabel.frame = CGRectMake(padding, titleY, width - padding * 2, 28);
    self.confirmButton.frame = CGRectMake(padding, height - confirmBottom - 48, width - padding * 2, 48);
    CGFloat scrollHintY = CGRectGetMinY(self.confirmButton.frame) - hintSpacing;
    self.scrollHintLabel.frame = CGRectMake(padding, scrollHintY, width - padding * 2, 22);
    CGFloat tableX = padding;
    CGFloat tableRight = CGRectGetMaxX(self.confirmButton.frame);
    self.tableView.frame = CGRectMake(tableX, tableY, tableRight - tableX, MAX(120, scrollHintY - tableHintSpacing - tableY));
    [self updateScrollHintVisibilityAnimated:NO];
}

- (void)updateSheetHeader {
    self.sheetTitleLabel.text = PLVLocalizedString(@"风险提醒");
}

- (NSArray<PLVCheckVoiceWarningModel *> *)currentDisplayModels {
    return [[self.warningModels reverseObjectEnumerator] allObjects];
}

- (NSArray<PLVCheckVoiceWarningModel *> *)displayModels {
    return self.sheetDisplayModels ?: @[];
}

- (void)updateScrollHintVisibilityAnimated:(BOOL)animated {
    if (!self.tableView || !self.scrollHintLabel) {
        return;
    }

    CGFloat contentHeight = self.tableView.contentSize.height;
    CGFloat visibleHeight = CGRectGetHeight(self.tableView.bounds);
    CGFloat maxOffsetY = contentHeight - visibleHeight;
    CGFloat targetAlpha = 0;
    if (maxOffsetY > 1) {
        CGFloat distanceToBottom = maxOffsetY - self.tableView.contentOffset.y;
        targetAlpha = MIN(1.0, MAX(0.0, distanceToBottom / 44.0));
    }

    if (animated) {
        [UIView animateWithDuration:0.15 animations:^{
            self.scrollHintLabel.alpha = targetAlpha;
        }];
    } else {
        self.scrollHintLabel.alpha = targetAlpha;
    }
}

- (void)updateInteractionEnabled {
    self.userInteractionEnabled = !self.toastView.hidden || !self.sheetMaskView.hidden;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self displayModels].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLVCheckVoiceWarningCell *cell = [tableView dequeueReusableCellWithIdentifier:kPLVCheckVoiceWarningCellIdentifier forIndexPath:indexPath];
    NSArray *models = [self displayModels];
    if (indexPath.row < models.count) {
        [cell updateWithModel:models[indexPath.row]];
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *models = [self displayModels];
    if (indexPath.row >= models.count) {
        return 0;
    }
    return [PLVCheckVoiceWarningCell cellHeightWithModel:models[indexPath.row] width:CGRectGetWidth(tableView.bounds)];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateScrollHintVisibilityAnimated:NO];
}

#pragma mark - Getter

- (UIView *)toastView {
    if (!_toastView) {
        _toastView = [[UIView alloc] init];
        _toastView.backgroundColor = PLV_UIColorFromRGBA(@"#1F2430", 0.95);
        _toastView.layer.cornerRadius = 12;
        _toastView.clipsToBounds = YES;
        _toastView.hidden = YES;
        
        [_toastView addSubview:self.toastTitleLabel];
        [_toastView addSubview:self.toastContentLabel];
        [_toastView addSubview:self.toastRiskLabel];
        [_toastView addSubview:self.toastCloseButton];
        [_toastView addSubview:self.toastDetailButton];
        [self.toastDetailButton addSubview:self.toastDetailArrowLabel];
    }
    return _toastView;
}

- (UILabel *)toastTitleLabel {
    if (!_toastTitleLabel) {
        _toastTitleLabel = [[UILabel alloc] init];
        _toastTitleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:18];
        _toastTitleLabel.textColor = [UIColor whiteColor];
        _toastTitleLabel.adjustsFontSizeToFitWidth = YES;
        _toastTitleLabel.minimumScaleFactor = 0.75;
    }
    return _toastTitleLabel;
}

- (UILabel *)toastContentLabel {
    if (!_toastContentLabel) {
        _toastContentLabel = [[UILabel alloc] init];
        _toastContentLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:15];
        _toastContentLabel.textColor = [UIColor whiteColor];
        _toastContentLabel.numberOfLines = 3;
        _toastContentLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _toastContentLabel;
}

- (UILabel *)toastRiskLabel {
    if (!_toastRiskLabel) {
        _toastRiskLabel = [[UILabel alloc] init];
        _toastRiskLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:15];
        _toastRiskLabel.textAlignment = NSTextAlignmentCenter;
        _toastRiskLabel.layer.cornerRadius = 14;
        _toastRiskLabel.clipsToBounds = YES;
    }
    return _toastRiskLabel;
}

- (UIButton *)toastCloseButton {
    if (!_toastCloseButton) {
        _toastCloseButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_toastCloseButton setTitle:@"×" forState:UIControlStateNormal];
        [_toastCloseButton setTitleColor:PLV_UIColorFromRGBA(@"#FFFFFF", 0.8) forState:UIControlStateNormal];
        _toastCloseButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:28];
        [_toastCloseButton addTarget:self action:@selector(closeToastButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _toastCloseButton;
}

- (UIButton *)toastDetailButton {
    if (!_toastDetailButton) {
        _toastDetailButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _toastDetailButton.backgroundColor = PLV_UIColorFromRGBA(@"#1E1F23", 0.95);
        _toastDetailButton.layer.cornerRadius = 15;
        _toastDetailButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:13];
        [_toastDetailButton setTitleColor:PLV_UIColorFromRGBA(@"#FFFFFF", 0.9) forState:UIControlStateNormal];
        _toastDetailButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 14);
        [_toastDetailButton addTarget:self action:@selector(showDetailButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _toastDetailButton;
}

- (UILabel *)toastDetailArrowLabel {
    if (!_toastDetailArrowLabel) {
        _toastDetailArrowLabel = [[UILabel alloc] init];
        _toastDetailArrowLabel.text = @">";
        _toastDetailArrowLabel.textColor = PLV_UIColorFromRGBA(@"#FFFFFF", 0.9);
        _toastDetailArrowLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _toastDetailArrowLabel.textAlignment = NSTextAlignmentCenter;
        _toastDetailArrowLabel.transform = CGAffineTransformMakeRotation(M_PI_2);
        _toastDetailArrowLabel.userInteractionEnabled = NO;
    }
    return _toastDetailArrowLabel;
}

- (UIView *)sheetMaskView {
    if (!_sheetMaskView) {
        _sheetMaskView = [[UIView alloc] init];
        _sheetMaskView.backgroundColor = PLV_UIColorFromRGBA(@"#000000", 0.42);
        _sheetMaskView.hidden = YES;
    }
    return _sheetMaskView;
}

- (UIView *)sheetContentView {
    if (!_sheetContentView) {
        _sheetContentView = [[UIView alloc] init];
        _sheetContentView.backgroundColor = PLV_UIColorFromRGBA(@"#151922", 0.98);
        _sheetContentView.layer.cornerRadius = 14;
        _sheetContentView.clipsToBounds = YES;
    }
    return _sheetContentView;
}

- (UIView *)sheetGrabberView {
    if (!_sheetGrabberView) {
        _sheetGrabberView = [[UIView alloc] init];
        _sheetGrabberView.backgroundColor = PLV_UIColorFromRGBA(@"#FFFFFF", 0.24);
        _sheetGrabberView.layer.cornerRadius = 2.5;
        _sheetGrabberView.clipsToBounds = YES;
    }
    return _sheetGrabberView;
}

- (UILabel *)sheetTitleLabel {
    if (!_sheetTitleLabel) {
        _sheetTitleLabel = [[UILabel alloc] init];
        _sheetTitleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:20];
        _sheetTitleLabel.textColor = [UIColor whiteColor];
        _sheetTitleLabel.adjustsFontSizeToFitWidth = YES;
        _sheetTitleLabel.minimumScaleFactor = 0.75;
    }
    return _sheetTitleLabel;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.estimatedRowHeight = 220;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        [_tableView registerClass:[PLVCheckVoiceWarningCell class] forCellReuseIdentifier:kPLVCheckVoiceWarningCellIdentifier];
    }
    return _tableView;
}

- (UILabel *)scrollHintLabel {
    if (!_scrollHintLabel) {
        _scrollHintLabel = [[UILabel alloc] init];
        _scrollHintLabel.text = [NSString stringWithFormat:@"%@ ˅", PLVLocalizedString(@"向下滑动查看更多")];
        _scrollHintLabel.textColor = PLV_UIColorFromRGBA(@"#FFFFFF", 0.55);
        _scrollHintLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        _scrollHintLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _scrollHintLabel;
}

- (UIButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _confirmButton.backgroundColor = PLV_UIColorFromRGB(@"#1464FF");
        _confirmButton.layer.cornerRadius = 6;
        _confirmButton.clipsToBounds = YES;
        _confirmButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:17];
        [_confirmButton setTitle:PLVLocalizedString(@"知道了") forState:UIControlStateNormal];
        [_confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_confirmButton addTarget:self action:@selector(confirmButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

@end
