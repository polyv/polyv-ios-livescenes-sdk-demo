//
//  PLVSAChannelInfoSheet.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/25.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAChannelInfoSheet.h"

// utils
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"

//Modules
#import "PLVRoomDataManager.h"

//SDK
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>



@interface PLVSAChannelInfoSheet()

// UI
@property (nonatomic, strong) UILabel *sheetTitleLabel; // 弹层顶部标题
@property (nonatomic, strong) UILabel *liveTitleLabel; // 直播名称标题
@property (nonatomic, strong) UILabel *liveTitleContentLabel; // 直播名称内容
@property (nonatomic, strong) UILabel *beginTimeTitleLabel; // 开始时间标题
@property (nonatomic, strong) UILabel *beginTimeContentLabel; // 开始时间内容
@property (nonatomic, strong) UILabel *channelIdTitleLabel; // 频道号标题
@property (nonatomic, strong) UILabel *channelIdContentLabel; // 频道号内容
@property (nonatomic, strong) UIButton *cloneChannelIdButton; // 复制频道号按钮
@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation PLVSAChannelInfoSheet


#pragma mark - [ Life Cycle ]


- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth {
    self = [super initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
    if (self) {
        [self.contentView addSubview:self.sheetTitleLabel];
        [self.contentView addSubview:self.scrollView];
        [self.scrollView addSubview:self.liveTitleLabel];
        [self.scrollView addSubview:self.liveTitleContentLabel];
        [self.scrollView addSubview:self.beginTimeTitleLabel];
        [self.scrollView addSubview:self.beginTimeContentLabel];
        [self.scrollView addSubview:self.channelIdTitleLabel];
        [self.scrollView addSubview:self.channelIdContentLabel];
        [self.scrollView addSubview:self.cloneChannelIdButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    
    CGFloat margin = isPad ? 56 : 30;
    CGFloat xPadding = (self.bounds.size.height > 667 || isLandscape) ? 34 : 17;
    CGFloat width = isLandscape ? self.sheetLandscapeWidth : self.bounds.size.width;
    width -= margin * 2;
    

    self.sheetTitleLabel.frame = CGRectMake(margin, xPadding, width, 20);
    
    self.scrollView.frame = CGRectMake(0, CGRectGetMaxY(self.sheetTitleLabel.frame), CGRectGetWidth(self.contentView.frame), CGRectGetHeight(self.contentView.frame) - CGRectGetMaxY(self.sheetTitleLabel.frame));
    CGSize size = [self.liveTitleLabel sizeThatFits:CGSizeMake(width, 20)];
    self.liveTitleLabel.frame = CGRectMake(margin, 22, size.width, size.height);
    
    CGFloat contentLabelX = isLandscape ? self.liveTitleLabel.frame.origin.x : CGRectGetMaxX(self.liveTitleLabel.frame);
    CGFloat contentLabelY = isLandscape ? CGRectGetMaxY(self.liveTitleLabel.frame) + 6 : self.liveTitleLabel.frame.origin.y;
    CGFloat maxWidth = isLandscape ? width : width - self.liveTitleLabel.frame.size.width;
    CGSize titleContentSize = [self.liveTitleContentLabel sizeThatFits:CGSizeMake(maxWidth, CGFLOAT_MAX)];
    self.liveTitleContentLabel.frame = CGRectMake(contentLabelX, contentLabelY, titleContentSize.width, titleContentSize.height);
  
    CGFloat labelBottomMargin = isLandscape ? 22 : 12;
    size = [self.beginTimeTitleLabel sizeThatFits:CGSizeMake(width, 20)];
    self.beginTimeTitleLabel.frame = CGRectMake(margin, CGRectGetMaxY(self.liveTitleContentLabel.frame) + labelBottomMargin, size.width, size.height);
    contentLabelX = isLandscape ? self.beginTimeTitleLabel.frame.origin.x : CGRectGetMaxX(self.beginTimeTitleLabel.frame);
    contentLabelY = isLandscape ? CGRectGetMaxY(self.beginTimeTitleLabel.frame) + 6 : self.beginTimeTitleLabel.frame.origin.y;
    maxWidth = isLandscape ? width : width - self.beginTimeTitleLabel.frame.size.width;
    self.beginTimeContentLabel.frame = CGRectMake(contentLabelX, contentLabelY, maxWidth, size.height);
    
    
    CGFloat buttonWidth = isPad ? 80 : 50;
    labelBottomMargin = isLandscape ? 22 : 16;
    size = [self.channelIdTitleLabel sizeThatFits:CGSizeMake(width, 20)];
    self.channelIdTitleLabel.frame = CGRectMake(margin, CGRectGetMaxY(self.beginTimeContentLabel.frame) + labelBottomMargin, size.width, size.height);
    contentLabelX = isLandscape ? self.channelIdTitleLabel.frame.origin.x : CGRectGetMaxX(self.channelIdTitleLabel.frame);
    contentLabelY = isLandscape ? CGRectGetMaxY(self.channelIdTitleLabel.frame) + 6 : self.channelIdTitleLabel.frame.origin.y;
    maxWidth = isLandscape ? width : width - self.channelIdTitleLabel.frame.size.width - buttonWidth;
    size = [self.channelIdContentLabel sizeThatFits:CGSizeMake(maxWidth, 20)];
    self.channelIdContentLabel.frame = CGRectMake(contentLabelX, contentLabelY, size.width, size.height);
    
    
    self.cloneChannelIdButton.frame = CGRectMake(CGRectGetMaxX(self.channelIdContentLabel.frame) + 12, self.channelIdTitleLabel.frame.origin.y - 2, buttonWidth, 24);
    self.cloneChannelIdButton.center = CGPointMake(self.cloneChannelIdButton.center.x, self.channelIdContentLabel.center.y);
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.bounds), CGRectGetMaxY(self.channelIdContentLabel.frame) + 12);
}

#pragma mark - [ Override ]

- (void)deviceOrientationDidChange {
    [super deviceOrientationDidChange];
    [self setNeedsLayout];
}

#pragma mark - [ Public Method ]

- (void)updateChannelInfoWithData:(PLVRoomData *)roomData {
    if (!roomData ||
        ![roomData isKindOfClass:[PLVRoomData class]]) {
        return;
    }
    
    NSString *titleString = roomData.channelName;
    if (![PLVFdUtil checkStringUseable:titleString]) {
        titleString = @"";
    }
        
    NSString *dateString = roomData.menuInfo.startTime;
    if (![PLVFdUtil checkStringUseable:dateString]) {
        dateString = PLVLocalizedString(@"无");
    }
    
    NSString *channelIdString = roomData.channelId;
    if (![PLVFdUtil checkStringUseable:channelIdString]) {
        channelIdString = PLVLocalizedString(@"无");
    }
    self.liveTitleContentLabel.text = titleString;
    self.beginTimeContentLabel.text = dateString;
    self.channelIdContentLabel.text = channelIdString;
}

#pragma mark - [ Private Method ]

- (NSMutableAttributedString *)createAttributedStringWithTitle:(NSString *)title content:(NSString *)content {
    NSMutableAttributedString *attrM = [[NSMutableAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:PLV_UIColorFromRGB(@"#AFAFAF"), NSFontAttributeName:[UIFont systemFontOfSize:14]}];
    
    NSAttributedString *attrContent = [[NSMutableAttributedString alloc] initWithString:content attributes:@{NSForegroundColorAttributeName:PLV_UIColorFromRGB(@"#F0F1F5"), NSFontAttributeName:[UIFont systemFontOfSize:14]}];
    
    [attrM appendAttributedString:attrContent];
    return attrM;
}

#pragma mark Getter & Setter
- (UILabel *)sheetTitleLabel {
    if (!_sheetTitleLabel) {
        _sheetTitleLabel = [[UILabel alloc] init];
        _sheetTitleLabel.font = [UIFont systemFontOfSize:18];
        _sheetTitleLabel.text = PLVLocalizedString(@"频道信息");
        _sheetTitleLabel.textColor = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:1/1.0];
    }
    return _sheetTitleLabel;
}

