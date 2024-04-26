//
//  PLVLSMoreInfoSheet.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/4/24.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSMoreInfoSheet.h"
// 工具类
#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVRoomDataManager.h"
// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLSMoreInfoSheet()

@property (nonatomic, strong) UILabel *sheetTitleLabel; // 弹层顶部标题
@property (nonatomic, strong) UIView *titleSplitLine; // 标题底部分割线
@property (nonatomic, strong) UIButton *beautyButton; // 美颜按钮
@property (nonatomic, strong) UIButton *resolutionButton; // 清晰度按钮
@property (nonatomic, strong) UIButton *mixLayoutButton; // 混流布局按钮
@property (nonatomic, strong) UIButton *shareButton; // 分享按钮
@property (nonatomic, strong) UIButton *badNetworkButton; //  弱网处理按钮
@property (nonatomic, strong) UIView *buttonSplitLine; // 退出登录按钮顶部分割线
@property (nonatomic, strong) UILabel *logoutButtonLabel; // 退出登录按钮背后的文本
@property (nonatomic, strong) UIButton *logoutButton; // 退出登录按钮
@property (nonatomic, strong) NSArray *buttonArray;

@property (nonatomic, assign) CGFloat sheetWidth; // 父类数据
@end

@implementation PLVLSMoreInfoSheet

@synthesize sheetWidth = _sheetWidth;

#pragma mark - [ Life Cycle ]
- (instancetype)initWithSheetWidth:(CGFloat)sheetWidth {
    self = [super initWithSheetWidth:sheetWidth];
    if (self) {
        [self.contentView addSubview:self.sheetTitleLabel];
        [self.contentView addSubview:self.titleSplitLine];
        NSMutableArray *muButtonArray = [NSMutableArray array];
        if ([PLVRoomDataManager sharedManager].roomData.appBeautyEnabled) {
            [self.contentView addSubview:self.beautyButton];
            [muButtonArray addObject:self.beautyButton];
        }
        [self.contentView addSubview:self.resolutionButton];
        [muButtonArray addObject:self.resolutionButton];
        if ([self canShareLiveroom]) {
            [self.contentView addSubview:self.shareButton];
            [muButtonArray addObject:self.shareButton];
        }
        [self.contentView addSubview:self.badNetworkButton];
        [muButtonArray addObject:self.badNetworkButton];
        if ([self showMixLayoutButton]) {
            [self.contentView addSubview:self.mixLayoutButton];
            [muButtonArray addObject:self.mixLayoutButton];
        }
        [self.contentView addSubview:self.buttonSplitLine];
        [self.contentView addSubview:self.logoutButtonLabel];
        [self.contentView addSubview:self.logoutButton];
        
        self.buttonArray = [muButtonArray copy];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat originX = 16;
    CGFloat sheetTitleLabelTop = 14;
    CGFloat titleSplitLineTop = 44;
    CGFloat logoutButtonHeight = 48;
    
    if (isPad) {
        sheetTitleLabelTop += PLVLSUtils.safeTopPad;
        titleSplitLineTop += PLVLSUtils.safeTopPad;
        logoutButtonHeight = 60;
    }
    
    self.sheetTitleLabel.frame = CGRectMake(originX, sheetTitleLabelTop, self.sheetWidth - originX * 2, 22);
    self.titleSplitLine.frame = CGRectMake(originX, titleSplitLineTop, self.sheetWidth - originX * 2, 1);
    
    CGFloat buttonOriginX = originX;
    CGFloat buttonOriginY = CGRectGetMaxY(self.titleSplitLine.frame) + 24;
    CGFloat buttonWidth = 48.0;
    CGFloat buttonHeight = 53.0;
    int placeNum = isPad ? 5 : 4;
    CGFloat buttonPadding = MIN(ceil((self.sheetWidth - originX * 2 - buttonWidth * placeNum)/3.0), 28.0);
    CGFloat buttonYPadding = 16;
    
    for (int i = 0; i < self.buttonArray.count ; i++) {
        UIButton *button = self.buttonArray[i];
        if (i % placeNum == 0 && i != 0) { // 换行
            buttonOriginX = originX;
            buttonOriginY += buttonHeight + buttonYPadding;
        }
        button.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonWidth, buttonHeight);
        [self setButtonInsets:button];
        buttonOriginX += buttonWidth + buttonPadding;
    }
    
    self.buttonSplitLine.frame = CGRectMake(originX, self.bounds.size.height - logoutButtonHeight - 1, self.sheetWidth - originX * 2, 1);
    self.logoutButtonLabel.frame = CGRectMake(originX, self.bounds.size.height - logoutButtonHeight, self.sheetWidth - originX * 2, logoutButtonHeight);
    self.logoutButton.frame = CGRectMake(originX, self.bounds.size.height - logoutButtonHeight, self.sheetWidth - originX * 2, logoutButtonHeight);
}

