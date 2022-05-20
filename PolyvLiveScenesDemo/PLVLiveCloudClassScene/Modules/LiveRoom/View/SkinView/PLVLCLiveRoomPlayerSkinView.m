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

#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLCLiveRoomPlayerSkinView () <PLVLCLiveRoomLandscapeInputViewDelegate>

#pragma mark UI
@property (nonatomic, strong) UIButton * bulletinButton;
@property (nonatomic, strong) UIButton * danmuButton;
@property (nonatomic, strong) UILabel * guideChatLabel;
@property (nonatomic, strong) UIView * likeButtonBackgroudView;
@property (nonatomic, strong) UIButton *rewardButton;
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

        // 底部UI
        CGFloat bottomShadowLayerHeight = 90.0;
        self.bottomShadowLayer.frame = CGRectMake(0, viewHeight - bottomShadowLayerHeight, viewWidth, bottomShadowLayerHeight);

        CGFloat bottomPadding = 28.0;
        self.playButton.frame = CGRectMake(leftSafePadding, viewHeight - bottomPadding - backButtonSize.height, backButtonSize.width, backButtonSize.height);
        
        [self refreshRefreshButtonFrame];
        [self refreshFloatViewShowButtonFrame];
        [self refreshDanmuButtonFrame];
        [self refreshGuideChatLabelFrame];
        
        CGFloat likeButtonWidth = 46.0;
        self.likeButtonBackgroudView.frame = CGRectMake(viewWidth - rightSafePadding - 10 - likeButtonWidth, self.playButton.center.y - likeButtonWidth / 2.0f, likeButtonWidth, likeButtonWidth);
        self.rewardButton.frame = CGRectMake(CGRectGetMinX(self.likeButtonBackgroudView.frame) - 30 - likeButtonWidth, CGRectGetMinY(self.likeButtonBackgroudView.frame), likeButtonWidth, likeButtonWidth);
        
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
    }
}


#pragma mark - [ Public Methods ]
- (void)displayLikeButtonView:(UIView *)likeButtonView{
    if (likeButtonView && [likeButtonView isKindOfClass:UIView.class]) {
        [self.likeButtonBackgroudView addSubview:likeButtonView];
        likeButtonView.frame = self.likeButtonBackgroudView.bounds;
        likeButtonView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }else{
        NSLog(@"PLVLCLiveRoomPlayerSkinView - displayLikeButtonView failed, view illegal %@",likeButtonView);
    }
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
}

- (void)refreshGuideChatLabelFrame {
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    CGFloat bottomPadding = 28.0;

    CGFloat guideChatLabelWidth = 0.3572 * viewWidth;
    CGFloat guideChatLabelHeight = 36.0;

    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    Boolean isSmallScreen = viewWidth <= PLVScreenWidth / 3 ? YES : NO;
    if (isPad && isSmallScreen) {
        // iPad小分屏适配（横屏1:2），聊天引导栏布局上调
        self.guideChatLabel.frame = CGRectMake(30, viewHeight - (bottomPadding - 6) - guideChatLabelHeight * 2 - 10, CGRectGetWidth(self.bounds) - 30 * 2 , guideChatLabelHeight);
    } else {
        CGFloat middleOriginX = (viewWidth - guideChatLabelWidth) / 2.0;
        CGFloat danmuButtonMaxOriginX = CGRectGetMaxX(self.danmuButton.frame) + 10.0;
        CGFloat guideChatLabelOriginX = MAX(middleOriginX,danmuButtonMaxOriginX);
        self.guideChatLabel.frame = CGRectMake(guideChatLabelOriginX, viewHeight - (bottomPadding - 6) - guideChatLabelHeight, guideChatLabelWidth, guideChatLabelHeight);
    }

}

#pragma mark Private Getter
- (UIButton *)bulletinButton{
    if (!_bulletinButton && self.skinViewType < PLVLCBasePlayerSkinViewType_AlonePlayback) {
        _bulletinButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_bulletinButton setImage:[self getLiveRoomImageWithName:@"plvlc_liveroom_bulletin"] forState:UIControlStateNormal];
        [_bulletinButton addTarget:self action:@selector(bulletinButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _bulletinButton;
}

- (UIButton *)danmuButton{
    if (!_danmuButton) {
        _danmuButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _danmuButton.hidden = YES;
        [_danmuButton setImage:[self getLiveRoomImageWithName:@"plvlc_liveroom_chatroom_open"] forState:UIControlStateNormal];
        [_danmuButton setImage:[self getLiveRoomImageWithName:@"plvlc_liveroom_chatroom_close"] forState:UIControlStateSelected];
        _danmuButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_danmuButton addTarget:self action:@selector(chatRoomShowButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _danmuButton;
}

- (UILabel *)guideChatLabel{
    if (!_guideChatLabel) {
        _guideChatLabel = [[UILabel alloc] init];
        _guideChatLabel.text = @"跟大家聊点什么吧～";
        _guideChatLabel.textAlignment = NSTextAlignmentCenter;
        _guideChatLabel.textColor = [UIColor whiteColor];
        _guideChatLabel.font = [UIFont fontWithName:@"PingFang SC" size:14];
        _guideChatLabel.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
        _guideChatLabel.layer.cornerRadius = 18.0;
        _guideChatLabel.clipsToBounds = YES;
        _guideChatLabel.userInteractionEnabled = YES;

        UITapGestureRecognizer * guideChatLabelTapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(guideChatLabelTapGestureAction:)];
        [_guideChatLabel addGestureRecognizer:guideChatLabelTapGR];
    }
    return _guideChatLabel;
}

- (UIView *)likeButtonBackgroudView{
    if (!_likeButtonBackgroudView) {
        _likeButtonBackgroudView = [[UIView alloc] init];
    }
    return _likeButtonBackgroudView;
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
}

#pragma mark - [ Father Public Methods ]
- (void)setupUI{
    [super setupUI];

    /// 底部UI
    [self addSubview:self.danmuButton];
    [self addSubview:self.guideChatLabel];
    [self addSubview:self.likeButtonBackgroudView];
    [self addSubview:self.landscapeInputView];
    
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
            }
            subview.alpha = alpha;
        }
    };
    [UIView animateWithDuration:0.3 animations:animationBlock];
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
        [self.delegate plvLCLiveRoomPlayerSkinViewDanmuButtonClicked:self userWannaShowDanmu:showDanmu];
    }
}

- (void)rewardButtonAction:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLiveRoomPlayerSkinViewRewardButtonClicked:)]) {
        [self.delegate plvLCLiveRoomPlayerSkinViewRewardButtonClicked:self];
    }
}


#pragma mark - [ Delegate ]
#pragma mark PLVLCLiveRoomLandscapeInputViewDelegate
- (void)plvLCLiveRoomLandscapeInputView:(PLVLCLiveRoomLandscapeInputView *)inputView SendButtonClickedWithSendContent:(NSString *)sendContent{
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLiveRoomPlayerSkinView:userWannaSendChatContent:)]) {
        [self.delegate plvLCLiveRoomPlayerSkinView:self userWannaSendChatContent:sendContent];
    }
}

@end
