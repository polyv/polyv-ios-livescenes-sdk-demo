//
//  PLVHCCompanyTableViewCell.m
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/6/30.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCCompanyTableViewCell.h"
#import "PLVHCDemoUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>


@interface PLVHCCompanyTableViewCell()

// 气泡视图（父视图）
@property (nonatomic, strong) UIView *bubbleView;
// 标题
@property (nonatomic, strong) UILabel *titleLabel;
// 选中后的渐变layer
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
// 选中标记图片
@property (nonatomic, strong) UIImageView *selectedImageView;

@end

@implementation PLVHCCompanyTableViewCell

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
    
    /// 气泡相对Cell左右边距
    CGFloat bubbleXPadding = 18;
    /// 文本相对气泡的左边距
    CGFloat textLeftPadding = 16;
    /// 文本相对气泡的右边距
    CGFloat textRightPadding = 64;
    /// 文本相对气泡的上下边距
    CGFloat textYPadding = 12;
    /// 文本最大宽度
    CGFloat maxTitleLabelWidth = CGRectGetWidth(self.frame) - textLeftPadding - textRightPadding - bubbleXPadding * 2;

    CGSize textSize = [self.titleLabel sizeThatFits:CGSizeMake(maxTitleLabelWidth, MAXFLOAT)];
    self.bubbleView.frame = CGRectMake(bubbleXPadding, 0, CGRectGetWidth(self.frame) - bubbleXPadding * 2, textSize.height + textYPadding * 2);
    self.gradientLayer.frame = self.bubbleView.bounds;
    self.titleLabel.frame = CGRectMake(textLeftPadding, textYPadding, maxTitleLabelWidth, textSize.height);
    self.selectedImageView.frame = CGRectMake(CGRectGetWidth(self.bubbleView.frame) - 12 - 18, CGRectGetHeight(self.bubbleView.frame) / 2 - 9, 18, 18);
}

#pragma mark - [ Private Method ]

- (void)initUI {
    [self.contentView addSubview:self.bubbleView];
    [self.bubbleView addSubview:self.titleLabel];
    [self.bubbleView addSubview:self.selectedImageView];
}

#pragma mark Getter & Setter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:16];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"未知公司名称";
    }
    return _titleLabel;
}

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.layer.masksToBounds = YES;
        _bubbleView.layer.cornerRadius = 8;
        _bubbleView.backgroundColor = PLV_UIColorFromRGB(@"#2D3452");
        [_bubbleView.layer insertSublayer:self.gradientLayer atIndex:0];
    }
    return _bubbleView;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)PLV_UIColorFromRGB(@"#00B16C").CGColor, (__bridge id)PLV_UIColorFromRGB(@"#00E78D").CGColor];
        _gradientLayer.locations = @[@0.5, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
        _gradientLayer.hidden = YES;
    }
    return _gradientLayer;
}

- (UIImageView *)selectedImageView {
    if (!_selectedImageView) {
        _selectedImageView = [[UIImageView alloc] initWithImage:
                              [PLVHCDemoUtils imageForHiClassResource:@"plvhc_btn_normal"]];
    }
    return _selectedImageView;
}

#pragma mark - [ Override ]

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    self.gradientLayer.hidden = !selected;
    NSString *imageName = selected ? @"plvhc_btn_selected": @"plvhc_btn_normal";
    self.selectedImageView.image = [PLVHCDemoUtils imageForHiClassResource:imageName];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *touchView = [super hitTest:point withEvent:event];
    if (touchView == self.bubbleView) {
        return touchView;
    } else {
        return nil;
    }
}

#pragma mark - [ Public Method ]

- (void)setCompanyName:(NSString *)companyName {
    NSString *titleString = [PLVFdUtil checkStringUseable:companyName] ? companyName : @"未知公司名称";
    self.titleLabel.text = titleString;
}

#pragma mark 高度计算

+ (CGFloat)cellHeightWithText:(NSString *)text cellWidth:(CGFloat)cellWidth {
    if (![PLVFdUtil checkStringUseable:text]) {
        text = @"未知公司名称";
    }
    /// 气泡相对Cell左右边距
    CGFloat bubbleXPadding = 18;
    /// 文本相对气泡的左边距
    CGFloat textLeftPadding = 16;
    /// 文本相对气泡的右边距
    CGFloat textRightPadding = 64;
    /// 文本相对气泡的上下边距
    CGFloat textYPadding = 12;
    /// 文本最大宽度
    CGFloat maxTitleLabelWidth = cellWidth - textLeftPadding - textRightPadding - bubbleXPadding * 2;
    /// Cell之间的边距
    CGFloat cellYPadding = 16;

    CGFloat titLabelHeight = [text boundingRectWithSize:CGSizeMake(maxTitleLabelWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : [UIFont fontWithName:@"PingFangSC-Regular" size:16]} context:nil].size.height;
    CGFloat bubbleHeight = titLabelHeight + textYPadding * 2;
     
    return bubbleHeight + cellYPadding;
}

@end