#pragma mark - Override
- (void)showInView:(UIView *)parentView{
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat scale = isPad ? 0.43 : 0.44;
    self.sheetWidth = screenWidth * scale;
    [super showInView:parentView];
}

#pragma mark - [ Private Method ]

- (BOOL)canShareLiveroom {
    PLVRoomUserType userType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
    if ((userType == PLVRoomUserTypeTeacher || userType == PLVRoomUserTypeGuest) &&
        [PLVRoomDataManager sharedManager].roomData.menuInfo.pushSharingEnabled) {
        return YES;
    }
    return NO;
}

- (BOOL)showMixLayoutButton {
    return [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher;
}

#pragma mark Getter
- (UILabel *)sheetTitleLabel {
    if (!_sheetTitleLabel) {
        _sheetTitleLabel = [[UILabel alloc] init];
        _sheetTitleLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
        _sheetTitleLabel.font = [UIFont boldSystemFontOfSize:16];
        _sheetTitleLabel.text = PLVLocalizedString(@"更多");
    }
    return _sheetTitleLabel;
}

- (UIView *)titleSplitLine {
    if (!_titleSplitLine) {
        _titleSplitLine = [[UIView alloc] init];
        _titleSplitLine.backgroundColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:0.1];
    }
    return _titleSplitLine;
}

