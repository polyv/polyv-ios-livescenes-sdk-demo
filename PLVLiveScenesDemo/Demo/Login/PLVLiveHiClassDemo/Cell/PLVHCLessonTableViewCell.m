//
//  PLVHCClassDetailView.m
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/7/1.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCLessonTableViewCell.h"

// 工具
#import "PLVHCDemoUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <SDWebImage/UIImageView+WebCache.h>

/// Cell样式枚举
typedef NS_ENUM(NSUInteger, PLVHCLessonTableViewCellStyle) {
    PLVHCLessonTableViewCellNone    = 0,
    PLVHCLessonTableViewCellTitle   = 1,
    PLVHCLessonTableViewCellLine    = 2
};



@interface PLVHCLessonTableViewCell()

/// Cell样式
@property (nonatomic, assign) PLVHCLessonTableViewCellStyle cellStyle;
/// Cell形状
@property (nonatomic, assign) PLVHCLessonTableViewCellShape cellShape;
/// 背景气泡
@property (nonatomic, strong) UIView *bubbleView;
/// 标题
@property (nonatomic, strong) UILabel *titleLabel;
/// 封面图
@property (nonatomic, strong) UIImageView *coverImageView;
/// 课节名称
@property (nonatomic, strong) UILabel *lessonNameLabel;
/// 课程名称
@property (nonatomic, strong) UILabel *courseNameLabel;
/// 时间
@property (nonatomic, strong) UILabel *timeLabel;
/// 下划线
@property (nonatomic, strong) UIView *lineView;

@end

@implementation PLVHCLessonTableViewCell

#pragma mark - [ Life Cycle ]
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        [self initUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    /// bubbleView的参考高度
    CGFloat bubbleViewHeight = 96;
    CGFloat bubbleViewWidth = CGRectGetWidth(self.frame) - 18 * 2;
    CGFloat coverImageViewTopPadding = 15;
    
    self.titleLabel.frame = CGRectZero;
    self.lineView.frame = CGRectZero;
    
    if (self.cellStyle == PLVHCLessonTableViewCellTitle) {
        bubbleViewHeight = 132;
        coverImageViewTopPadding = 50;
        self.titleLabel.frame = CGRectMake(16, 16, 72, 18);
    } else if (self.cellStyle == PLVHCLessonTableViewCellLine){
        self.lineView.frame = CGRectMake(16, 0, bubbleViewWidth - 16 * 2, 1);
    }
    
    self.coverImageView.frame = CGRectMake(16, coverImageViewTopPadding, 88, 66);
    
    /// 文本最大宽度
    CGFloat maxLessonNameLabelWidth = bubbleViewWidth - 120 - 15;
    CGFloat lessonNameLabelHeight = [self.lessonNameLabel sizeThatFits:CGSizeMake(maxLessonNameLabelWidth, MAXFLOAT)].height;
    
    self.lessonNameLabel.frame = CGRectMake(UIViewGetRight(self.coverImageView) + 16, UIViewGetTop(self.coverImageView), maxLessonNameLabelWidth, lessonNameLabelHeight);
    self.timeLabel.frame = CGRectMake(UIViewGetLeft(self.lessonNameLabel), UIViewGetBottom(self.lessonNameLabel) + 10, 110, 12);
    self.courseNameLabel.frame = CGRectMake(UIViewGetLeft(self.lessonNameLabel), UIViewGetBottom(self.timeLabel) + 8, CGRectGetWidth(self.lessonNameLabel.frame), 12);
    
    /// 设置气泡
    if (lessonNameLabelHeight - 18 > 10) {
        bubbleViewHeight += lessonNameLabelHeight - 18;
    }
    self.bubbleView.frame = CGRectMake(18, 0, bubbleViewWidth, bubbleViewHeight);
    self.bubbleView.layer.mask = [self shapeLayerWithView:self.bubbleView shape:self.cellShape];
}

#pragma mark - [ Public method ]

#pragma mark 设置数据源
- (void)updateWithModel:(PLVHCLessonModel *)model title:(NSString *)title line:(BOOL)isLine cellShape:(PLVHCLessonTableViewCellShape)cellShape {
    if (![PLVHCLessonTableViewCell isModelValid:model]) {
        return;
    }
    // 设置cell样式与标题
    if (title && title.length) {
        self.titleLabel.text = title;
        self.cellStyle = PLVHCLessonTableViewCellTitle;
    } else if (isLine) {
        self.cellStyle = PLVHCLessonTableViewCellLine;
    } else {
        self.cellStyle = PLVHCLessonTableViewCellNone;
    }
    self.cellShape = cellShape;
    
    // 数据源填充
    self.lessonNameLabel.text = model.name;
    self.timeLabel.text = model.startTime;
    self.courseNameLabel.text = model.courseNames;
    
    NSURL *coverURL = [PLVHCLessonTableViewCell coverImageURLWithString:model.cover];
    UIImage *placeholderImage = [PLVHCDemoUtils imageForHiClassResource:@"plvhc_default_lesson_image"];
    if (coverURL) {
        [self.coverImageView sd_setImageWithURL:coverURL
                                placeholderImage:placeholderImage
                                         options:SDWebImageRetryFailed];
    } else {
        self.coverImageView.image = placeholderImage;
    }
}

