//
//  PLVSABroadcastLayoutSwitchSheet.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2023/9/18.
//  Copyright © 2023 PLV. All rights reserved.
//

#import "PLVSABroadcastLayoutSwitchSheet.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"

@interface PLVSABroadcastLayoutSwitchSheet()

// UI
@property (nonatomic, strong) UILabel *titleLabel;

// 选项按钮数组，只初始化一次
@property (nonatomic, strong) NSArray <UIButton *> *optionsButtonArray;

@end

@implementation PLVSABroadcastLayoutSwitchSheet

#pragma mark - [ Life Cycle ]
- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth {
    self = [super initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
    if (self) {
        [self initUI];
    }
    return self;
}

- (void)initUI {
    [self.contentView addSubview:self.titleLabel];
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    CGFloat titleLabelLeft = 32;
    CGFloat buttonWidth = isLandscape ? 110 : 128;
    CGFloat buttonHeight = isLandscape ? 87 : 97;
    CGFloat buttonY = isLandscape ? 16 : 20;
    CGFloat contentViewWidth = self.contentView.bounds.size.width;
    CGFloat paddingX = isLandscape ? (contentViewWidth - 2 * buttonWidth) / 5 : (contentViewWidth - 2 * buttonWidth) / 3;
    // 横屏时的两边边距
    CGFloat margin = paddingX * 2;
    // iPad时的中间边距
    CGFloat middlePadding = 0;
    if (isPad) {
        titleLabelLeft = 56;
        buttonWidth = 128;
        buttonHeight = 97;
        middlePadding = contentViewWidth * 0.052;
        CGFloat middlePadding = contentViewWidth * 0.052;
        margin = (contentViewWidth - middlePadding * (self.optionsButtonArray.count - 1) - buttonWidth * self.optionsButtonArray.count) / 2;
        if (isLandscape) {
            margin = (contentViewWidth - middlePadding * (self.optionsButtonArray.count - 1) - buttonWidth * self.optionsButtonArray.count / 2) / 2;
        }
    }
    self.titleLabel.frame = CGRectMake(titleLabelLeft, 32, 90, 18);
    CGFloat buttonOriginX = isLandscape ? margin : (isPad ? 56.0 : paddingX);
    CGFloat buttonOriginY =  (self.bounds.size.height > 667 || isLandscape) ? CGRectGetMaxY(self.titleLabel.frame) + 20 : CGRectGetMaxY(self.titleLabel.frame) + 16;
    
    for (int i = 0; i < self.optionsButtonArray.count ; i++) {
        UIButton *button = self.optionsButtonArray[i];
        
        if (isPad && !isLandscape) {
            buttonOriginX = (i * buttonWidth) + margin + (i * middlePadding);
        } else if (i % 2 == 0 && i != 0) { // 换行
            buttonOriginX = isLandscape ? margin : paddingX;
            buttonOriginY += buttonHeight + buttonY;
        }
        
        button.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonWidth, buttonHeight);
        buttonOriginX += buttonWidth + paddingX;
        
        // 调整图标样式
        CGFloat padding = button.imageView.frame.size.height / 2;
        CGFloat imageBottom = button.titleLabel.intrinsicContentSize.height;

        [button setTitleEdgeInsets:
               UIEdgeInsetsMake(button.frame.size.height/2 + padding,
                                -button.imageView.frame.size.width,
                                0,
                                0)];
        [button setImageEdgeInsets:
                   UIEdgeInsetsMake(
                               0,
                               (button.frame.size.width-button.imageView.frame.size.width) / 2,
                                imageBottom,
                               (button.frame.size.width-button.imageView.frame.size.width) / 2)];
    }
}

#pragma mark Public Method

- (void)setupBroadcastLayoutTypeOptionsWithCurrentBroadcastLayoutType:(PLVBroadcastLayoutType)currentType {
    for (UIButton *button in self.optionsButtonArray) {
        button.selected = NO;
        if(button.tag == currentType) {
            button.selected = YES;
        }
    }
}

#pragma mark Getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:18];
        _titleLabel.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _titleLabel.text = PLVLocalizedString(@"转播布局");
    }
    return _titleLabel;
}

- (NSArray <UIButton *> *)optionsButtonArray {
    if (!_optionsButtonArray) {
        NSMutableArray *buttonMuArray = [[NSMutableArray alloc] initWithCapacity:4];
        UIButton *topLeftButton = [self createButtonWithBroadcastLayoutType:PLVBroadcastLayoutType_TopLeft];
        [buttonMuArray addObject:topLeftButton];
        [self.contentView addSubview:topLeftButton];
        UIButton *topRightButton = [self createButtonWithBroadcastLayoutType:PLVBroadcastLayoutType_TopRight];
        [buttonMuArray addObject:topRightButton];
        [self.contentView addSubview:topRightButton];
        UIButton *bottomLeftButton = [self createButtonWithBroadcastLayoutType:PLVBroadcastLayoutType_BottomLeft];
        [buttonMuArray addObject:bottomLeftButton];
        [self.contentView addSubview:bottomLeftButton];
        UIButton *bottomRightButton = [self createButtonWithBroadcastLayoutType:PLVBroadcastLayoutType_BottomRight];
        [buttonMuArray addObject:bottomRightButton];
        [self.contentView addSubview:bottomRightButton];
        _optionsButtonArray = [buttonMuArray copy];
    }
    return _optionsButtonArray;
}


