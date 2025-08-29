//
//  PLVStickerTypeSelectionView.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2023/9/15.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVStickerTypeSelectionView.h"
#import <PLVFoundationSDK/PLVColorUtil.h>
#import "PLVMultiLanguageManager.h"
#import "PLVSAUtils.h"

@interface PLVStickerTypeSelectionView ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *textButton;
@property (nonatomic, strong) UIButton *imageButton;
@property (nonatomic, strong) CAShapeLayer *separatorLine;

@end

@implementation PLVStickerTypeSelectionView

#pragma mark - Life Cycle

- (instancetype)init {
    return [self initWithSheetHeight:240];
}

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth{
    self = [super initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
    if (self) {
        [self setupUI];
    }
    return self;
}

#pragma mark - UI Setup

- (void)setupUI {
    // 设置圆角和背景色
    [self setSheetCornerRadius:16];
    self.contentView.backgroundColor = [PLVColorUtil colorFromHexString:@"#2B2C35"];
    
    // 添加视图
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.textButton];
    [self.contentView addSubview:self.imageButton];
    [self.contentView.layer addSublayer:self.separatorLine];
    
    // 设置关闭回调
    __weak typeof(self) weakSelf = self;
    self.didCloseSheet = ^{
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(stickerTypeSelectionViewDidCancel:)]) {
            [weakSelf.delegate stickerTypeSelectionViewDidCancel:weakSelf];
        }
    };
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat contentWidth = self.contentView.bounds.size.width;
    CGFloat buttonHeight = 48;
    CGFloat sideMargin = 16;
    CGFloat buttonWidth = contentWidth - sideMargin * 2;
    
    // 标题布局
    self.titleLabel.frame = CGRectMake(sideMargin, 20, buttonWidth, 22);
    
    // 文字贴图按钮布局
    self.textButton.frame = CGRectMake(sideMargin, CGRectGetMaxY(self.titleLabel.frame) + 20, buttonWidth, buttonHeight);
    
    // 图片贴图按钮布局
    self.imageButton.frame = CGRectMake(sideMargin, CGRectGetMaxY(self.textButton.frame) + 12, buttonWidth, buttonHeight);
    
    // 分割线布局
    CGFloat separatorY = CGRectGetMaxY(self.imageButton.frame) + 20;
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(sideMargin, separatorY)];
    [path addLineToPoint:CGPointMake(contentWidth - sideMargin, separatorY)];
    self.separatorLine.path = path.CGPath;
}

#pragma mark - Actions

- (void)textButtonAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerTypeSelectionView:didSelectType:)]) {
        [self.delegate stickerTypeSelectionView:self didSelectType:PLVStickerTypeText];
    }
    [self dismiss];
}

- (void)imageButtonAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerTypeSelectionView:didSelectType:)]) {
        [self.delegate stickerTypeSelectionView:self didSelectType:PLVStickerTypeImage];
    }
    [self dismiss];
}

#pragma mark - Getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = PLVLocalizedString(@"贴图");
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        _titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0.8];
    }
    return _titleLabel;
}

- (UIButton *)textButton {
    if (!_textButton) {
        _textButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_textButton setTitle:PLVLocalizedString(@"文字") forState:UIControlStateNormal];
        [_textButton setTitleColor:[PLVColorUtil colorFromHexString:@"#F0F1F5"] forState:UIControlStateNormal];
        _textButton.titleLabel.font = [UIFont systemFontOfSize:16];
        _textButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#46474E"];
        _textButton.layer.cornerRadius = 8;
        [_textButton addTarget:self action:@selector(textButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _textButton;
}

- (UIButton *)imageButton {
    if (!_imageButton) {
        _imageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_imageButton setTitle:PLVLocalizedString(@"手机相册图片") forState:UIControlStateNormal];
        [_imageButton setTitleColor:[PLVColorUtil colorFromHexString:@"#F0F1F5"] forState:UIControlStateNormal];
        _imageButton.titleLabel.font = [UIFont systemFontOfSize:16];
        _imageButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#46474E"];
        _imageButton.layer.cornerRadius = 8;
        [_imageButton addTarget:self action:@selector(imageButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _imageButton;
}

- (CAShapeLayer *)separatorLine {
    if (!_separatorLine) {
        _separatorLine = [CAShapeLayer layer];
        _separatorLine.strokeColor = [PLVColorUtil colorFromHexString:@"#FFFFFF" alpha:0.2].CGColor;
        _separatorLine.lineWidth = 1;
        _separatorLine.lineDashPattern = @[@4, @4];
    }
    return _separatorLine;
}

@end 
