//
//  PLVSAMoreInfoSheet.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAMoreInfoSheet.h"

// utils
#import "PLVSAUtils.h"
#import "PLVSABitRateSheet.h"

//SDK
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVSAMoreInfoSheet ()

// UI
@property (nonatomic, strong) UILabel *titleLabel; // 标题
@property (nonatomic, strong) UIButton *cameraButton; // 摄像头
@property (nonatomic, strong) UIButton *micphoneButton; // 麦克风
@property (nonatomic, strong) UIButton *cameraReverseButton; // 翻转
@property (nonatomic, strong) UIButton *mirrorButton; // 镜像
@property (nonatomic, strong) UIButton *flashButton; // 闪光灯
@property (nonatomic, strong) UIButton *cameraBitRateButton; // 摄像头清晰度
@property (nonatomic, strong) UIButton *closeRoomButton; // 全体禁言

@end

@implementation PLVSAMoreInfoSheet

#pragma mark - [ Life Cycle ]

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight sheetLandscapeWidth:(CGFloat)sheetLandscapeWidth{
    self = [super initWithSheetHeight:sheetHeight sheetLandscapeWidth:sheetLandscapeWidth];
    if (self) {
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.cameraButton];
        [self.contentView addSubview:self.micphoneButton];
        [self.contentView addSubview:self.cameraReverseButton];
        [self.contentView addSubview:self.mirrorButton];
        [self.contentView addSubview:self.flashButton];
        [self.contentView addSubview:self.cameraBitRateButton];
        [self.contentView addSubview:self.closeRoomButton];
    }
    return self;
}


#pragma mark - [ Override ]

- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    
    CGFloat titleX = isPad ? 56 : (isLandscape ? 32 : 16);
    CGFloat titleY = (self.bounds.size.height > 667 || isLandscape) ? 32 : 18;
    self.titleLabel.frame = CGRectMake(titleX, titleY, 50, 18);
    NSMutableArray *buttonArray = [NSMutableArray arrayWithArray:@[self.cameraButton,
                                                                   self.micphoneButton,
                                                                   self.cameraReverseButton,
                                                                   self.mirrorButton,
                                                                   self.flashButton,
                                                                   self.cameraBitRateButton]];
    self.closeRoomButton.hidden = YES;
    if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType != PLVRoomUserTypeGuest) {
        self.closeRoomButton.hidden = NO;
        [buttonArray addObject:self.closeRoomButton];
    }
    
    [self setButtonFrameWithArray:buttonArray];
    [self setButtonInsetsWithArray:buttonArray];
}


#pragma mark - [ Public Method ]
- (void)changeFlashButtonSelectedState:(BOOL)selectedState{
    self.flashButton.selected = selectedState;
    _currentCameraFlash = self.flashButton.selected;
}

#pragma mark 当前用户配置
- (void)setCurrentMicOpen:(BOOL)currentMicOpen {
    _currentMicOpen = currentMicOpen;
    self.micphoneButton.selected = currentMicOpen;
}

- (void)setStreamQuality:(PLVResolutionType)streamQuality {
    _streamQuality = streamQuality;
    [self setCameraBitRateButtonTitleAndImageWithType:streamQuality];
}

- (void)setCurrentCameraOpen:(BOOL)currentCameraOpen {
    _currentCameraOpen = currentCameraOpen;
    self.cameraButton.selected = currentCameraOpen;
    // 摄像头关闭，翻转 禁用
    self.cameraReverseButton.enabled = currentCameraOpen;
    // 后置摄像头、摄像头：镜像禁用
    self.mirrorButton.enabled = currentCameraOpen && self.currentCameraFront;
    // 前置摄像头，闪光灯 禁用
    self.flashButton.enabled = currentCameraOpen && !self.currentCameraFront;
}

/// 本地用户的 摄像头 当前是否前置
- (void)setCurrentCameraFront:(BOOL)currentCameraFront {
    _currentCameraFront = currentCameraFront;
    self.cameraReverseButton.selected = currentCameraFront;
    
    // 前置摄像头，闪光灯 禁用
    self.flashButton.enabled = !currentCameraFront && self.currentCameraOpen;
    //后置摄像头、摄像头关闭: 镜像禁用
    self.mirrorButton.enabled = currentCameraFront && self.currentCameraOpen;
}

