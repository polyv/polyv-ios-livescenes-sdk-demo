//
//  PLVLCLiveRoomPlayerSkinView.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/10/6.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCLiveRoomPlayerSkinView.h"

#import "PLVLCUtils.h"
#import "PLVLCLiveRoomLandscapeInputView.h"
#import "PLVCommodityPushView.h"
#import "PLVRoomDataManager.h"
#import "PLVChatModel.h"

#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCLiveRoomPlayerSkinView () <PLVLCLiveRoomLandscapeInputViewDelegate>

#pragma mark UI
@property (nonatomic, strong) UIButton * bulletinButton;
@property (nonatomic, strong) UIButton * danmuButton;
@property (nonatomic, strong) UIButton * danmuSettingButton;
@property (nonatomic, strong) UILabel * guideChatLabel;
@property (nonatomic, strong) UIView * likeButtonBackgroudView;
@property (nonatomic, strong) UIView * redpackBackgroudView;
@property (nonatomic, strong) UIView * cardPushBackgroudView;
@property (nonatomic, strong) UIButton *rewardButton;
@property (nonatomic, strong) UIButton *commodityButton;
@property (nonatomic, strong) PLVLCLiveRoomLandscapeInputView * landscapeInputView;

@end

@implementation PLVLCLiveRoomPlayerSkinView

@synthesize skinViewLiveStatus = _skinViewLiveStatus;

@synthesize titleLabel = _titleLabel;
@synthesize playTimesLabel = _playTimesLabel;

#pragma mark - [ Life Period ]
- (void)dealloc{
    NSLog(@"%s",__FUNCTION__);
}