- (UILabel *)liveTitleLabel {
    if (!_liveTitleLabel) {
        _liveTitleLabel = [[UILabel alloc] init];
        _liveTitleLabel.font = [UIFont systemFontOfSize:14];
        _liveTitleLabel.textColor = PLV_UIColorFromRGB(@"#AFAFAF");
        _liveTitleLabel.text = PLVLocalizedString(@"直播名称：");
    }
    return _liveTitleLabel;
}

- (UILabel *)liveTitleContentLabel {
    if (!_liveTitleContentLabel) {
        _liveTitleContentLabel = [[UILabel alloc] init];
        _liveTitleContentLabel.font = [UIFont systemFontOfSize:14];
        _liveTitleContentLabel.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _liveTitleContentLabel.numberOfLines = 0;
    }
    return _liveTitleContentLabel;
}

- (UILabel *)beginTimeTitleLabel {
    if (!_beginTimeTitleLabel) {
        _beginTimeTitleLabel = [[UILabel alloc] init];
        _beginTimeTitleLabel.font = [UIFont systemFontOfSize:14];
        _beginTimeTitleLabel.textColor = PLV_UIColorFromRGBA(@"#F0F1F5", 0.6);
        _beginTimeTitleLabel.text = PLVLocalizedString(@"开始时间：");
    }
    return _beginTimeTitleLabel;
}