- (void)setCurrentCameraMirror:(BOOL)currentCameraMirror {
    _currentCameraMirror = currentCameraMirror;
    self.mirrorButton.selected = currentCameraMirror;
}

- (void)setCloseRoom:(BOOL)closeRoom {
    _closeRoom = closeRoom;
    self.closeRoomButton.selected = closeRoom;
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"更多";
        _titleLabel.font = [UIFont systemFontOfSize:18];
        _titleLabel.textColor = [UIColor colorWithRed:240/255.0 green:241/255.0 blue:245/255.0 alpha:1/1.0];
    }
    return _titleLabel;
}
- (UIButton *)cameraButton {
    if (!_cameraButton) {
        _cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cameraButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _cameraButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [_cameraButton setTitle:@"摄像头" forState:UIControlStateNormal];
        [_cameraButton setTitle:@"摄像头" forState:UIControlStateSelected];
        [_cameraButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_camera_close"] forState:UIControlStateNormal];
        [_cameraButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_camera_open"] forState:UIControlStateSelected];
        [_cameraButton addTarget:self action:@selector(cameraButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _cameraButton;
}

- (UIButton *)micphoneButton {
    if (!_micphoneButton) {
        _micphoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _micphoneButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _micphoneButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [_micphoneButton setTitle:@"麦克风" forState:UIControlStateNormal];
        [_micphoneButton setTitle:@"麦克风" forState:UIControlStateSelected];
        [_micphoneButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_micphone_close"] forState:UIControlStateNormal];
        [_micphoneButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_micphone_open"] forState:UIControlStateSelected];
        [_micphoneButton addTarget:self action:@selector(micphoneButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _micphoneButton;
}

- (UIButton *)cameraReverseButton {
    if (!_cameraReverseButton) {
        _cameraReverseButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cameraReverseButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _cameraReverseButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [_cameraReverseButton setTitle:@"翻转" forState:UIControlStateNormal];
        [_cameraReverseButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_cameraReverse"] forState:UIControlStateNormal];
        [_cameraReverseButton addTarget:self action:@selector(cameraReverseButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraReverseButton;
}

- (UIButton *)mirrorButton {
    if (!_mirrorButton) {
        _mirrorButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _mirrorButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _mirrorButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [_mirrorButton setTitle:@"镜像" forState:UIControlStateNormal];
        [_mirrorButton setTitle:@"镜像" forState:UIControlStateSelected];
        [_mirrorButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_mirrorClose"] forState:UIControlStateNormal];

        [_mirrorButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_mirrorOpen"] forState:UIControlStateSelected];
        [_mirrorButton addTarget:self action:@selector(mirrorButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _mirrorButton;
}

- (UIButton *)flashButton {
    if (!_flashButton) {
        _flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _flashButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _flashButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        [_flashButton setTitle:@"闪光灯" forState:UIControlStateNormal];
        [_flashButton setTitle:@"闪光灯" forState:UIControlStateSelected];
        [_flashButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_flash_close"] forState:UIControlStateNormal];
        [_flashButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_flash_open"] forState:UIControlStateSelected];
        [_flashButton addTarget:self action:@selector(flashButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _flashButton;
}

- (UIButton *)cameraBitRateButton {
    if (!_cameraBitRateButton) {
        _cameraBitRateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cameraBitRateButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _cameraBitRateButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        _cameraBitRateButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [_cameraBitRateButton setTitle:@"" forState:UIControlStateNormal];
        [_cameraBitRateButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_hd"] forState:UIControlStateNormal];
        [_cameraBitRateButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_hd"] forState:UIControlStateSelected];
        [_cameraBitRateButton addTarget:self action:@selector(cameraBitRateButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cameraBitRateButton;
}

- (UIButton *)closeRoomButton {
    if (!_closeRoomButton) {
        _closeRoomButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeRoomButton.titleLabel.font = [UIFont systemFontOfSize:12];
        _closeRoomButton.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.6];
        _closeRoomButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        NSString *normalTitle = isPad ? @"开启全体禁言" : @"开启全\n体禁言";
        NSString *selectedTitle = isPad ? @"取消全体禁言" : @"取消全\n体禁言";
        [_closeRoomButton setTitle:normalTitle forState:UIControlStateNormal];
        [_closeRoomButton setTitle:selectedTitle forState:UIControlStateSelected];
        [_closeRoomButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_allmicphoneClose"] forState:UIControlStateNormal];
        [_closeRoomButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_btn_allmicphoneClose"] forState:UIControlStateSelected];
        [_closeRoomButton addTarget:self action:@selector(closeRoomButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeRoomButton;
}

#pragma mark setButtonFrame

- (CGFloat)getMaxButtonWidthWithArray:(NSArray *)buttonArray {
    CGFloat maxButtonWidth = 28;
    for (int i = 0; i < buttonArray.count ; i++) {
        UIButton *button = buttonArray[i];
        
        // width
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:button.titleLabel.text attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12]}];
        CGSize titleSize = [attr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        maxButtonWidth = MAX(titleSize.width, maxButtonWidth);
    }
    return maxButtonWidth;
}

- (void)setButtonFrameWithArray:(NSArray *)buttonArray {
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    BOOL isLandscape = [PLVSAUtils sharedUtils].isLandscape;
    
    CGFloat titleLabelMaxY =  ((self.bounds.size.height > 667 || isLandscape) ? 32 : 18) + 18;
    CGFloat buttonX = isLandscape ? 38 : 21.5;
    CGFloat buttonY =  (self.bounds.size.height > 667 || isLandscape) ? CGRectGetMaxY(self.titleLabel.frame) + 12 : titleLabelMaxY + 10;
    CGFloat buttonImageHeight = 28;
    CGFloat buttonWidth = [self getMaxButtonWidthWithArray:buttonArray];
    CGFloat buttonHeight = buttonImageHeight + 12 +14;
    CGFloat padding = 0;
    if (isLandscape) {
        padding = (self.sheetLandscapeWidth - buttonX * 2 - buttonWidth * 3) / 2;
    } else {
        padding = (self.bounds.size.width - buttonX * 2 - buttonWidth * 5) / 4;
    }
    CGFloat margin = (self.bounds.size.height > 667 || isLandscape) ? 18 : 16;
    
    if (isPad) {
        buttonWidth = 88;
        buttonX = isLandscape ? (self.contentView.bounds.size.width -buttonWidth) / 2:(self.bounds.size.width - buttonWidth * 7) / 2;
        buttonY = CGRectGetMaxY(self.titleLabel.frame) + 24;
        padding = 0;
        if (buttonX < 0) {
            buttonWidth = self.bounds.size.width / 7;
            buttonX = 0;
        }
    }
    
    for (int i = 0; i < buttonArray.count ; i++) {
        UIButton *button = buttonArray[i];
        
        // width
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:button.titleLabel.text attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12]}];
        CGSize titleSize = [attr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
        buttonWidth = MAX(titleSize.width, buttonWidth);
        buttonHeight = MAX(titleSize.height + buttonImageHeight + 12, buttonHeight);
        
        // 换行
        if (isLandscape) {
            if (isPad) {
                buttonY += buttonHeight + margin;
            }else if (i == 3 || i == 6) {
                buttonX = 43;
                buttonY += buttonHeight + margin;
            }
        } else {
            if (!isPad && i == 5) {
                buttonX = 21.5;
                buttonY += buttonHeight + margin;
            }
        }
        
        // frame
        button.frame = CGRectMake(buttonX, buttonY, buttonWidth, buttonHeight);
        // buttonX
        if (!(isPad && isLandscape)) {
            buttonX += buttonWidth + padding;
        }
    }
}

- (void)setButtonInsetsWithArray:(NSArray *)buttonArray {
    for (int i = 0; i < buttonArray.count ; i++) {
        UIButton *but = buttonArray[i];
        CGFloat padding = 12;
        CGFloat imageBottom = but.titleLabel.intrinsicContentSize.height;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            imageBottom += padding;
        }
        
        [but setTitleEdgeInsets:
               UIEdgeInsetsMake(but.frame.size.height/2 + padding,
                                -but.imageView.frame.size.width,
                                0,
                                0)];
        [but setImageEdgeInsets:
                   UIEdgeInsetsMake(
                               0,
                               (but.frame.size.width-but.imageView.frame.size.width)/2,
                                imageBottom,
                               (but.frame.size.width-but.imageView.frame.size.width)/2)];
    }
}

#pragma mark 清晰度枚举类型、字符的转换
/// 将成字符串转换成清晰度枚举值
- (PLVResolutionType)changeBitRateTypeWithString:(NSString *)bitRatestring {
    PLVResolutionType type = PLVResolutionType360P;
    if ([bitRatestring isEqualToString:@"超清"]) {
        type = PLVResolutionType720P;
    } else if ([bitRatestring isEqualToString:@"高清"]) {
        type = PLVResolutionType360P;
    } else if ([bitRatestring isEqualToString:@"标清"]) {
        type = PLVResolutionType180P;
    }
    return type;
}

- (void)setCameraBitRateButtonTitleAndImageWithType:(PLVResolutionType)type {
    NSString *title = @"";
    NSString *imageName = @"";
    switch (type) {
        case PLVResolutionType180P:
            title = @"标清\n  ";
            imageName = @"plvsa_liveroom_btn_sd";
            break;
        case PLVResolutionType360P:
            title = @"高清\n  ";
            imageName = @"plvsa_liveroom_btn_hd";
            break;
        case PLVResolutionType720P:
            title = @"超清\n  ";
            imageName = @"plvsa_liveroom_btn_uhd";
            break;
        default:
            break;
    }
    
    // iPad时，文案去掉换行
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    if (isPad) {
        NSString *padTitle = [title substringToIndex:2];
        title = padTitle;
    }

    [self.cameraBitRateButton setTitle:title forState:UIControlStateNormal];
    [self.cameraBitRateButton setImage:[PLVSAUtils imageForLiveroomResource:imageName] forState:UIControlStateNormal];
}
#pragma mark - Event

#pragma mark Action

- (void)cameraButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheet:didChangeCameraOpen:)]) {
        [self.delegate moreInfoSheet:self didChangeCameraOpen:!self.cameraButton.selected];
    }
}

- (void)micphoneButtonAction {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheet:didChangeMicOpen:)]) {
        [self.delegate moreInfoSheet:self didChangeMicOpen:!self.micphoneButton.selected];
    }
}

- (void)cameraReverseButtonAction {
    __weak typeof(self) weakSelf = self;
    self.cameraReverseButton.userInteractionEnabled = NO; //控制翻转按钮点击间隔，防止短时间内重复点击
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.cameraReverseButton.userInteractionEnabled = YES;
     });
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheet:didChangeCameraFront:)]) {
        [self.delegate moreInfoSheet:self didChangeCameraFront:!self.cameraReverseButton.selected];
        self.currentCameraFront = !self.cameraReverseButton.selected;
    }
}

- (void)mirrorButtonAction {
    __weak typeof(self) weakSelf = self;
    self.mirrorButton.userInteractionEnabled = NO; //控制镜像按钮点击间隔，防止短时间内重复点击
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        weakSelf.mirrorButton.userInteractionEnabled = YES;
     });
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheet:didChangeMirrorOpen:)]) {
        [self.delegate moreInfoSheet:self didChangeMirrorOpen:!self.mirrorButton.selected];
        self.currentCameraMirror = !self.mirrorButton.selected;
    }
}

- (void)flashButtonAction {
    self.flashButton.selected = !self.flashButton.selected;
    [self changeFlashButtonSelectedState:self.flashButton.selected];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheet:didChangeFlashOpen:)]) {
        [self.delegate moreInfoSheet:self didChangeFlashOpen:self.flashButton.selected];
    }
}

- (void)cameraBitRateButtonAction {
    [self dismiss];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheetDidTapCameraBitRateButton:)]) {
        [self.delegate moreInfoSheetDidTapCameraBitRateButton:self];
    }
}

- (void)closeRoomButtonAction {
    self.closeRoomButton.selected = !self.closeRoomButton.selected;
    self.closeRoom = self.closeRoomButton.selected;
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(moreInfoSheet:didChangeCloseRoom:)]) {
        [self.delegate moreInfoSheet:self didChangeCloseRoom:self.closeRoomButton.selected];
    }
}


@end