- (void)layoutSubviews{
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;

    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    
    CGFloat leftSafePadding;
    CGFloat rightSafePadding = 0;
    if (@available(iOS 11.0, *)) {
        leftSafePadding = self.safeAreaInsets.left;
        rightSafePadding = self.safeAreaInsets.right;
    } else {
        leftSafePadding = 20;
    }
    leftSafePadding += 0;
            
    if (!fullScreen) {
        self.hidden = YES;
    }else{
        self.hidden = NO;
        [self controlsSwitchShowStatusWithAnimation:YES];
        BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
        // 顶部UI
        CGFloat topShadowLayerHeight = 90.0;
        self.topShadowLayer.frame = CGRectMake(0, 0, viewWidth, topShadowLayerHeight);
        
        CGSize backButtonSize = CGSizeMake(40.0, 20.0f);
        CGFloat countdownTimeViewHeight = 32.0;
        CGFloat topPadding = isPad ? 30.0 : 16.0;

        if (![PLVFdUtil isiPhoneXSeries]) {
            leftSafePadding = 6;
            rightSafePadding = 6;
        }
        if (isPad) {
            leftSafePadding = 20;
            rightSafePadding = 20;
        }
        
        self.backButton.frame = CGRectMake(leftSafePadding, topPadding - 10, backButtonSize.width, 40);
        
        self.countdownTimeView.frame = CGRectMake(0, topPadding - (countdownTimeViewHeight - backButtonSize.height) / 2.0f,
                                                  viewWidth, countdownTimeViewHeight);
           
        CGSize titleLabelFitSize = [self.titleLabel sizeThatFits:CGSizeMake(200, 22)];
        self.titleLabel.frame = CGRectMake(CGRectGetMaxX(self.backButton.frame), topPadding, titleLabelFitSize.width, backButtonSize.height);
        
        self.moreButton.frame = CGRectMake(viewWidth - rightSafePadding - backButtonSize.width, topPadding, backButtonSize.width, backButtonSize.height);
        
        [self refreshBulletinButtonFrame];
        [self refreshPictureInPictureButtonFrame];
        
        [self refreshTitleLabelFrameInSmallScreen];
        [self refreshPlayTimesLabelFrame];
        [self refreshProgressViewFrame];

        // 底部UI
        CGFloat bottomShadowLayerHeight = 90.0;
        self.bottomShadowLayer.frame = CGRectMake(0, viewHeight - bottomShadowLayerHeight, viewWidth, bottomShadowLayerHeight);

        CGFloat bottomPadding = 28.0;
        self.playButton.frame = CGRectMake(leftSafePadding, viewHeight - bottomPadding - backButtonSize.height, backButtonSize.width, backButtonSize.height);
        
        [self refreshRefreshButtonFrame];
        [self refreshFloatViewShowButtonFrame];
        [self refreshDanmuButtonFrame];
        [self refreshGuideChatLabelFrame];
        [self refreshBottomButtonsFrame];
        
        CGFloat timeLabelWidth = [self getLabelTextWidth:self.currentTimeLabel];
        self.currentTimeLabel.frame = CGRectMake(CGRectGetMinX(self.playButton.frame), CGRectGetMinY(self.playButton.frame) - 14 - backButtonSize.height, timeLabelWidth, backButtonSize.height);
        
        self.diagonalsLabel.frame = CGRectMake(CGRectGetMaxX(self.currentTimeLabel.frame), CGRectGetMinY(self.currentTimeLabel.frame), 5, backButtonSize.height);
        
        timeLabelWidth = [self getLabelTextWidth:self.durationLabel];
        self.durationLabel.frame = CGRectMake(CGRectGetMaxX(self.diagonalsLabel.frame), CGRectGetMinY(self.currentTimeLabel.frame), timeLabelWidth, backButtonSize.height);
        
        CGFloat progressSliderOriginX = CGRectGetMaxX(self.durationLabel.frame) + 16;
        CGFloat progressSliderWidth = CGRectGetMaxX(self.likeButtonBackgroudView.frame) - progressSliderOriginX;
        self.progressSlider.frame = CGRectMake(progressSliderOriginX, CGRectGetMinY(self.currentTimeLabel.frame), progressSliderWidth, 21);
        
        // 其他UI
        self.landscapeInputView.frame = self.bounds;
        
        // PPT翻页视图
        CGFloat documentToolViewWidht = self.documentToolView.viewWidth;
        CGFloat documentToolHeight = 36;
        CGFloat documentToolPadding = 12;
        self.documentToolView.frame = CGRectMake((viewWidth - documentToolViewWidht) / 2, CGRectGetMinY(self.guideChatLabel.frame) - documentToolHeight - documentToolPadding, documentToolViewWidht , documentToolHeight);
        // 自动隐藏皮肤
        [self autoHideSkinView];
    }
}

#pragma mark - [ Public Methods ]
- (void)hiddenLiveRoomPlayerSkinView:(BOOL)isHidden {
    if (isHidden) {
        self.needShowSkin = self.skinShow;
    }
    [self controlsSwitchShowStatusWithAnimation:!isHidden];
}

- (void)displayLikeButtonView:(UIView *)likeButtonView{
    if (likeButtonView && [likeButtonView isKindOfClass:UIView.class]) {
        [self.likeButtonBackgroudView addSubview:likeButtonView];
        likeButtonView.frame = self.likeButtonBackgroudView.bounds;
        likeButtonView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }else{
        NSLog(@"PLVLCLiveRoomPlayerSkinView - displayLikeButtonView failed, view illegal %@",likeButtonView);
    }
}

- (void)displayRedpackButtonView:(UIView *)redpackButtonView {
    if (redpackButtonView && [redpackButtonView isKindOfClass:UIView.class]) {
        [self.redpackBackgroudView addSubview:redpackButtonView];
        redpackButtonView.frame = self.redpackBackgroudView.bounds;
        redpackButtonView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }else{
        NSLog(@"PLVLCLiveRoomPlayerSkinView - displayCardPushButtonView failed, view illegal %@", redpackButtonView);
    }
}

