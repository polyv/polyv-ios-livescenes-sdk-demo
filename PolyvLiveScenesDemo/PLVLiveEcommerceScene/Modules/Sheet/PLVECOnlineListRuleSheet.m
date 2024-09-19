//
//  PLVECOnlineListRuleSheet.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/9/6.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVECOnlineListRuleSheet.h"
#import "PLVECUtils.h"
#import "PLVMultiLanguageManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVECOnlineListRuleSheet ()

// UI
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UILabel *titleLabel; // 基础功能标题
@property (nonatomic, strong) UILabel *firstTitleLabel;
@property (nonatomic, strong) UILabel *firstContentLabel;
@property (nonatomic, strong) UILabel *secondTitleLabel;
@property (nonatomic, strong) UILabel *secondContentLabel;

@end

@implementation PLVECOnlineListRuleSheet

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    CGFloat maxWH = MAX([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    CGFloat minWH = MIN([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    CGFloat sheetHeight = maxWH - minWH * 9 / 16 - [PLVECUtils sharedUtils].areaInsets.top;
    CGFloat sheetLandscapeWidth = minWH;
    self = [super initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
    if (self) {
        [self initUI];
    }
    return self;
}

- (void)initUI {
    [self.contentView addSubview:self.closeButton];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.firstTitleLabel];
    [self.contentView addSubview:self.firstContentLabel];
    [self.contentView addSubview:self.secondTitleLabel];
    [self.contentView addSubview:self.secondContentLabel];
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat titleLabelLeft =  isPad ? 32 : 16;
    CGFloat contentViewWidth = self.contentView.bounds.size.width;
    CGFloat originY = titleLabelLeft;
    
    self.closeButton.frame = CGRectMake(titleLabelLeft, originY, 20, 20);
    CGFloat titleLabelWidth = contentViewWidth - CGRectGetMaxX(self.closeButton.frame) * 2 - 8;
    self.titleLabel.frame = CGRectMake(CGRectGetMaxX(self.closeButton.frame) + 4, originY, titleLabelWidth, 22);
    originY += self.closeButton.frame.size.height + 28;
    
    self.firstTitleLabel.frame = CGRectMake(titleLabelLeft, originY, contentViewWidth - titleLabelLeft * 2, 22);
    originY += self.firstTitleLabel.frame.size.height + 12;
    
    CGFloat contentLabelWidth = contentViewWidth - titleLabelLeft * 2;
    CGSize maxSize = CGSizeMake(contentLabelWidth, CGFLOAT_MAX);
    CGFloat firstContentLabelHeight = [self.firstContentLabel.text boundingRectWithSize:maxSize
                                                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                                                  attributes:@{NSFontAttributeName: self.firstContentLabel.font}
                                                                                     context:nil].size.height;
    self.firstContentLabel.frame = CGRectMake(titleLabelLeft, originY, contentLabelWidth, firstContentLabelHeight);
    originY += firstContentLabelHeight + titleLabelLeft * 2;
    
    self.secondTitleLabel.frame = CGRectMake(titleLabelLeft, originY, contentViewWidth - titleLabelLeft * 2, 22);
    originY += self.firstTitleLabel.frame.size.height + 12;
    
    CGFloat secondContentLabelHeight = [self.secondContentLabel.text boundingRectWithSize:maxSize
                                                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                                                              attributes:@{NSFontAttributeName: self.secondContentLabel.font}
                                                                                 context:nil].size.height;
    self.secondContentLabel.frame = CGRectMake(titleLabelLeft, originY, contentLabelWidth, secondContentLabelHeight);
}

- (void)deviceOrientationDidChange {
    [self dismiss];
}

#pragma mark - Getter

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:[PLVECUtils imageForWatchResource:@"plvec_online_list_rule_close"] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = PLVLocalizedString(@"列表规则");
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = PLV_UIColorFromRGBA(@"#000000",0.8);
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16];
    }
    return _titleLabel;
}

- (UILabel *)firstTitleLabel{
    if (!_firstTitleLabel) {
        _firstTitleLabel = [[UILabel alloc] init];
        _firstTitleLabel.text = PLVLocalizedString(@"一、列表规则");
        _firstTitleLabel.textAlignment = NSTextAlignmentLeft;
        _firstTitleLabel.textColor = PLV_UIColorFromRGBA(@"#000000",0.8);
        _firstTitleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16];
    }
    return _firstTitleLabel;
}

- (UILabel *)firstContentLabel{
    if (!_firstContentLabel) {
        _firstContentLabel = [[UILabel alloc] init];
        _firstContentLabel.text = PLVLocalizedString(@"在线列表顺序将根据特殊角色>观众的优先级进行排序；观众顺序将根据进入直播间的先后时间进行排序，先进入直播间的观众将展示在前排。");
        _firstContentLabel.textAlignment = NSTextAlignmentLeft;
        _firstContentLabel.textColor = PLV_UIColorFromRGBA(@"#000000",0.6);
        _firstContentLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        _firstContentLabel.numberOfLines = 0;
    }
    return _firstContentLabel;
}

- (UILabel *)secondTitleLabel{
    if (!_secondTitleLabel) {
        _secondTitleLabel = [[UILabel alloc] init];
        _secondTitleLabel.text = PLVLocalizedString(@"二、特别提醒");
        _secondTitleLabel.textAlignment = NSTextAlignmentLeft;
        _secondTitleLabel.textColor = PLV_UIColorFromRGBA(@"#000000",0.8);
        _secondTitleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16];
    }
    return _secondTitleLabel;
}

- (UILabel *)secondContentLabel{
    if (!_secondContentLabel) {
        _secondContentLabel = [[UILabel alloc] init];
        _secondContentLabel.text = PLVLocalizedString(@"在线列表将会有短时间的缓存，可能会出现观众重新离开/进入直播间，列表未更新及时的现象，属于正常。");
        _secondContentLabel.textAlignment = NSTextAlignmentLeft;
        _secondContentLabel.textColor = PLV_UIColorFromRGBA(@"#000000",0.6);
        _secondContentLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        _secondContentLabel.numberOfLines = 0;
    }
    return _secondContentLabel;
}

#pragma mark - Action

- (void)closeButtonAction {
    [self dismiss];
}

@end