- (UIButton *)createButtonWithBroadcastLayoutType:(PLVBroadcastLayoutType)type {
    UIButton *button = [[UIButton alloc] init];
//    button.frame = CGRectMake(0, 0, 70, 64);
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.tag = type;
    [button addTarget:self action:@selector(broadcastLayoutButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    switch (type) {
        case PLVBroadcastLayoutType_BottomRight:
            [button setTitle:PLVLocalizedString(@"右下角") forState:UIControlStateNormal];
            [button setTitle:PLVLocalizedString(@"右下角") forState:UIControlStateSelected];
            button.selected = YES;
            break;
        case PLVBroadcastLayoutType_BottomLeft:
            [button setTitle:PLVLocalizedString(@"左下角") forState:UIControlStateNormal];
            [button setTitle:PLVLocalizedString(@"左下角") forState:UIControlStateSelected];
            break;
        case PLVBroadcastLayoutType_TopRight:
            [button setTitle:PLVLocalizedString(@"右上角") forState:UIControlStateNormal];
            [button setTitle:PLVLocalizedString(@"右上角") forState:UIControlStateSelected];
            break;
        case PLVBroadcastLayoutType_TopLeft:
            [button setTitle:PLVLocalizedString(@"左上角") forState:UIControlStateNormal];
            [button setTitle:PLVLocalizedString(@"左上角") forState:UIControlStateSelected];
            break;
    }
    button.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
    [button setTitleColor:PLV_UIColorFromRGB(@"#F0F1F5") forState:UIControlStateNormal];
    [button setTitleColor:PLV_UIColorFromRGB(@"#86B7FF") forState:UIControlStateSelected];
    [button setImage:[self createImageWithButtonWithBroadcastLayoutType:type selected:NO] forState:UIControlStateNormal];
    [button setImage:[self createImageWithButtonWithBroadcastLayoutType:type selected:YES] forState:UIControlStateSelected];
    return button;
}

- (UIImage *)createImageWithButtonWithBroadcastLayoutType:(PLVBroadcastLayoutType)type selected:(BOOL)selected {
    CGSize imageSize = CGSizeMake(128, 72);
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
    
    NSString *rgbString = selected ? @"#3E95FF" : @"#FFFFFF";
    
    // 绘制大矩形
    CGRect bigRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
    CGFloat bigCornerRadius = 8.0;

    CGContextSetFillColorWithColor(context, PLV_UIColorFromRGBA(rgbString, 0.12).CGColor);
    CGContextAddPath(context, [UIBezierPath bezierPathWithRoundedRect:bigRect cornerRadius:bigCornerRadius].CGPath);
    CGContextFillPath(context);
    if (selected) {
        CGContextSetStrokeColorWithColor(context, PLV_UIColorFromRGB(rgbString).CGColor);
        CGContextSetLineWidth(context, 0.5);
        CGContextAddPath(context, [UIBezierPath bezierPathWithRoundedRect:CGRectInset(bigRect, 0.5, 0.5) cornerRadius:bigCornerRadius].CGPath);
        CGContextStrokePath(context);
    }
    
    CGPoint point;
    
    switch(type) {
        case PLVBroadcastLayoutType_BottomRight:
            point = CGPointMake(71, 37);
            break;
        case PLVBroadcastLayoutType_BottomLeft:
            point = CGPointMake(8, 37);
            break;
        case PLVBroadcastLayoutType_TopRight:
            point = CGPointMake(71, 8);
            break;
        case PLVBroadcastLayoutType_TopLeft:
            point = CGPointMake(8, 8);
            break;
    }
    
    // 绘制小矩形
    CGRect smallRect = CGRectMake(point.x, point.y, 49, 27);
    CGFloat smallCornerRadius = 4.0;
    CGContextSetFillColorWithColor(context, PLV_UIColorFromRGBA(rgbString, 0.6).CGColor);
    CGContextAddPath(context, [UIBezierPath bezierPathWithRoundedRect:smallRect cornerRadius:smallCornerRadius].CGPath);
    CGContextFillPath(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)broadcastLayoutButtonAction:(UIButton *)sender {
    for (UIButton *button in self.optionsButtonArray) {
        button.selected = NO;
    }
    sender.selected = YES;
    [PLVSAUtils showToastWithMessage:[NSString stringWithFormat:PLVLocalizedString(@"已切换为%@"), sender.titleLabel.text] inView:[PLVSAUtils sharedUtils].homeVC.view];
    [self dismiss];
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvsaBroadcastLayoutSwitchSheet:broadcastLayoutButtonClickWithMixLayoutType:)]) {
        PLVBroadcastLayoutType type = sender.tag;
        [self.delegate plvsaBroadcastLayoutSwitchSheet:self broadcastLayoutButtonClickWithMixLayoutType:type];
    }
}

@end