- (void)displayCardPushButtonView:(UIView *)cardPushButtonView {
    if (cardPushButtonView && [cardPushButtonView isKindOfClass:UIView.class]) {
        [self.cardPushBackgroudView addSubview:cardPushButtonView];
        cardPushButtonView.frame = self.cardPushBackgroudView.bounds;
        cardPushButtonView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }else{
        NSLog(@"PLVLCLiveRoomPlayerSkinView - displayCardPushButtonView failed, view illegal %@", cardPushButtonView);
    }
}

- (void)showCommodityButton:(BOOL)show {
    self.commodityButton.hidden = !show;
    [self refreshBottomButtonsFrame];
}

- (void)showRedpackButtonView:(BOOL)show {
    self.redpackBackgroudView.hidden = !show;
    [self refreshBottomButtonsFrame];
}

- (void)showCardPushButtonView:(BOOL)show {
    self.cardPushBackgroudView.hidden = !show;
    [self refreshBottomButtonsFrame];
}

- (void)refreshPaintButtonShow:(BOOL)show {
    self.paintButton.hidden = !show;
    [self refreshBottomButtonsFrame];
}

- (void)didTapReplyChatModel:(PLVChatModel *)model {
    [self.landscapeInputView showWithReplyChatModel:model];
}

#pragma mark - [ Private Methods ]
- (UIImage *)getLiveRoomImageWithName:(NSString *)imageName{
    return [PLVLCUtils imageForLiveRoomResource:imageName];
}

- (void)refreshBulletinButtonFrame{
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat rightSafePadding = 0;
    CGFloat topPadding = 16.0;
    CGFloat intervalPadding = 0;

    if (@available(iOS 11.0, *)) {
        rightSafePadding = self.safeAreaInsets.right;
    }
    // iPad适配
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        rightSafePadding = 20.0;
        topPadding = 30.0;
        intervalPadding = 10.0;
    }
    
    CGSize backButtonSize = CGSizeMake(40.0, 20.0);
    CGFloat bulletinButtonX = self.moreButton.hidden ? (viewWidth - rightSafePadding - backButtonSize.width) : (CGRectGetMinX(self.moreButton.frame) - backButtonSize.width - intervalPadding);
    self.bulletinButton.frame = CGRectMake(bulletinButtonX, topPadding, backButtonSize.width, backButtonSize.height);
}

- (void)refreshPictureInPictureButtonFrame{
    CGFloat rightSafePadding = 0;
    CGFloat topPadding = 16.0;
    CGFloat intervalPadding = 0;

    if (@available(iOS 11.0, *)) {
        rightSafePadding = self.safeAreaInsets.right;
    }
    // iPad适配
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        rightSafePadding = 20.0;
        topPadding = 30.0;
        intervalPadding = 10.0;
    }
    
    CGSize backButtonSize = CGSizeMake(40.0, 20.0);
    CGFloat pictureInPictureButtonX = self.bulletinButton.frame.origin.x - backButtonSize.width;
    self.pictureInPictureButton.frame = CGRectMake(pictureInPictureButtonX, topPadding, backButtonSize.width, backButtonSize.height);
}

