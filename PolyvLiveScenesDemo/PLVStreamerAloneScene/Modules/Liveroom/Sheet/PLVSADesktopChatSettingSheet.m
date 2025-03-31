//
//  PLVSADesktopChatSettingSheet.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/3/20.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVSADesktopChatSettingSheet.h"
#import "PLVSADesktopChatSettingGuideViewController.h"
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVRoomDataManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSString *const PLVSADesktopChatGuideAttributeName = @"desktopChatGuide";

@interface PLVSADesktopChatSettingSheet () <UITextViewDelegate>

// UI
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UISwitch *desktopChatSwitch;
@property (nonatomic, strong) UITextView *textView;

@end

@implementation PLVSADesktopChatSettingSheet

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
    [self.contentView addSubview:self.desktopChatSwitch];
    [self.contentView addSubview:self.textView];
}

#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat left = 32;
    CGFloat padding = 16;
    CGFloat top = 35;
    
    CGSize textSize = [self.titleLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 18)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName: self.titleLabel.font}
                                                         context:nil].size;
    self.titleLabel.frame = CGRectMake(left, top, textSize.width, 18);
    self.desktopChatSwitch.frame = CGRectMake(CGRectGetMaxX(self.titleLabel.frame) + padding, 32, 38, 24);
    self.textView.frame = CGRectMake(left, CGRectGetMaxY(self.desktopChatSwitch.frame) + 24, self.bounds.size.width - left * 2, 100);
}

- (void)showInView:(UIView *)parentView {
    [super showInView:parentView];
    self.desktopChatSwitch.on = [PLVRoomDataManager sharedManager].roomData.desktopChatEnabled;
}

#pragma mark - [ Private Method ]

- (void)showDesktopChatGuide {
    PLVSADesktopChatSettingGuideViewController *vctrl = [[PLVSADesktopChatSettingGuideViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vctrl];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [[PLVSAUtils sharedUtils].homeVC presentViewController:nav animated:YES completion:nil];
}

#pragma mark Getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:18];
        _titleLabel.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _titleLabel.text = PLVLocalizedString(@"桌面消息");
    }
    return _titleLabel;
}

- (UISwitch *)desktopChatSwitch {
    if (!_desktopChatSwitch) {
        _desktopChatSwitch = [[UISwitch alloc] init];
        _desktopChatSwitch.onTintColor = [PLVColorUtil colorFromHexString:@"#4399FF"];
        _desktopChatSwitch.on = [PLVRoomDataManager sharedManager].roomData.desktopChatEnabled;
        [_desktopChatSwitch addTarget:self action:@selector(desktopChatSwitchAction) forControlEvents:UIControlEventValueChanged];
    }
    return _desktopChatSwitch;
}

- (UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc] init];
        _textView.backgroundColor = [UIColor clearColor];
        
        UIFont *font = [UIFont fontWithName:@"PingFangSC-Regular" size: 12];
        NSDictionary *normalAttributes = @{NSFontAttributeName:font,
                                              NSForegroundColorAttributeName:PLV_UIColorFromRGBA(@"#F0F1F5", 0.8)};
        NSDictionary *jumpAttributes = @{NSFontAttributeName:font,
                                                NSForegroundColorAttributeName:PLV_UIColorFromRGB(@"#4399FF"),
                                                NSLinkAttributeName: [NSString stringWithFormat:@"%@://", PLVSADesktopChatGuideAttributeName]};
        NSString *tipsString = PLVLocalizedString(@"仅限屏幕共享期间有效，需开启系统「自动开启画中画」权限");
        NSString *jumpString = PLVLocalizedString(@"查看引导");
        NSString *textViewString = [NSString stringWithFormat:@"%@ %@",tipsString, jumpString];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:textViewString];
        [attributedString addAttributes:normalAttributes range:NSMakeRange(0, tipsString.length)];
        [attributedString addAttributes:jumpAttributes range:NSMakeRange(tipsString.length + 1, jumpString.length)];
        _textView.linkTextAttributes = @{NSForegroundColorAttributeName: PLV_UIColorFromRGB(@"#4399FF")};
        _textView.attributedText = attributedString;
        _textView.delegate = self;
    }
    return _textView;
}

#pragma mark Setter

- (void)setDesktopChatEnable:(BOOL)desktopChatEnable {
    _desktopChatEnable = desktopChatEnable;
    if (self.desktopChatSwitch.on != desktopChatEnable) {
        self.desktopChatSwitch.on = desktopChatEnable;
    }
}

#pragma mark - [ Action ]

- (void)desktopChatSwitchAction {
    self.desktopChatEnable = self.desktopChatSwitch.on;
    if (self.delegate && [self.delegate respondsToSelector:@selector(desktopChatSettingSheet:didChangeDesktopChatEnable:)]) {
        [self.delegate desktopChatSettingSheet:self didChangeDesktopChatEnable:self.desktopChatSwitch.on];
    }
}

#pragma mark - [ Delegate ]

#pragma mark UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    if ([[URL scheme] isEqualToString:PLVSADesktopChatGuideAttributeName]) {
        [self showDesktopChatGuide];
    }
    
    return NO;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    return NO;
}

@end