- (UILabel *)beginTimeContentLabel {
    if (!_beginTimeContentLabel) {
        _beginTimeContentLabel = [[UILabel alloc] init];
        _beginTimeContentLabel.font = [UIFont systemFontOfSize:14];
        _beginTimeContentLabel.textColor = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:1/1.0];
        _beginTimeContentLabel.numberOfLines = 0;
    }
    return _beginTimeContentLabel;
}

- (UILabel *)channelIdTitleLabel {
    if (!_channelIdTitleLabel) {
        _channelIdTitleLabel = [[UILabel alloc] init];
        _channelIdTitleLabel.font = [UIFont systemFontOfSize:14];
        _channelIdTitleLabel.textColor = PLV_UIColorFromRGBA(@"#F0F1F5", 0.6);
        _channelIdTitleLabel.text = PLVLocalizedString(@"频道号：");
    }
    return _channelIdTitleLabel;
}

- (UILabel *)channelIdContentLabel {
    if (!_channelIdContentLabel) {
        _channelIdContentLabel = [[UILabel alloc] init];
        _channelIdContentLabel.font = [UIFont systemFontOfSize:14];
        _channelIdContentLabel.textColor = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:1/1.0];
        _channelIdContentLabel.numberOfLines = 0;
    }
    return _channelIdContentLabel;
}

- (UIButton *)cloneChannelIdButton {
    if (!_cloneChannelIdButton) {
        _cloneChannelIdButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cloneChannelIdButton.titleLabel.textColor = [UIColor whiteColor];
        _cloneChannelIdButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _cloneChannelIdButton.backgroundColor = [UIColor colorWithRed:0/255.0 green:128/255.0 blue:255/255.0 alpha:1/1.0];
        _cloneChannelIdButton.layer.cornerRadius = 12;
        [_cloneChannelIdButton setTitle:PLVLocalizedString(@"复制") forState:UIControlStateNormal];
        [_cloneChannelIdButton addTarget:self action:@selector(cloneChannelIdButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cloneChannelIdButton;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
    }
    return _scrollView;
}

#pragma mark - Event

#pragma mark Action

- (void)cloneChannelIdButtonAction {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [PLVRoomDataManager sharedManager].roomData.channelId;
    [PLVSAUtils showToastInHomeVCWithMessage:PLVLocalizedString(@"已复制")];
}

@end