- (void)refreshTitleLabelFrameInSmallScreen{
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGSize backButtonSize = CGSizeMake(40.0, 20.0);
    CGFloat topPadding = isPad ? 30.0 : 16.0;
    CGSize titleLabelFitSize = [self.titleLabel sizeThatFits:CGSizeMake(200, 22)];
    CGFloat titleLabelWidth = CGRectGetMinX(self.moreButton.frame) - CGRectGetMaxX(self.backButton.frame);

    if (isPad) {
        // iPad小分屏适配（横屏1:2），标题宽度调整，观看次数隐藏
        Boolean isSmallScreen = CGRectGetWidth(self.bounds) <= PLVScreenWidth / 3 ? YES : NO;
        if (isSmallScreen) {
            self.playTimesLabel.hidden = YES;
            
            if (self.skinViewType < PLVLCBasePlayerSkinViewType_AlonePlayback) {
                titleLabelWidth = CGRectGetMinX(self.bulletinButton.frame) - CGRectGetMaxX(self.backButton.frame);
            }
            titleLabelWidth = MIN(titleLabelWidth, titleLabelFitSize.width);
            self.titleLabel.frame = CGRectMake(CGRectGetMaxX(self.backButton.frame), topPadding, titleLabelWidth, backButtonSize.height);
        } else {
            self.playTimesLabel.hidden = NO;

            CGFloat playTimesLabelMaxWidth = 100;
            if (self.skinViewType < PLVLCBasePlayerSkinViewType_AlonePlayback) {
                titleLabelWidth = CGRectGetMinX(self.bulletinButton.frame) - CGRectGetMaxX(self.backButton.frame) - playTimesLabelMaxWidth - 16;
            }
            titleLabelWidth = MIN(titleLabelWidth, titleLabelFitSize.width);
            self.titleLabel.frame = CGRectMake(CGRectGetMaxX(self.backButton.frame), topPadding, titleLabelWidth, backButtonSize.height);
        }
    }
}

- (void)refreshRefreshButtonFrame {
    CGSize buttonSize = CGSizeMake(40.0, 20.0);
    CGFloat originX = CGRectGetMinX(self.playButton.frame);
    if (!self.playButton.hidden && self.playButton.superview) {
        originX += CGRectGetWidth(self.playButton.frame) + 5;
    }
    self.refreshButton.frame = CGRectMake(originX, CGRectGetMinY(self.playButton.frame), buttonSize.width, buttonSize.height);
}

- (void)refreshFloatViewShowButtonFrame {
    CGSize buttonSize = CGSizeMake(40.0, 20.0);
    CGFloat originX = CGRectGetMinX(self.playButton.frame);
    if (!self.playButton.hidden && self.playButton.superview) {
        originX += CGRectGetWidth(self.playButton.frame) + 5;
    }
    if (!self.refreshButton.hidden && self.refreshButton.superview) {
        originX += CGRectGetWidth(self.refreshButton.frame) + 5;
    }
    self.floatViewShowButton.frame = CGRectMake(originX, CGRectGetMinY(self.playButton.frame), buttonSize.width, buttonSize.height);
}

- (void)refreshDanmuButtonFrame {
    CGSize buttonSize = CGSizeMake(40.0, 20.0);
    CGFloat originX = CGRectGetMinX(self.playButton.frame);
    if (!self.playButton.hidden && self.playButton.superview) {
        originX += CGRectGetWidth(self.playButton.frame) + 5;
    }
    if (!self.refreshButton.hidden && self.refreshButton.superview) {
        originX += CGRectGetWidth(self.refreshButton.frame) + 5;
    }
    if (!self.floatViewShowButton.hidden && self.floatViewShowButton.superview) {
        originX += CGRectGetWidth(self.floatViewShowButton.frame) + 5;
    }
    self.danmuButton.frame = CGRectMake(originX, CGRectGetMinY(self.playButton.frame), buttonSize.width, buttonSize.height);
    originX += CGRectGetWidth(self.danmuButton.frame) + 5;
    self.danmuSettingButton.frame = CGRectMake(originX, CGRectGetMinY(self.playButton.frame), buttonSize.width, buttonSize.height);
}

