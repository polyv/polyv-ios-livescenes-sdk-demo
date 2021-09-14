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
@property (nonatomic, strong) UILabel *beginTimeLabel; // 开始时间
@property (nonatomic, strong) UILabel *channelIdLabel; // 频道号
@property (nonatomic, strong) UIButton *cloneChannelIdButton; // 复制频道号按钮

@end

@implementation PLVSAChannelInfoSheet


#pragma mark - [ Life Cycle ]

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight {
    self = [super initWithSheetHeight:sheetHeight];
    if (self) {
        [self.contentView addSubview:self.sheetTitleLabel];
        [self.contentView addSubview:self.liveTitleLabel];
        [self.contentView addSubview:self.liveTitleContentLabel];
        [self.contentView addSubview:self.beginTimeLabel];
        [self.contentView addSubview:self.channelIdLabel];
        [self.contentView addSubview:self.cloneChannelIdButton];
    }
    return self;
}


#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat margin = 30;
    CGFloat xPadding = self.bounds.size.height > 667 ? 34 : 17;
    CGFloat width = self.bounds.size.width - margin * 2;
    
    CGSize titleContentSize = [self.liveTitleContentLabel sizeThatFits:CGSizeMake(width - 50, CGFLOAT_MAX)];
    if (titleContentSize.height <= 17) {
        xPadding = 34;
    }
    self.sheetTitleLabel.frame = CGRectMake(margin, xPadding, width, 20);
    
    CGSize size = [self.liveTitleLabel sizeThatFits:CGSizeMake(width, 20)];
    self.liveTitleLabel.frame = CGRectMake(margin, CGRectGetMaxY(self.sheetTitleLabel.frame) + 22, size.width, size.height);
    
    
    self.liveTitleContentLabel.frame = CGRectMake(CGRectGetMaxX(self.liveTitleLabel.frame), self.liveTitleLabel.frame.origin.y, titleContentSize.width, titleContentSize.height);
  
    self.beginTimeLabel.frame = CGRectMake(margin, CGRectGetMaxY(self.liveTitleContentLabel.frame) + 12, width, 20);
    
    size = [self.channelIdLabel sizeThatFits:CGSizeMake(width, 20)];
    self.channelIdLabel.frame = CGRectMake(margin, CGRectGetMaxY(self.beginTimeLabel.frame) + 16, size.width, size.height);
    
    self.cloneChannelIdButton.frame = CGRectMake(CGRectGetMaxX(self.channelIdLabel.frame) + 12, self.channelIdLabel.frame.origin.y - 2, 50, 24);
    self.cloneChannelIdButton.center = CGPointMake(self.cloneChannelIdButton.center.x, self.channelIdLabel.center.y);
}
#pragma mark - [ Public Method ]

- (void)updateChannelInfoWithData:(PLVRoomData *)roomData {
    if (!roomData ||
        ![roomData isKindOfClass:[PLVRoomData class]]) {
        return;
    }
    
    NSString *titleString = roomData.channelName;
    if (!titleString || ![titleString isKindOfClass:[NSString class]]) {
        titleString = @"";
    }
        
    NSString *dateString = roomData.menuInfo.startTime;
    
    if (!dateString || ![dateString isKindOfClass:[NSString class]] || dateString.length == 0) {
        dateString = @"无";
    }
    
    self.liveTitleLabel.text = @"直播名称：";
    self.liveTitleContentLabel.text = titleString;
    
    self.beginTimeLabel.attributedText = [self createAttributedStringWithTitle:@"开始时间：" content:dateString];
    self.channelIdLabel.attributedText = [self createAttributedStringWithTitle:@"频道号：" content:roomData.channelId];
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
        _sheetTitleLabel.text = @"频道信息";
        _sheetTitleLabel.textColor = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:1/1.0];
    }
    return _sheetTitleLabel;
}

- (UILabel *)liveTitleLabel {
    if (!_liveTitleLabel) {
        _liveTitleLabel = [[UILabel alloc] init];
        _liveTitleLabel.font = [UIFont systemFontOfSize:14];
        _liveTitleLabel.textColor = PLV_UIColorFromRGB(@"#AFAFAF");
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

- (UILabel *)beginTimeLabel {
    if (!_beginTimeLabel) {
        _beginTimeLabel = [[UILabel alloc] init];
        _beginTimeLabel.font = [UIFont systemFontOfSize:14];
        _beginTimeLabel.textColor = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:1/1.0];
    }
    return _beginTimeLabel;
}

- (UILabel *)channelIdLabel {
    if (!_channelIdLabel) {
        _channelIdLabel = [[UILabel alloc] init];
        _channelIdLabel.font = [UIFont systemFontOfSize:14];
        _channelIdLabel.textColor = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:1/1.0];
    }
    return _channelIdLabel;
}

- (UIButton *)cloneChannelIdButton {
    if (!_cloneChannelIdButton) {
        _cloneChannelIdButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cloneChannelIdButton.titleLabel.textColor = [UIColor whiteColor];
        _cloneChannelIdButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _cloneChannelIdButton.backgroundColor = [UIColor colorWithRed:0/255.0 green:128/255.0 blue:255/255.0 alpha:1/1.0];
        _cloneChannelIdButton.layer.cornerRadius = 12;
        [_cloneChannelIdButton setTitle:@"复制" forState:UIControlStateNormal];
        [_cloneChannelIdButton addTarget:self action:@selector(cloneChannelIdButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cloneChannelIdButton;
}

#pragma mark - Event

#pragma mark Action

- (void)cloneChannelIdButtonAction {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [PLVRoomDataManager sharedManager].roomData.channelId;
    [PLVSAUtils showToastInHomeVCWithMessage:@"已复制"];
}

@end
