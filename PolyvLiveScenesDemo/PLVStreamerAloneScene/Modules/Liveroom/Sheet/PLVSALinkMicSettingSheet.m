//
//  PLVSALinkMicSettingSheet.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/4/9.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVSALinkMicSettingSheet.h"

#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVRoomDataManager.h"
#import <PLVFoundationSDK/PLVFdUtil.h>

@interface PLVSALinkMicSettingSheet ()

///UI
@property (nonatomic, strong) UILabel *sheetTitleLabel; // 弹层顶部标题
@property (nonatomic, strong) UILabel *optionTitleLabel; // 设置项顶部标题
@property (nonatomic, strong) UIButton *audioTypeButton; // 音频连麦按钮
@property (nonatomic, strong) UIButton *videoTypeButton; // 视频连麦按钮
@property (nonatomic, strong) UIView *selectedView; // 选中选项底下蓝色圆点
@property (nonatomic, strong) UILabel *optionNotesLabel; // 设置项底部备注
@property (nonatomic, strong) UILabel *sheetNotesLabel; // 弹层底部备注

/// 数据
@property (nonatomic, assign) BOOL linkMicOnAudio; // 默认值为YES
@property (nonatomic, strong) NSArray <UIButton *> *optionsButton;
@property (nonatomic, assign) NSInteger selectedTag; // 选中按钮，初始值为0

@end

@implementation PLVSALinkMicSettingSheet

#pragma mark - Life Cycle

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth {
    self = [super initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
    if (self) {
        self.linkMicOnAudio = [PLVRoomDataManager sharedManager].roomData.channelLinkMicMediaType != PLVChannelLinkMicMediaType_Video;
        [self initUI];
    }
    return self;
}

- (void)initUI {
    [self.contentView addSubview:self.sheetTitleLabel];
    [self.contentView addSubview:self.optionTitleLabel];
    [self.contentView addSubview:self.audioTypeButton];
    [self.contentView addSubview:self.videoTypeButton];
    [self.contentView addSubview:self.selectedView];
    [self.contentView addSubview:self.optionNotesLabel];
    [self.contentView addSubview:self.sheetNotesLabel];
}

#pragma mark - [ Override ]’

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat titleLabelLeft = 32;
    CGFloat contentViewWidth = self.contentView.bounds.size.width;
    CGFloat bottom = [PLVSAUtils sharedUtils].areaInsets.bottom;
    CGFloat right = [PLVSAUtils sharedUtils].areaInsets.right;
    
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    
    if (isPad) {
        titleLabelLeft = 56;
    }
    self.sheetTitleLabel.frame = CGRectMake(titleLabelLeft, titleLabelLeft, contentViewWidth - titleLabelLeft * 2, 18);
    self.optionTitleLabel.frame = CGRectMake(titleLabelLeft, CGRectGetMaxY(self.sheetTitleLabel.frame) + titleLabelLeft, contentViewWidth - titleLabelLeft - right, 17);
    UIFont *buttonFont = [UIFont fontWithName:@"PingFangSC-Medium" size:14];
    CGSize audioTypeButtonSize = [self.audioTypeButton.titleLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 17) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:buttonFont} context:nil].size;
    CGFloat buttonPadding = 8;
    self.audioTypeButton.frame = CGRectMake(titleLabelLeft, CGRectGetMaxY(self.optionTitleLabel.frame) + 12, audioTypeButtonSize.width + buttonPadding, 17);
    CGSize videoTypeButtonSize = [self.videoTypeButton.titleLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, 17) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:buttonFont} context:nil].size;
    self.videoTypeButton.frame = CGRectMake(CGRectGetMaxX(self.audioTypeButton.frame) + titleLabelLeft * 2, CGRectGetMinY(self.audioTypeButton.frame), videoTypeButtonSize.width + buttonPadding, 17);
    if (self.selectedTag == 0) {
        self.selectedView.frame = CGRectMake(CGRectGetMidX(self.audioTypeButton.frame) - 2, CGRectGetMaxY(self.audioTypeButton.frame) + 3, 4, 4);
    } else {
        self.selectedView.frame = CGRectMake(CGRectGetMidX(self.videoTypeButton.frame) - 2, CGRectGetMaxY(self.videoTypeButton.frame) + 3, 4, 4);
    }
    self.optionNotesLabel.frame = CGRectMake(titleLabelLeft, CGRectGetMaxY(self.selectedView.frame) + 6, contentViewWidth - titleLabelLeft - right, 17);
    self.sheetNotesLabel.frame = CGRectMake(titleLabelLeft, self.contentView.frame.size.height - 34 - bottom, contentViewWidth - titleLabelLeft - right, 34);
}

#pragma mark - Public