- (void)refreshBottomButtonsFrame {
    CGFloat rightSafePadding = 0;
    if (@available(iOS 11.0, *)) {
        rightSafePadding = self.safeAreaInsets.right;
    }
    // iPad适配
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        rightSafePadding = 20.0;
    }
    
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat buttonWidth = 36.0;
    CGFloat buttonOriginX = viewWidth - rightSafePadding - 10 - buttonWidth;
    CGFloat buttonOriginY = self.playButton.center.y - buttonWidth / 2.0f;
    CGFloat buttonPadding = 16.0; // 每个按钮中间的间隔

    UIView *likeButtonView = self.likeButtonBackgroudView.subviews.firstObject;
    if (likeButtonView && !likeButtonView.isHidden) {
        self.likeButtonBackgroudView.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonWidth, buttonWidth);
        buttonOriginX -= (buttonPadding + buttonWidth);
    }
    
    if (!self.rewardButton.isHidden && self.rewardButton.superview) {
        self.rewardButton.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonWidth, buttonWidth);
        buttonOriginX -= (buttonPadding + buttonWidth);
    }
    
    if (!self.commodityButton.isHidden) {
        self.commodityButton.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonWidth, buttonWidth);
        buttonOriginX -= (buttonPadding + buttonWidth);
    }
    
    if (!self.redpackBackgroudView.isHidden) {
        self.redpackBackgroudView.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonWidth, buttonWidth);
        buttonOriginX -= (buttonPadding + buttonWidth);
    }
    
    // 从右数起第一个按钮为卡片推送时，位置适配，右边间隔从10改为50
    buttonOriginX = MIN(buttonOriginX, viewWidth - rightSafePadding - 50 - buttonWidth);
    if (!self.cardPushBackgroudView.isHidden) {
        self.cardPushBackgroudView.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonWidth, buttonWidth);
        buttonOriginX -= (buttonPadding + buttonWidth);
    }
    
    // 从右数起第一个按钮为画笔时，位置适配，右边间隔从10改为50
    buttonOriginX = MIN(buttonOriginX, viewWidth - rightSafePadding - 50 - buttonWidth);
    if (!self.paintButton.isHidden) {
        self.paintButton.frame = CGRectMake(buttonOriginX, buttonOriginY, buttonWidth, buttonWidth);
    }
}

- (void)refreshGuideChatLabelFrame {
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    CGFloat bottomPadding = 22.0;

    CGFloat guideChatLabelWidth = 0.23 * viewWidth;
    CGFloat guideChatLabelHeight = 36.0;

    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    Boolean isSmallScreen = viewWidth <= PLVScreenWidth / 3 ? YES : NO;
    if (isPad && isSmallScreen) {
        // iPad小分屏适配（横屏1:2），聊天引导栏布局上调
        self.guideChatLabel.frame = CGRectMake(30, viewHeight - bottomPadding - guideChatLabelHeight * 2 - 10, CGRectGetWidth(self.bounds) - 30 * 2 , guideChatLabelHeight);
    } else {
        CGFloat middleOriginX = (viewWidth - guideChatLabelWidth) / 2.0;
        CGFloat danmuButtonMaxOriginX = CGRectGetMaxX(self.danmuSettingButton.frame) + 10.0;
        CGFloat guideChatLabelOriginX = MAX(middleOriginX,danmuButtonMaxOriginX);
        self.guideChatLabel.frame = CGRectMake(guideChatLabelOriginX, viewHeight - bottomPadding - guideChatLabelHeight, guideChatLabelWidth, guideChatLabelHeight);
    }
}

/// 切换聊天室关闭状态，开启/禁用输入框
- (void)changeCloseRoomStatus:(BOOL)closeRoom {
    NSString *guideChatLabelText = closeRoom ? @"聊天室已关闭":@"跟大家聊点什么吧～";
    [self.guideChatLabel setText:guideChatLabelText];
    self.guideChatLabel.userInteractionEnabled = !closeRoom;
    [self.landscapeInputView showInputView:NO];
}

/// 切换聊天室专注模式状态，开启/禁用输入框
- (void)changeFocusModeStatus:(BOOL)focusMode{
    NSString *guideChatLabelText = focusMode ? @"当前为专注模式，无法发言":@"跟大家聊点什么吧～";
    [self.guideChatLabel setText:guideChatLabelText];
    self.guideChatLabel.userInteractionEnabled = !focusMode;
    [self.landscapeInputView showInputView:NO];
}

