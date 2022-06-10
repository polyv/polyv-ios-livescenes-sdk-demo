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
#import "PLVRoomDataManager.h"
// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLSMoreInfoSheet()

@property (nonatomic, strong) UILabel *sheetTitleLabel; // 弹层顶部标题
@property (nonatomic, strong) UIView *titleSplitLine; // 标题底部分割线
@property (nonatomic, strong) UIButton *beautyButton; // 美颜按钮
@property (nonatomic, strong) UIButton *resolutionButton; // 清晰度按钮
@property (nonatomic, strong) UIView *buttonSplitLine; // 退出登陆按钮顶部分割线
@property (nonatomic, strong) UILabel *logoutButtonLabel; // 退出登陆按钮背后的文本
@property (nonatomic, strong) UIButton *logoutButton; // 退出登陆按钮

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
        if ([PLVRoomDataManager sharedManager].roomData.appBeautyEnabled) {
            [self.contentView addSubview:self.beautyButton];
        }
        [self.contentView addSubview:self.resolutionButton];
        [self.contentView addSubview:self.buttonSplitLine];
        [self.contentView addSubview:self.logoutButtonLabel];
        [self.contentView addSubview:self.logoutButton];
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
    
    if ([PLVRoomDataManager sharedManager].roomData.appBeautyEnabled) {
        CGFloat beautyOriginY = CGRectGetMaxY(self.titleSplitLine.frame) + 24;
        self.beautyButton.frame = CGRectMake(originX, beautyOriginY, 48, 53);
        self.resolutionButton.frame = CGRectMake(CGRectGetMaxX(self.beautyButton.frame) + 28, beautyOriginY, 48, 53);
        [self setButtonInsets:self.beautyButton];
        [self setButtonInsets:self.resolutionButton];
    }
    else {
        self.resolutionButton.frame = CGRectMake(originX, CGRectGetMaxY(self.titleSplitLine.frame) + 24, 48, 53);
        [self setButtonInsets:self.resolutionButton];
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
#pragma mark Getter
- (UILabel *)sheetTitleLabel {
    if (!_sheetTitleLabel) {
        _sheetTitleLabel = [[UILabel alloc] init];
        _sheetTitleLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
        _sheetTitleLabel.font = [UIFont boldSystemFontOfSize:16];
        _sheetTitleLabel.text = @"更多";
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
        _beautyButton = [self buttonWithTitle:@"美颜" NormalImageString:@"plvls_beauty_more" selectedImageString:@"plvls_beauty_more"];
        [_beautyButton addTarget:self action:@selector(beautyButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _beautyButton;
}

- (UIButton *)resolutionButton {
    if (!_resolutionButton) {
        _resolutionButton = [self buttonWithTitle:@"清晰度" NormalImageString:@"plvls_beauty_resolution" selectedImageString:@"plvls_beauty_resolution"];
        [_resolutionButton addTarget:self action:@selector(resolutionButtonAction) forControlEvents:UIControlEventTouchUpInside];
        }
    return _resolutionButton;
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
        NSAttributedString *textAttributedString = [[NSAttributedString alloc] initWithString:@" 退出登录" attributes:attributedDict];
        
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
    [button setImage: [PLVLSUtils imageForBeautyResource:normalImageString] forState:UIControlStateNormal];
    [button setImage:[PLVLSUtils imageForBeautyResource:selectedImageString] forState:UIControlStateSelected];
    
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
                                -button.imageView.frame.size.width,
                                0,
                                0)];
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

- (void)logoutButtonAction {
    [self dismiss];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheetDidTapLogoutButton:)]) {
        [self.delegate moreInfoSheetDidTapLogoutButton:self];
    }
}

@end