- (void)updateLinkMicType:(BOOL)linkMicOnAudio {
    if (self.linkMicOnAudio != linkMicOnAudio) {
        self.linkMicOnAudio = linkMicOnAudio;
        self.audioTypeButton.selected = linkMicOnAudio;
        self.videoTypeButton.selected = !linkMicOnAudio;
        if (self.selectedTag == 0) {
            self.selectedView.frame = CGRectMake(CGRectGetMidX(self.audioTypeButton.frame) - 2, CGRectGetMaxY(self.audioTypeButton.frame) + 3, 4, 4);
        } else {
            self.selectedView.frame = CGRectMake(CGRectGetMidX(self.videoTypeButton.frame) - 2, CGRectGetMaxY(self.videoTypeButton.frame) + 3, 4, 4);
        }
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

#pragma mark - Getter

- (UILabel *)sheetTitleLabel {
    if (!_sheetTitleLabel) {
        _sheetTitleLabel = [[UILabel alloc] init];
        _sheetTitleLabel.textColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:1];
        _sheetTitleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16];
        _sheetTitleLabel.text = PLVLocalizedString(@"连麦设置");
    }
    return _sheetTitleLabel;
}

- (UILabel *)optionTitleLabel {
    if (!_optionTitleLabel) {
        _optionTitleLabel = [[UILabel alloc] init];
        _optionTitleLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.6];
        _optionTitleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:12];
        _optionTitleLabel.text = PLVLocalizedString(@"默认连麦设置");
    }
    return _optionTitleLabel;
}

- (UIButton *)audioTypeButton {
    if (!_audioTypeButton) {
        _audioTypeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _audioTypeButton.tag = 0;
        _audioTypeButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:14];
        [_audioTypeButton setTitle:PLVLocalizedString(@"语音连麦") forState:UIControlStateNormal];
        [_audioTypeButton setTitleColor:PLV_UIColorFromRGBA(@"#F0F1F5", 0.6) forState:UIControlStateNormal];
        [_audioTypeButton setTitleColor:PLV_UIColorFromRGB(@"#4399FF") forState:UIControlStateSelected];
        [_audioTypeButton addTarget:self action:@selector(optionButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _audioTypeButton.selected = YES;
    }
    return _audioTypeButton;
}

- (UIButton *)videoTypeButton {
    if (!_videoTypeButton) {
        _videoTypeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _videoTypeButton.tag = 1;
        _videoTypeButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:14];
        [_videoTypeButton setTitle:PLVLocalizedString(@"视频连麦") forState:UIControlStateNormal];
        
        [_videoTypeButton setTitleColor:PLV_UIColorFromRGBA(@"#F0F1F5", 0.6) forState:UIControlStateNormal];
        [_videoTypeButton setTitleColor:PLV_UIColorFromRGB(@"#4399FF") forState:UIControlStateSelected];
        [_videoTypeButton addTarget:self action:@selector(optionButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _videoTypeButton;
}

- (UIView *)selectedView {
    if (!_selectedView) {
        _selectedView = [[UIView alloc] init];
        _selectedView.layer.cornerRadius = 2;
        _selectedView.layer.masksToBounds = YES;
        _selectedView.backgroundColor = [PLVColorUtil colorFromHexString:@"#4399FF"];
    }
    return _selectedView;
}

- (UILabel *)optionNotesLabel {
    if (!_optionNotesLabel) {
        _optionNotesLabel = [[UILabel alloc] init];
        _optionNotesLabel.textColor = [PLVColorUtil colorFromHexString:@"#878B93"];
        _optionNotesLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:12];
        _optionNotesLabel.text = PLVLocalizedString(@"注：更改连麦方式时，需要确保当前无人正在连麦");
    }
    return _optionNotesLabel;
}

- (UILabel *)sheetNotesLabel {
    if (!_sheetNotesLabel) {
        _sheetNotesLabel = [[UILabel alloc] init];
        _sheetNotesLabel.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5" alpha:0.6];
        _sheetNotesLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:12];
        _sheetNotesLabel.text = PLVLocalizedString(@"若需要固定该配置，请前往频道下-角色设置-角色权限-功能配置-连麦设置-默认连麦方式修改");
        _sheetNotesLabel.numberOfLines = 2;
    }
    return _sheetNotesLabel;
}

- (NSInteger)selectedTag {
    return self.linkMicOnAudio ? 0 : 1;
}

#pragma mark - Action

- (void)backButtonAction {
    [self dismiss];
}

- (void)optionButtonAction:(id)sender {
    UIButton *button = (UIButton *)sender;
    if (button.selected) {
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvsaLinkMicSettingSheet_wannaChangeLinkMicType:)]) {
        [self.delegate plvsaLinkMicSettingSheet_wannaChangeLinkMicType:button.tag == 0];
    }
}

@end