#pragma mark Private Getter
- (UIButton *)bulletinButton{
    if (!_bulletinButton && self.skinViewType < PLVLCBasePlayerSkinViewType_AlonePlayback) {
        _bulletinButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_bulletinButton.imageView setContentMode:UIViewContentModeScaleAspectFill];
        [_bulletinButton setImage:[self getLiveRoomImageWithName:@"plvlc_liveroom_bulletin"] forState:UIControlStateNormal];
        [_bulletinButton addTarget:self action:@selector(bulletinButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _bulletinButton;
}

- (UIButton *)danmuButton{
    if (!_danmuButton) {
        _danmuButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _danmuButton.hidden = YES;
        [_danmuButton setImage:[self getLiveRoomImageWithName:@"plvlc_liveroom_danmu_open"] forState:UIControlStateNormal];
        [_danmuButton setImage:[self getLiveRoomImageWithName:@"plvlc_liveroom_danmu_close"] forState:UIControlStateSelected];
        _danmuButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_danmuButton addTarget:self action:@selector(chatRoomShowButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _danmuButton;
}

- (UIButton *)danmuSettingButton{
    if (!_danmuSettingButton) {
        _danmuSettingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _danmuSettingButton.hidden = YES;
        [_danmuSettingButton setImage:[self getLiveRoomImageWithName:@"plvlc_liveroom_danmu_setting"] forState:UIControlStateNormal];
        _danmuSettingButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_danmuSettingButton addTarget:self action:@selector(chatRoomDanmuSettingButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _danmuSettingButton;
}

- (UILabel *)guideChatLabel{
    if (!_guideChatLabel) {
        _guideChatLabel = [[UILabel alloc] init];
        _guideChatLabel.textAlignment = NSTextAlignmentCenter;
        _guideChatLabel.textColor = [UIColor whiteColor];
        _guideChatLabel.font = [UIFont fontWithName:@"PingFang SC" size:14];
        _guideChatLabel.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
        _guideChatLabel.layer.cornerRadius = 18.0;
        _guideChatLabel.clipsToBounds = YES;
        _guideChatLabel.userInteractionEnabled = YES;
        
        if ([PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Playback) { //回放时不支持发言
            _guideChatLabel.text = @"聊天室暂时关闭";
        } else {
            _guideChatLabel.text = @"跟大家聊点什么吧～";
            UITapGestureRecognizer * guideChatLabelTapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(guideChatLabelTapGestureAction:)];
            [_guideChatLabel addGestureRecognizer:guideChatLabelTapGR];
        }
    }
    return _guideChatLabel;
}

- (UIView *)likeButtonBackgroudView{
    if (!_likeButtonBackgroudView) {
        _likeButtonBackgroudView = [[UIView alloc] init];
    }
    return _likeButtonBackgroudView;
}

- (UIView *)redpackBackgroudView{
    if (!_redpackBackgroudView) {
        _redpackBackgroudView = [[UIView alloc] init];
        _redpackBackgroudView.hidden = YES;
    }
    return _redpackBackgroudView;
}

- (UIView *)cardPushBackgroudView{
    if (!_cardPushBackgroudView) {
        _cardPushBackgroudView = [[UIView alloc] init];
        _cardPushBackgroudView.hidden = YES;
    }
    return _cardPushBackgroudView;
}

- (UIButton *)rewardButton {
    if (!_rewardButton) {
        _rewardButton = [[UIButton alloc]init];
        [_rewardButton setImage: [PLVLCUtils imageForLiveRoomResource:@"plv_liveroom_reward"] forState:UIControlStateNormal];
        _rewardButton.hidden = YES;
        [_rewardButton addTarget:self action:@selector(rewardButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _rewardButton;
}

- (UIButton *)commodityButton {
    if (!_commodityButton) {
        _commodityButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _commodityButton.hidden = YES;
        [_commodityButton setImage: [PLVLCUtils imageForLiveRoomResource:@"plv_liveroom_commodity"] forState:UIControlStateNormal];
        [_commodityButton addTarget:self action:@selector(commodityButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _commodityButton;
}

- (PLVLCLiveRoomLandscapeInputView *)landscapeInputView{
    if (!_landscapeInputView) {
        _landscapeInputView = [[PLVLCLiveRoomLandscapeInputView alloc]init];
        _landscapeInputView.delegate = self;
    }
    return _landscapeInputView;
}

#pragma mark Private Setter

- (void)setDanmuButtonShow:(BOOL)danmuButtonShow {
    _danmuButtonShow = danmuButtonShow;
    self.danmuButton.hidden = !danmuButtonShow;
    self.danmuSettingButton.hidden = self.danmuButton.hidden || self.danmuButton.selected;
}

#pragma mark - [ Father Public Methods ]
- (void)setupUI{
    [super setupUI];

    /// 底部UI
    [self addSubview:self.danmuButton];
    [self addSubview:self.danmuSettingButton];
    [self addSubview:self.guideChatLabel];
    [self addSubview:self.likeButtonBackgroudView];
    [self addSubview:self.redpackBackgroudView];
    [self addSubview:self.cardPushBackgroudView];
    [self addSubview:self.landscapeInputView];
    [self addSubview:self.commodityButton];

    // 注意：懒加载过程中已增加判断，若场景不匹配，将创建失败并返回nil
    if (self.skinViewType < PLVLCBasePlayerSkinViewType_AlonePlayback) { // 视频类型为 直播
        /// 顶部UI
        [self addSubview:self.bulletinButton];
        [self addSubview:self.rewardButton];
    }
}

- (void)switchSkinViewLiveStatusTo:(PLVLCBasePlayerSkinViewLiveStatus)skinViewLiveStatus{
    [super switchSkinViewLiveStatusTo:skinViewLiveStatus];
    
    if (_skinViewLiveStatus == skinViewLiveStatus) { return; }

    _skinViewLiveStatus = skinViewLiveStatus;
        
    if (self.skinViewType < PLVLCBasePlayerSkinViewType_AlonePlayback) {
        [self refreshBulletinButtonFrame];
        [self refreshPictureInPictureButtonFrame];
        [self refreshTitleLabelFrameInSmallScreen];
        [self refreshPlayTimesLabelFrame];
        [self refreshRefreshButtonFrame];
        [self refreshFloatViewShowButtonFrame];
        [self refreshDanmuButtonFrame];
        [self refreshGuideChatLabelFrame];
    }else{
        NSLog(@"PLVLCLiveRoomPlayerSkinView - skinViewLiveStatusSwitchTo failed, skin view type illegal:%ld",self.skinViewType);
    }
}

- (void)refreshPlayTimesLabelFrame{
    CGSize playTimesLabelFitSize = [self.playTimesLabel sizeThatFits:CGSizeMake(100, 20.0)];
    self.playTimesLabel.frame = CGRectMake(CGRectGetMaxX(self.titleLabel.frame) + 16, CGRectGetMinY(self.titleLabel.frame), playTimesLabelFitSize.width, 20.0);
}

- (void)refreshProgressViewFrame {
    self.progressView.frame = CGRectMake(self.frame.size.width / 2 - 73.5, self.frame.size.height / 2 -16, 147, 32);
}

- (void)showFloatViewShowButtonTipsLabelAnimation:(BOOL)showTips{
    // 横屏不需要显示提示，仅重写覆盖即可
}

- (void)refreshMoreButtonHiddenOrRestore:(BOOL)hidden {
    [super refreshMoreButtonHiddenOrRestore:hidden];
    [self refreshBulletinButtonFrame];
    [self refreshPictureInPictureButtonFrame];
}

#pragma mark Father Animation
- (void)controlsSwitchShowStatusWithAnimation:(BOOL)showStatus{
    if (self.skinShow == showStatus) {
        NSLog(@"PLVLCBasePlayerSkinView - controlsSwitchShowAnimationWithShow failed , state is same");
        return;
    }
    
    self.skinShow = showStatus;
    CGFloat alpha = self.skinShow ? 1.0 : 0.0;
    __weak typeof(self) weakSelf = self;
    void (^animationBlock)(void) = ^{
        weakSelf.topShadowLayer.opacity = alpha;
        weakSelf.bottomShadowLayer.opacity = alpha;
        for (UIView * subview in weakSelf.subviews) {
            if ([subview isKindOfClass:PLVLCLiveRoomLandscapeInputView.class]) {
                continue;
            } else if ([subview isKindOfClass:PLVLCMediaCountdownTimeView.class]) {
                continue;
            } else if ([subview isKindOfClass:PLVCommodityPushView.class]) {
                continue;
            } else if ([subview isKindOfClass:PLVLCMediaProgressView.class]) {
                continue;
            }
            subview.alpha = alpha;
        }
    };
    [UIView animateWithDuration:0.3 animations:animationBlock completion:^(BOOL finished) {
        if (finished) {
            [self autoHideSkinView];
        }
    }];
}

#pragma mark Father Getter
- (UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"房间标题";
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont fontWithName:@"PingFang SC" size:16];
    }
    return _titleLabel;
}

- (UILabel *)playTimesLabel{
    if (!_playTimesLabel) {
        _playTimesLabel = [[UILabel alloc] init];
        _playTimesLabel.text = @"播放量";
        _playTimesLabel.textAlignment = NSTextAlignmentLeft;
        _playTimesLabel.textColor = PLV_UIColorFromRGB(@"D0D0D0");
        _playTimesLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
    }
    return _playTimesLabel;
}


#pragma mark - [ Event ]
#pragma mark Action
- (void)guideChatLabelTapGestureAction:(UITapGestureRecognizer *)tapGR {
    [self.landscapeInputView showInputView:YES];
}

- (void)bulletinButtonAction:(UIButton *)button{
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLiveRoomPlayerSkinViewBulletinButtonClicked:)]) {
        [self.delegate plvLCLiveRoomPlayerSkinViewBulletinButtonClicked:self];
    }
}

- (void)chatRoomShowButtonAction:(UIButton *)button{
    self.danmuButton.selected = !self.danmuButton.selected;
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLiveRoomPlayerSkinViewDanmuButtonClicked:userWannaShowDanmu:)]) {
        BOOL showDanmu = !self.danmuButton.selected;
        self.danmuSettingButton.hidden = !showDanmu;
        [self.delegate plvLCLiveRoomPlayerSkinViewDanmuButtonClicked:self userWannaShowDanmu:showDanmu];
    }
}

- (void)chatRoomDanmuSettingButtonAction:(UIButton *)button{
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLiveRoomPlayerSkinViewDanmuSettingButtonClicked:)]) {
        [self.delegate plvLCLiveRoomPlayerSkinViewDanmuSettingButtonClicked:self];
    }
}

- (void)rewardButtonAction:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLiveRoomPlayerSkinViewRewardButtonClicked:)]) {
        [self.delegate plvLCLiveRoomPlayerSkinViewRewardButtonClicked:self];
    }
}

- (void)commodityButtonAction:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLiveRoomPlayerSkinViewCommodityButtonClicked:)]) {
        [self.delegate plvLCLiveRoomPlayerSkinViewCommodityButtonClicked:self];
    }
}

#pragma mark - [ Delegate ]
#pragma mark PLVLCLiveRoomLandscapeInputViewDelegate

- (void)plvLCLiveRoomLandscapeInputView:(PLVLCLiveRoomLandscapeInputView *)inputView
       SendButtonClickedWithSendContent:(NSString *)sendContent
                             replyModel:(PLVChatModel *)replyModel {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLiveRoomPlayerSkinView:userWannaSendChatContent:replyModel:)]) {
        [self.delegate plvLCLiveRoomPlayerSkinView:self userWannaSendChatContent:sendContent replyModel:replyModel];
    }
}

@end