#pragma mark 高度计算
+ (CGFloat)cellHeightWithText:(NSString * _Nonnull)text cellWidth:(CGFloat)cellWidth isTitle:(BOOL)isTitle {
    /// Cell的参考高度
    CGFloat cellHeight = 96;
    if (isTitle) {
        cellHeight = 132;
    }
    /// 气泡相对Cell左右边距
    CGFloat bubbleXPadding = 18;
    /// 文本相对气泡的左边距
    CGFloat textLeftPadding = 120;
    /// 文本相对气泡的右边距
    CGFloat textRightPadding = 15;
    /// 文本最大宽度
    CGFloat maxLessonNameLabelWidth = cellWidth - textLeftPadding - textRightPadding - bubbleXPadding * 2;

    CGFloat lessonNameLabelHeight = [text boundingRectWithSize:CGSizeMake(maxLessonNameLabelWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : [UIFont fontWithName:@"PingFangSC-Medium" size:16]} context:nil].size.height;
    if (lessonNameLabelHeight - 18 > 10) {
        return cellHeight += lessonNameLabelHeight - 18;
    } else {
        return cellHeight;
    }
}


#pragma mark - [ Override ]
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *touchView = [super hitTest:point withEvent:event];
    if (touchView == self.bubbleView) {
        return touchView;
    } else {
        return nil;
    }
}

#pragma mark - [ Private Method ]

- (void)initUI {
    [self.contentView addSubview:self.bubbleView];
    
    [self.bubbleView addSubview:self.coverImageView];
    [self.bubbleView addSubview:self.lessonNameLabel];
    [self.bubbleView addSubview:self.timeLabel];
    [self.bubbleView addSubview:self.courseNameLabel];
    [self.bubbleView addSubview:self.titleLabel];
    [self.bubbleView addSubview:self.lineView];
}

- (CAShapeLayer *)shapeLayerWithView:(UIView *)view shape:(PLVHCLessonTableViewCellShape)shape {
    if (shape == PLVHCLessonTableViewCellNoneRoundedCorners) {
        return nil;
    }
    
    UIBezierPath *maskPath;
    switch (shape) {
        case PLVHCLessonTableViewCellAllRoundedCorners:{
            maskPath = [UIBezierPath bezierPathWithRoundedRect:view.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight | UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii:CGSizeMake(8,8)];
            break;
        }
        case PLVHCLessonTableViewCellTopRoundedCorners:{
            maskPath = [UIBezierPath bezierPathWithRoundedRect:view.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(8,8)];
            break;
        }
        case PLVHCLessonTableViewCellBottomRoundedCorners:{
            CGRect rect = CGRectMake(view.bounds.origin.x, view.bounds.origin.y - 1, view.bounds.size.width, view.bounds.size.height + 1);
            maskPath = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii:CGSizeMake(8,8)];
            break;
        }
        default:
            break;
    }
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = view.bounds;
    maskLayer.path = maskPath.CGPath;
    
    return maskLayer;
}

#pragma mark Getter & Setter

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = PLV_UIColorFromRGB(@"#2D3452");
    }
    return _bubbleView;
}

- (UIImageView *)coverImageView {
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] init];
        _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        _coverImageView.layer.masksToBounds = YES;
        _coverImageView.layer.cornerRadius = 5.87;
    }
    return _coverImageView;
}

- (UILabel *)lessonNameLabel {
    if (!_lessonNameLabel) {
        _lessonNameLabel = [[UILabel alloc] init];
        _lessonNameLabel.text = @"这是课节名称";
        _lessonNameLabel.numberOfLines = 0;
        _lessonNameLabel.textAlignment = NSTextAlignmentLeft;
        _lessonNameLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16];
        _lessonNameLabel.textColor = [UIColor whiteColor];
    }
    return _lessonNameLabel;
}

- (UILabel *)courseNameLabel {
    if (!_courseNameLabel) {
        _courseNameLabel = [[UILabel alloc] init];
        _courseNameLabel.text = @"这是课程名称";
        _courseNameLabel.textAlignment = NSTextAlignmentLeft;
        _courseNameLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _courseNameLabel.textColor = PLV_UIColorFromRGBA(@"#FFFFFF", 0.75);
    }
    return _courseNameLabel;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.text = @"2021-05-05 15:00";
        _timeLabel.textAlignment = NSTextAlignmentLeft;
        _timeLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _timeLabel.textColor = PLV_UIColorFromRGBA(@"#FFFFFF", 0.75);
    }
    return _timeLabel;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:18];
        _titleLabel.textColor = [UIColor whiteColor];
    }
    return _titleLabel;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = PLV_UIColorFromRGBA(@"#FFFFFF", 0.08);
    }
    return _lineView;
}

#pragma mark Util

+ (BOOL)isModelValid:(PLVHCLessonModel *)model {
    if (!model || ![model isKindOfClass:[PLVHCLessonModel class]]) {
        return NO;
    }
    
    return YES;
}

/// 获取课节封面URL
+ (NSURL *)coverImageURLWithString:(NSString *)urlString {

    if (!urlString || ![urlString isKindOfClass:[NSString class]] || !urlString.length) {
        return nil;
    }
    
    return [NSURL URLWithString:urlString];
}


@end
