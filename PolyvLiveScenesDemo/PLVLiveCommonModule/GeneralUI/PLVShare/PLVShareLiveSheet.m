//
//  PLVShareLiveSheet.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2022/8/1.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVShareLiveSheet.h"
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"
#import "PLVShareLivePosterModel.h"

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <WebKit/WebKit.h>

static CGFloat kShareLiveSheetAnimationDuration = 0.4;
static CGFloat kShareLiveSheetButtonSizeWidth = 48.0;
static CGFloat kShareLiveSheetButtonSizeHeight = 75.0;

typedef NS_ENUM(NSInteger, PLVShareLiveButtonType) {
    PLVShareLiveButtonTypeWXSession = 0,  /**< 分享至聊天界面    */
    PLVShareLiveButtonTypeWXTimeline,     /**< 分享至朋友圈     */
    PLVShareLiveButtonTypeSavePicture,    /**< 保存图片    */
    PLVShareLiveButtonTypeCopyLink,       /**< 复制链接    */
};

@interface PLVShareLiveSheet ()
// UI
@property (nonatomic, strong) UIScrollView *posterScrollView;
@property (nonatomic, strong) WKWebView *posterWebView;
@property (nonatomic, strong) UIView *shareControlsView;// 分享控件视图
@property (nonatomic, strong) UIVisualEffectView *effectView; // 高斯模糊效果图
@property (nonatomic, strong) CALayer *buttonSplitLine; // 退出登录按钮顶部分割线
@property (nonatomic, strong) UIButton *cancelButton;
// 数据
@property (nonatomic, assign) PLVShareLiveSheetSceneType sceneType;
@property (nonatomic, strong) NSMutableArray <UIButton *>*shareButtonArray;
@property (nonatomic, strong) PLVShareLivePosterModel *posterModel;

@end

@implementation PLVShareLiveSheet

#pragma mark - [ Life Cycle ]

- (instancetype)initWithType:(PLVShareLiveSheetSceneType)type {
    self = [super init];
    if (self) {
        _sceneType = type;
        
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL isLandscape = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    CGFloat posterAspectRatio = 0.55; //宽高比
    CGFloat posterTopPadding = 0.0;
    CGFloat posterWebViewHeight = 0.0;
    CGFloat posterWebViewWidth = 0.0;

    if (isLandscape) {
        self.posterScrollView.frame = CGRectMake(0, 0, self.bounds.size.width * 0.65, self.bounds.size.height);
        posterTopPadding = isPad ? 48.0 : 17.0;
        posterWebViewHeight = PLVScreenHeight - posterTopPadding - MAX(posterTopPadding, P_SafeAreaBottomEdgeInsets());
        posterWebViewWidth = posterWebViewHeight * posterAspectRatio;
        self.posterWebView.frame = CGRectMake(CGRectGetMidX(self.posterScrollView.frame) - posterWebViewWidth/2, posterTopPadding, posterWebViewWidth, posterWebViewHeight);
    } else {
        CGFloat scrollViewHeight = self.bounds.size.height - 205;
        CGFloat posterLeftPadding = 38.0;
        if(isPad) {
            posterTopPadding = 48.0;
            posterWebViewHeight = scrollViewHeight - posterTopPadding * 2;
            posterWebViewWidth = posterWebViewHeight * posterAspectRatio;
            posterLeftPadding = (self.bounds.size.width - posterWebViewWidth)/2;
        } else {
            posterWebViewWidth = self.bounds.size.width - posterLeftPadding * 2;
            posterWebViewHeight = posterWebViewWidth / posterAspectRatio;
            posterTopPadding = ((scrollViewHeight - posterWebViewHeight) > (48 + 24)) ? (scrollViewHeight - posterWebViewHeight - 24) : 48;
        }
        self.posterScrollView.frame = CGRectMake(posterLeftPadding, 0, posterWebViewWidth, scrollViewHeight);
        self.posterWebView.frame = CGRectMake(0, posterTopPadding, posterWebViewWidth, posterWebViewHeight);
        self.posterScrollView.contentSize = CGSizeMake(0, CGRectGetHeight(self.posterWebView.frame) + posterTopPadding);
    }
    if (self.sceneType == PLVShareLiveSheetSceneTypeSA) {
        CGFloat cancelBtnOriginY = self.shareControlsView.bounds.size.height - 40 - (isLandscape ? 27 : 34);
        CGFloat cancelBtnWidth = (self.shareControlsView.bounds.size.width > 260 ? 240 : (self.shareControlsView.bounds.size.width - 20));
        self.cancelButton.frame = CGRectMake((self.shareControlsView.bounds.size.width - cancelBtnWidth)/2, cancelBtnOriginY, cancelBtnWidth, 40);
        
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = self.shareControlsView.bounds;
        UIRectCorner corners = isLandscape ? (UIRectCornerTopLeft | UIRectCornerBottomLeft) : (UIRectCornerTopLeft | UIRectCornerTopRight);
        maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.shareControlsView.bounds
                                               byRoundingCorners:corners
                                                     cornerRadii:CGSizeMake(16, 16)].CGPath;
        self.shareControlsView.layer.mask = maskLayer;
    } else {
        self.cancelButton.frame = CGRectMake(0.0, self.bounds.size.height - 48, self.shareControlsView.bounds.size.width, 48);
    }
    self.buttonSplitLine.frame = CGRectMake(16, CGRectGetMinY(self.cancelButton.frame) - 1, CGRectGetWidth(self.cancelButton.bounds) - 16 * 2, 1);

    [self updateShareControlsFrame];
}