- (UIButton *)beautyButton {
    if (!_beautyButton) {
        _beautyButton = [self buttonWithTitle:PLVLocalizedString(@"美颜") NormalImageString:@"plvls_beauty_more" selectedImageString:@"plvls_beauty_more"];
        [_beautyButton addTarget:self action:@selector(beautyButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _beautyButton;
}

- (UIButton *)resolutionButton {
    if (!_resolutionButton) {
        _resolutionButton = [self buttonWithTitle:PLVLocalizedString(@"清晰度") NormalImageString:@"plvls_beauty_resolution" selectedImageString:@"plvls_beauty_resolution"];
        [_resolutionButton addTarget:self action:@selector(resolutionButtonAction) forControlEvents:UIControlEventTouchUpInside];
        }
    return _resolutionButton;
}

- (UIButton *)shareButton {
    if (!_shareButton) {
        _shareButton = [self buttonWithTitle:PLVLocalizedString(@"分享") NormalImageString:@"plvls_liveroom_share_btn" selectedImageString:@"plvls_liveroom_share_btn"];
        [_shareButton addTarget:self action:@selector(shareButtonAction) forControlEvents:UIControlEventTouchUpInside];
        }
    return _shareButton;
}

- (UIButton *)badNetworkButton {
    if (!_badNetworkButton) {
        _badNetworkButton = [self buttonWithTitle:PLVLocalizedString(@"弱网处理") NormalImageString:@"plvls_liveroom_badNetwork_switch_btn" selectedImageString:@"plvls_liveroom_badNetwork_switch_btn"];
        [_badNetworkButton addTarget:self action:@selector(badNetworkButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _badNetworkButton;
}

- (UIButton *)mixLayoutButton {
    if (!_mixLayoutButton) {
        _mixLayoutButton = [self buttonWithTitle:PLVLocalizedString(@"混流布局") NormalImageString:@"plvls_liveroom_mixLayout_btn" selectedImageString:@"plvls_liveroom_mixLayout_btn"];
        [_mixLayoutButton addTarget:self action:@selector(mixLayoutAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _mixLayoutButton;
}


- (UIView *)buttonSplitLine {
    if (!_buttonSplitLine) {
        _buttonSplitLine = [[UIView alloc] init];
        _buttonSplitLine.backgroundColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:0.1];
    }
    return _buttonSplitLine;
}

- (UILabel *)logoutButtonLabel {
    if (!_logoutButtonLabel) {
        _logoutButtonLabel = [[UILabel alloc] init];
        _logoutButtonLabel.textAlignment = NSTextAlignmentCenter;
        
        UIImage *image = [PLVLSUtils imageForStatusResource:@"plvls_status_exit_btn"];
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = image;
        NSAttributedString *iconAttributedString = [NSAttributedString attributedStringWithAttachment:attachment];
        attachment.bounds = CGRectMake(-1, -2, image.size.width, image.size.height);
        
        NSDictionary *attributedDict = @{NSFontAttributeName: [UIFont systemFontOfSize:14],
                                         NSForegroundColorAttributeName:[UIColor colorWithRed:0xff/255.0 green:0x63/255.0 blue:0x63/255.0 alpha:1]
        };
        NSAttributedString *textAttributedString = [[NSAttributedString alloc] initWithString:PLVLocalizedString(@" 退出登录") attributes:attributedDict];
        
        NSMutableAttributedString *muString = [[NSMutableAttributedString alloc] init];
        [muString appendAttributedString:iconAttributedString];
        [muString appendAttributedString:textAttributedString];
        _logoutButtonLabel.attributedText = [muString copy];
    }
    return _logoutButtonLabel;
}

- (UIButton *)logoutButton {
    if (!_logoutButton) {
        _logoutButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_logoutButton addTarget:self action:@selector(logoutButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _logoutButton;
}

#pragma mark 初始化button
- (UIButton *)buttonWithTitle:(NSString *)title NormalImageString:(NSString *)normalImageString selectedImageString:(NSString *)selectedImageString {
    UIButton *button = [[UIButton alloc] init];
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    button.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
    [button setTitleColor:PLV_UIColorFromRGBA(@"#F0F1F5",0.6) forState:UIControlStateNormal];
    
    [button setTitle:title forState:UIControlStateNormal];
    [button setImage: [PLVLSUtils imageForLiveroomResource:normalImageString] forState:UIControlStateNormal];
    [button setImage:[PLVLSUtils imageForLiveroomResource:selectedImageString] forState:UIControlStateSelected];
    
    return button;
}

- (void)setButtonInsets:(UIButton *)button {
        CGFloat padding = 10;
        CGFloat imageBottom = button.titleLabel.intrinsicContentSize.height;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            imageBottom += padding;
        }
        
        [button setTitleEdgeInsets:
               UIEdgeInsetsMake(button.frame.size.height/2 + padding,
                                -button.imageView.frame.size.width - 5,
                                0,
                                - 5)];
        [button setImageEdgeInsets:
                   UIEdgeInsetsMake(
                               0,
                               (button.frame.size.width-button.imageView.frame.size.width)/2,
                                imageBottom,
                               (button.frame.size.width-button.imageView.frame.size.width)/2)];
}

#pragma mark - [ Event ]
#pragma mark Action

- (void)beautyButtonAction {
    [self dismiss];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheetDidTapBeautyButton:)]) {
        [self.delegate moreInfoSheetDidTapBeautyButton:self];
    }
}

- (void)resolutionButtonAction {
    [self dismiss];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheetDidTapResolutionButton:)]) {
        [self.delegate moreInfoSheetDidTapResolutionButton:self];
    }
}

- (void)shareButtonAction {
    [self dismiss];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheetDidTapShareButton:)]) {
        [self.delegate moreInfoSheetDidTapShareButton:self];
    }
}

- (void)logoutButtonAction {
    [self dismiss];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheetDidTapLogoutButton:)]) {
        [self.delegate moreInfoSheetDidTapLogoutButton:self];
    }
}

- (void)badNetworkButtonAction {
    [self dismiss];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheetDidBadNetworkButton:)]) {
        [self.delegate moreInfoSheetDidBadNetworkButton:self];
    }
}

- (void)mixLayoutAction {
    [self dismiss];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheetDidTapMixLayoutButton:)]) {
        [self.delegate moreInfoSheetDidTapMixLayoutButton:self];
    }
}

@end