#pragma mark - [ Public Method ]

- (void)showInView:(UIView *)parentView {
    if (!parentView) {
        return;
    }
    
    [self requestLivePosterData];
    
    [parentView addSubview:self];
    [parentView insertSubview:self atIndex:parentView.subviews.count - 1];
   
    [self resetWithAnimate];
}

- (void)dismiss {
    if (!self.superview) {
        return;
    }
    
    BOOL isLandscape = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    [UIView animateWithDuration:kShareLiveSheetAnimationDuration animations:^{
        if (isLandscape) {
            self.shareControlsView.frame = CGRectMake(self.bounds.size.width, 0, self.shareControlsView.frame.size.width, self.bounds.size.height);
        } else {
            self.shareControlsView.frame = CGRectMake(0, self.bounds.size.height, self.bounds.size.width, self.shareControlsView.frame.size.height);
        }
        self.effectView.frame = self.shareControlsView.bounds;
        self.posterWebView.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    self.backgroundColor = [PLVColorUtil colorFromHexString:@"#000000" alpha:0.5];
    [self addSubview:self.posterScrollView];
    [self addSubview:self.shareControlsView];
    [self.posterScrollView addSubview:self.posterWebView];
    [self.shareControlsView addSubview:self.effectView];
    [self.shareControlsView addSubview:self.cancelButton];
    [self addShareControls];
    
    if (self.sceneType == PLVShareLiveSheetSceneTypeSA) {
        self.shareControlsView.backgroundColor = [PLVColorUtil colorFromHexString:@"#888888" alpha:0.5];
        self.cancelButton.layer.cornerRadius = 20.0f;
        self.cancelButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#464646" alpha:0.5];
        self.posterWebView.layer.cornerRadius = 16.0f;
    } else {
        [self.shareControlsView.layer addSublayer:self.buttonSplitLine];
        self.posterWebView.layer.cornerRadius = 8.0f;
    }
}

- (void)requestLivePosterData {
    __weak typeof(self) weakSelf = self;
    NSString *channelId = [PLVRoomDataManager sharedManager].roomData.channelId;
    [PLVLiveVideoAPI requestInvitePosterWithChannelId:channelId success:^(NSDictionary * _Nonnull respondDict) {
        NSDictionary *dict = PLV_SafeDictionaryForDictKey(respondDict, @"data");
        if ([PLVFdUtil checkDictionaryUseable:dict]) {
            weakSelf.posterModel = [[PLVShareLivePosterModel alloc] initWithDictionary:dict];
            [weakSelf loadWebView];
        }
    } failure:^(NSError * _Nonnull error) {
        NSLog(@"PLVShareLiveSheet request error: %@", error.localizedDescription);
    }];
}

- (void)loadWebView {
    if ([PLVFdUtil checkStringUseable:self.posterModel.posterURLString]) {
        NSURL *posterURL = [NSURL URLWithString:self.posterModel.posterURLString];
        NSURLRequest *request = [NSURLRequest requestWithURL:posterURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
        [self.posterWebView loadRequest:request];
    }
}

- (void)addShareControls {
    NSArray *buttonTypes = @[@(PLVShareLiveButtonTypeSavePicture),
                            @(PLVShareLiveButtonTypeCopyLink)];
    for (NSInteger index = 0; index < buttonTypes.count; index ++) {
        PLVShareLiveButtonType type = [buttonTypes[index] integerValue];
        UIButton *shareBtn = [self buttonWithShareType:type];
        [self.shareControlsView addSubview:shareBtn];
        [self.shareButtonArray addObject:shareBtn];
    }
}

- (void)updateShareControlsFrame {
    BOOL isLandscape = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    NSInteger buttonCount = self.shareButtonArray.count;
    CGFloat buttonHPadding = 0.0; // button 水平的间距
    CGFloat buttonOriginX = 0.0; // 按钮x坐标
    CGFloat buttonOriginY = 48;

    if (isLandscape) {
        buttonHPadding = (self.shareControlsView.bounds.size.width -
                                    (kShareLiveSheetButtonSizeWidth * 2))/3;
        buttonOriginX = buttonHPadding;
        buttonOriginY = 48;
    } else {
        if (isPad) {
            buttonHPadding = 35;
            buttonOriginX = ((self.shareControlsView.bounds.size.width -
                                 (kShareLiveSheetButtonSizeWidth * buttonCount)) - buttonHPadding * (buttonCount - 1))/2;
        } else {
            buttonHPadding = (self.shareControlsView.bounds.size.width -
                                        (kShareLiveSheetButtonSizeWidth * buttonCount))/(buttonCount + 1);
            buttonOriginX = buttonHPadding;
        }
        buttonOriginY = 32;
    }

    for (NSInteger index = 0; index < self.shareButtonArray.count; index ++) {
        UIButton *button = self.shareButtonArray[index];
        if (isLandscape && (index%2 == 0)) {
            buttonOriginX = buttonHPadding;
            if ((index + 2)/2 != 1) {
                buttonOriginY += (kShareLiveSheetButtonSizeHeight + 36);
            }
        } else if (index != 0) {
            buttonOriginX += (kShareLiveSheetButtonSizeWidth + buttonHPadding);
        }
        button.frame = CGRectMake(buttonOriginX, buttonOriginY, kShareLiveSheetButtonSizeWidth, kShareLiveSheetButtonSizeHeight);
    }
}

- (void)resetWithAnimate {
    BOOL isLandscape = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    self.frame = self.superview.bounds;
    if (isLandscape) {
        self.shareControlsView.frame = CGRectMake(self.bounds.size.width, 0, self.bounds.size.width * 0.35, self.bounds.size.height);
    } else {
        self.shareControlsView.frame = CGRectMake(0, self.bounds.size.height, self.bounds.size.width, 205);
    }
    self.effectView.frame = self.shareControlsView.bounds;
    self.posterWebView.alpha = 0;

    [UIView animateWithDuration:kShareLiveSheetAnimationDuration animations:^{
        if (isLandscape) {
            self.shareControlsView.frame = CGRectMake(self.bounds.size.width - self.shareControlsView.frame.size.width, 0, self.shareControlsView.frame.size.width, self.bounds.size.height);
        } else {
            self.shareControlsView.frame = CGRectMake(0, self.bounds.size.height - self.shareControlsView.frame.size.height, self.bounds.size.width, self.shareControlsView.frame.size.height);
        }
        self.effectView.frame = self.shareControlsView.bounds;
        self.posterWebView.alpha = 1;
    } completion:nil];
}

#pragma mark - Utils

- (UIImage *)createImageWithView:(UIView *)view{
    UIImage *image = [PLVImageUtil imageFromUIView:view opaque:YES scale:[UIScreen mainScreen].scale];
    return image;
}

#pragma mark - Getter

- (UIScrollView *)posterScrollView {
    if (!_posterScrollView) {
        _posterScrollView = [[UIScrollView alloc] init];
        _posterScrollView.showsHorizontalScrollIndicator = NO;
        _posterScrollView.showsVerticalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            _posterScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _posterScrollView;
}

- (WKWebView *)posterWebView {
    if (!_posterWebView) {
        WKUserContentController *userContentController = [[WKUserContentController alloc] init];
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        config.userContentController = userContentController;
        if (@available(iOS 13.0, *)) {
            config.defaultWebpagePreferences.preferredContentMode = WKContentModeMobile;
        }
        if (@available(iOS 14.0, *)) {
            config.defaultWebpagePreferences.allowsContentJavaScript = YES;
        }
        _posterWebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
        _posterWebView.scrollView.backgroundColor = [UIColor clearColor];
        _posterWebView.userInteractionEnabled = NO;
        _posterWebView.layer.masksToBounds = YES;
        if (@available(iOS 11.0, *)) {
            _posterWebView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _posterWebView;
}

- (UIVisualEffectView *)effectView {
    if (!_effectView) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    }
    return _effectView;
}

- (UIView *)shareControlsView {
    if (!_shareControlsView) {
        _shareControlsView = [[UIView alloc] init];
    }
    return _shareControlsView;
}

- (CALayer *)buttonSplitLine {
    if (!_buttonSplitLine) {
        _buttonSplitLine = [[CALayer alloc] init];
        _buttonSplitLine.backgroundColor = [UIColor colorWithRed:0xf0/255.0 green:0xf1/255.0 blue:0xf5/255.0 alpha:0.1].CGColor;
    }
    return _buttonSplitLine;
}

- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
        _cancelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_cancelButton setTitle:PLVLocalizedString(@"取消") forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}

- (NSMutableArray *)shareButtonArray {
    if (!_shareButtonArray) {
        _shareButtonArray = [NSMutableArray arrayWithCapacity:4];
    }
    return _shareButtonArray;
}

- (UIButton *)buttonWithShareType:(PLVShareLiveButtonType)shareType {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0.0, 0.0, kShareLiveSheetButtonSizeWidth, kShareLiveSheetButtonSizeHeight);
    button.titleLabel.font = [UIFont systemFontOfSize:12.0];
    [button setTitleColor:[PLVColorUtil colorFromHexString:@"#979797"] forState:UIControlStateNormal];
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    button.tag = shareType;
    [button addTarget:self action:@selector(shareButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    switch (shareType) {
        case PLVShareLiveButtonTypeWXSession:
            [button setTitle:PLVLocalizedString(@"微信好友") forState:UIControlStateNormal];
            [button setImage:[self imageForShareResource:@"plv_share_wxsession_btn"] forState:UIControlStateNormal];
            break;
        case PLVShareLiveButtonTypeWXTimeline:
            [button setTitle:PLVLocalizedString(@"朋友圈") forState:UIControlStateNormal];
            [button setImage:[self imageForShareResource:@"plv_share_wxtimeline_btn"] forState:UIControlStateNormal];;
            break;
        case PLVShareLiveButtonTypeSavePicture:
            [button setTitle:PLVLocalizedString(@"保存图片") forState:UIControlStateNormal];
            [button setImage:[self imageForShareResource:@"plv_share_savepicture_btn"] forState:UIControlStateNormal];
            break;
        case PLVShareLiveButtonTypeCopyLink:
            [button setTitle:PLVLocalizedString(@"复制链接") forState:UIControlStateNormal];
            [button setImage:[self imageForShareResource:@"plv_share_copylink_btn"] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
    [button setTitleEdgeInsets:UIEdgeInsetsMake(0, - button.imageView.frame.size.width - 12, - button.imageView.frame.size.height - 8, - 12)];
    [button setImageEdgeInsets:UIEdgeInsetsMake(- (kShareLiveSheetButtonSizeHeight - kShareLiveSheetButtonSizeWidth), 0, 0, 0)];
    
    return button;
}

#pragma mark - Utils

- (UIImage *)imageForShareResource:(NSString *)imageName {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSBundle *resourceBundle = [NSBundle bundleWithPath:[bundle pathForResource:@"PLVShare" ofType:@"bundle"]];
    return [UIImage imageNamed:imageName inBundle:resourceBundle compatibleWithTraitCollection:nil];
}

#pragma mark - Action

- (void)cancelButtonAction {
    [self dismiss];
}

- (void)shareButtonAction:(UIButton *)sender {
    PLVShareLiveButtonType type = sender.tag;
    switch (type) {
        case PLVShareLiveButtonTypeWXSession:
            
            break;
        case PLVShareLiveButtonTypeWXTimeline:
            
            break;
        case PLVShareLiveButtonTypeSavePicture:
            [self savePictureButtonAction];
            break;
        case PLVShareLiveButtonTypeCopyLink:
            [self linkCopyButtonAction];
            break;
            
        default:
            break;
    }
}

- (void)savePictureButtonAction {
    UIImage *posterImage = [self createImageWithView:self.posterWebView];
    if (posterImage) {
        UIImageWriteToSavedPhotosAlbum(posterImage, self, @selector(savedPhotoImage:didFinishSavingWithError:contextInfo:), nil);
    }
}

- (void)linkCopyButtonAction {
    if ([PLVFdUtil checkStringUseable:self.posterModel.watchUrl]) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = self.posterModel.watchUrl;
        if (self.delegate && [self.delegate respondsToSelector:@selector(shareLiveSheetCopyLinkFinished:)]) {
            [self.delegate shareLiveSheetCopyLinkFinished:self];
        }
    }
}

- (void)savedPhotoImage:(UIImage*)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (self.delegate && [self.delegate respondsToSelector:@selector(shareLiveSheet:savePictureSuccess:)]) {
        [self.delegate shareLiveSheet:self savePictureSuccess:!error];
    }
}

@end
