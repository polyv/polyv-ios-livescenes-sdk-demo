//
//  PLVLoginViewController.m
//  PLVLiveScenesDemo
//
//  Created by Hank on 2020/11/4.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLiveWatchLoginController.h"

#import <PLVFoundationSDK/PLVProgressHUD.h>
#import <AVFoundation/AVFoundation.h>
#import "PLVRoomLoginClient.h"
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"
#import "PLVMultiMeetingManager.h"

#import "PLVLCCloudClassViewController.h"
#import "PLVECWatchRoomViewController.h"
#import "PLVBugReporter.h"

#import <PLVLiveScenesSDK/PLVLivePictureInPictureManager.h>
#import "PLVLivePictureInPictureRestoreManager.h"

#define PushOrModel 0 // 进入页面方式（1-push、0-model）
static NSString *kPLVUserDefaultLoginInfoKey = @"kPLVUserDefaultLoginInfoKey_demo";

@interface PLVLiveWatchLoginController () <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIImageView *logoImgView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIButton *liveBtn;
@property (nonatomic, weak) IBOutlet UIView *liveSelectView;
@property (nonatomic, weak) IBOutlet UIButton *vodBtn;
@property (nonatomic, weak) IBOutlet UIView *vodSelectView;
@property (nonatomic, weak) IBOutlet UITextField *channelIdTF;
@property (nonatomic, weak) IBOutlet UITextField *appIDTF;
@property (nonatomic, weak) IBOutlet UITextField *userIDTF;
@property (nonatomic, weak) IBOutlet UIView *userLineView;
@property (nonatomic, weak) IBOutlet UITextField *appSecretTF;
@property (nonatomic, weak) IBOutlet UIView *appSecretLineView;
@property (nonatomic, weak) IBOutlet UITextField *vIdTF;
@property (nonatomic, weak) IBOutlet UIView *vidLineView;
@property (nonatomic, weak) IBOutlet UIButton *loginBtn;

@property (nonatomic, weak) IBOutlet UIButton *btnCloundClass;
@property (nonatomic, weak) IBOutlet UIButton *btnLive;
@property (nonatomic, weak) IBOutlet UIButton *backButton;

@property (weak, nonatomic) IBOutlet UISwitch *vodListSwitch;
@property (weak, nonatomic) IBOutlet UILabel *vodListSwitchLabel;

@property (nonatomic, weak) UIViewController *liveViewController;

// 扫码相关属性
@property (nonatomic, strong) UIButton *qrCodeScanButton;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) UIView *scannerView;

@end

@implementation PLVLiveWatchLoginController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initUI];
    
    [self recoverParamsFromFile];
    
    [self addNotification];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [self.view addGestureRecognizer:tap];
    
    __weak typeof(self) weakSelf = self;
    [PLVMultiLanguageManager sharedManager].languageUpdateCallback = ^{
        if (weakSelf.liveViewController) {
            if ([weakSelf.liveViewController isKindOfClass:PLVLCCloudClassViewController.class]) {
                [(PLVLCCloudClassViewController *)weakSelf.liveViewController exitCleanCurrentLiveController];
                [weakSelf loginRequest];
            } else if ([weakSelf.liveViewController isKindOfClass:PLVECWatchRoomViewController.class]) {
                [(PLVECWatchRoomViewController *)weakSelf.liveViewController exitCleanCurrentLiveController];
                [weakSelf loginRequest];
            }
        }
    };
    
    [PLVMultiMeetingManager sharedManager].jumpCallback = ^(NSString *_Nonnull channelId, BOOL isPlayback) {
        if (weakSelf.liveViewController) {
            if ([weakSelf.liveViewController isKindOfClass:PLVLCCloudClassViewController.class]) {
                [(PLVLCCloudClassViewController *)weakSelf.liveViewController exitCleanCurrentLiveController];
                weakSelf.channelIdTF.text = channelId;
                if (isPlayback) {
                    [weakSelf switchToVodUI];
                } else {
                    [weakSelf switchToLiveUI];
                }
                weakSelf.vIdTF.text = @"";
                [weakSelf loginRequest];
            }
        }
    };
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    // 检查当前方向并强制切换到竖屏
    // 适配iphoneSE 8P 等部分机型
    BOOL isLandscape = self.view.bounds.size.width > self.view.bounds.size.height;
    if (isLandscape) {
        // 强制切换到竖屏
        [PLVFdUtil changeDeviceOrientation:UIDeviceOrientationPortrait];
    }
}

- (void)dealloc {
    [self removeNotification];
    [self stopQRCodeScanning];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;//登录窗口只支持竖屏方向
}

#pragma mark - UI

- (void)initUI {
    for (UIView *textField in self.view.subviews) {
        if ([textField isKindOfClass:UITextField.class]) {
            //使用了私有的实现修改UITextField里clearButton的图片
            UIButton *clearButton = [textField valueForKey:@"_clearButton"];
            [clearButton setImage:[UIImage imageNamed:@"plvlw_login_clear.png"] forState:UIControlStateNormal];
        }
    }
    
    [self setTFStyle:self.userIDTF];
    [self setTFStyle:self.channelIdTF];
    [self setTFStyle:self.appIDTF];
    [self setTFStyle:self.appSecretTF];
    [self setTFStyle:self.vIdTF];
    
    self.liveSelectView.hidden = YES;
    [self switchLiveAction:self.liveBtn];
    self.loginBtn.layer.cornerRadius = self.loginBtn.bounds.size.height * 0.5;
    
    self.btnCloundClass.layer.cornerRadius = self.btnCloundClass.bounds.size.height * 0.5;
    [self.btnCloundClass addTarget:self action:@selector(liveSwitch:) forControlEvents:UIControlEventTouchUpInside];
    
    self.btnLive.layer.cornerRadius = self.btnLive.bounds.size.height * 0.5;
    [self.btnLive addTarget:self action:@selector(liveSwitch:) forControlEvents:UIControlEventTouchUpInside];
    
    [self liveSwitch:self.btnCloundClass];
//    [self liveSwitch:self.btnLive];
    
    // 创建扫码按钮
    [self setupQRCodeScanButton];
}

- (void)setTFStyle:(UITextField *)tf {
    NSDictionary *attrs = @{NSForegroundColorAttributeName: [UIColor systemGrayColor]};
    tf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:tf.placeholder attributes:attrs];
    tf.textColor = [UIColor blackColor];
}

- (BOOL)checkTextField:(UITextField *)textField {
    textField.text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (textField.text.length == 0) {
        return YES;
    }
    return NO;
}

- (void)switchToLiveUI {
    if (self.liveSelectView.hidden) {
        [self switchScenes:NO];    }
}

- (void)switchToVodUI {
    if (self.vodSelectView.hidden) {
        [self switchScenes:YES];
    }
}

- (void)switchScenes:(BOOL)flag {
    self.liveSelectView.hidden = flag;
    
    // --------- btnCloundClass约束调整 start -------------
    // 移除btnCloundClass约束
    for (NSLayoutConstraint *constraint in self.btnCloundClass.superview.constraints) {
        if (constraint.firstItem == self.btnCloundClass
            && (constraint.firstAttribute == NSLayoutAttributeCenterX || constraint.firstAttribute == NSLayoutAttributeLeading)) {
            [self.btnCloundClass.superview removeConstraint:constraint];
            break;
        }
    }

    // 添加btnCloundClass约束
    NSLayoutAttribute attribute = flag ? NSLayoutAttributeLeading : NSLayoutAttributeCenterX;
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.btnCloundClass
                                                                  attribute:attribute
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.loginBtn
                                                                  attribute:attribute
                                                                 multiplier:1.0
                                                                   constant:0];
    [self.btnCloundClass.superview addConstraint:constraint];
    // --------- btnCloundClass约束调整 end -------------
    
    self.vodSelectView.hidden = !flag;
    self.vidLineView.hidden = self.vIdTF.hidden = !flag;
    self.vodListSwitch.hidden = !flag;
    self.vodListSwitchLabel.hidden = !flag;
}

#pragma mark - Notification

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    [self followKeyboardAnimation:UIEdgeInsetsMake(-110.0, 0.0, 110.0, 0.0) duration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] flag:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self followKeyboardAnimation:UIEdgeInsetsZero duration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] flag:NO];
}

- (void)followKeyboardAnimation:(UIEdgeInsets)contentInsets duration:(NSTimeInterval)duration flag:(BOOL)flag {
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:MAX(0.0, duration - 0.1) animations:^{
            weakSelf.logoImgView.hidden = flag;
            weakSelf.titleLabel.hidden = !flag;
            weakSelf.scrollView.contentInset = contentInsets;
            weakSelf.scrollView.scrollIndicatorInsets = contentInsets;
        }];
    });
}

#pragma mark - Action

- (void)tapAction {
    [self.view endEditing:YES];
}

- (IBAction)switchLiveAction:(UIButton *)sender {
    [self switchToLiveUI];
}

- (IBAction)switchVodAction:(UIButton *)sender {
    [self switchToVodUI];
}

- (void)liveSwitch:(UIButton *)button
{
    if (button == self.btnCloundClass) {
        self.btnCloundClass.enabled = NO;
        self.btnCloundClass.alpha = 1.0;
        
        self.btnLive.enabled = YES;
        self.btnLive.alpha = 0.4;
    } else if (button == self.btnLive) {
        self.btnCloundClass.enabled = YES;
        self.btnCloundClass.alpha = 0.4;
        
        self.btnLive.enabled = NO;
        self.btnLive.alpha = 1.0;
    }
}

- (IBAction)loginButtonClickAction:(UIButton *)sender {
    [self tapAction];
    [self loginRequest];
}

- (IBAction)vodListSwitchChanged:(UISwitch *)sender {
    PLV_LOG_INFO(PLVConsoleLogModuleTypeVerbose,@"%@", sender.isOn ? @"打开点播列表" : @"关闭点播列表");
}

- (IBAction)backAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 登录

- (void)loginRequest {
    BOOL paramValid = [self initParams:!self.liveSelectView.hidden];
    if (!paramValid) {
        [self showHud:@"参数不能为空！" detail:nil];
        return;
    }
    
    if (self.btnCloundClass.alpha == 1.0f) { // 云课堂场景
        void(^successBlock)(void) = ^() { // 登录成功页面跳转回调
            // 解开下列注释开启防录屏
            /*
            [PLVRoomDataManager sharedManager].roomData.captureScreenProtect = YES;
            [PLVRoomDataManager sharedManager].roomData.fullScreenProtectWhenCaptureScreen = YES; // 开启全屏防录屏保护
            [PLVRoomDataManager sharedManager].roomData.systemScreenShotProtect = YES; // 系统截图保护，禁止截图
            */
            
            PLVLCCloudClassViewController * cloudClassVC = [[PLVLCCloudClassViewController alloc] init];
            if (PushOrModel) {
                [self.navigationController pushViewController:cloudClassVC animated:YES];
            }else{
                cloudClassVC.modalPresentationStyle = UIModalPresentationFullScreen;
                [self presentViewController:cloudClassVC animated:YES completion:nil];
            }
            self.liveViewController = cloudClassVC;
            
            PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
            [PLVBugReporter setUserIdentifier:roomUser.viewerId];
        };
        
        // 如果当前正在开启系统画中画
        if ([PLVLivePictureInPictureManager sharedInstance].pictureInPictureActive) {
            if ([PLVFdUtil checkStringUseable:self.channelIdTF.text] &&
                [[PLVRoomDataManager sharedManager].roomData.channelId isEqualToString:self.channelIdTF.text] &&
                [[PLVLivePictureInPictureRestoreManager sharedInstance].holdingViewController isKindOfClass:[PLVLCCloudClassViewController class]]){
                // 同一直播间,不走登入流程;  关闭画中画,恢复直播间
                [[PLVLivePictureInPictureManager sharedInstance] stopPictureInPicture];
                return;
            }
            else{
                // 不同直播间,关闭并清理, 走登入流程
                [PLVLivePictureInPictureManager sharedInstance].restoreDelegate = nil;
                [[PLVLivePictureInPictureRestoreManager sharedInstance] cleanRestoreManager];
                [[PLVLivePictureInPictureManager sharedInstance] stopPictureInPicture];
            }
            
        }
        if (self.liveSelectView.hidden) { // 回放
            [self loginCloudClassPlaybackRoomWithChannelType:PLVChannelTypePPT | PLVChannelTypeAlone successHandler:successBlock];
        } else { // 直播
            [self loginCloudClassLiveRoomWithChannelType:PLVChannelTypePPT | PLVChannelTypeAlone successHandler:successBlock];
        }
    } else { // 直播带货场景
        void(^successBlock)(void) = ^() { // 登录成功页面跳转回调
            // 解开下列注释开启防录屏 防系统截屏功能
            /*
            [PLVRoomDataManager sharedManager].roomData.captureScreenProtect = YES;
            [PLVRoomDataManager sharedManager].roomData.fullScreenProtectWhenCaptureScreen = YES; // 开启全屏防录屏保护
            [PLVRoomDataManager sharedManager].roomData.systemScreenShotProtect = YES; // 系统截图保护，禁止截图
            */
            PLVECWatchRoomViewController * watchLiveVC = [[PLVECWatchRoomViewController alloc] init];
            watchLiveVC.fullScreenButtonShowOnIpad = YES;
            if (PushOrModel) {
                [self.navigationController pushViewController:watchLiveVC animated:YES];
            }else{
                watchLiveVC.modalPresentationStyle = UIModalPresentationFullScreen;
                [self presentViewController:watchLiveVC animated:YES completion:nil];
            }
            self.liveViewController = watchLiveVC;
            
            PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
            [PLVBugReporter setUserIdentifier:roomUser.viewerId];
        };
        
        // 如果当前正在开启系统画中画
        if ([PLVLivePictureInPictureManager sharedInstance].pictureInPictureActive) {
            if ([PLVFdUtil checkStringUseable:self.channelIdTF.text] &&
                [[PLVRoomDataManager sharedManager].roomData.channelId isEqualToString:self.channelIdTF.text] &&
                [[PLVLivePictureInPictureRestoreManager sharedInstance].holdingViewController isKindOfClass:[PLVECWatchRoomViewController class]]){
                // 同一直播间,不走登入流程;  关闭画中画,恢复直播间
                [[PLVLivePictureInPictureManager sharedInstance] stopPictureInPicture];
                return;
            }
            else{
                // 不同直播间,关闭并清理,走登入流程
                [PLVLivePictureInPictureManager sharedInstance].restoreDelegate = nil;
                [[PLVLivePictureInPictureRestoreManager sharedInstance] cleanRestoreManager];
                [[PLVLivePictureInPictureManager sharedInstance] stopPictureInPicture];
            }
            
        }
        if (self.liveSelectView.hidden) { // 回放
            [self loginEcommercePlaybackRoomWithChannelType:PLVChannelTypeAlone successHandler:successBlock];
        } else { // 直播
            [self loginEcommerceLiveRoomWithChannelType:PLVChannelTypeAlone successHandler:successBlock];
        }
    }
}

- (BOOL)initParams:(BOOL)live {
    if (!self.appIDTF.text || self.appIDTF.text.length == 0 ||
        !self.userIDTF.text || self.userIDTF.text.length == 0 ||
        !self.appSecretTF.text || self.appSecretTF.text.length == 0 ||
        !self.channelIdTF.text || self.channelIdTF.text.length == 0) {
        return NO;
    }
    return YES;
}

- (void)showHud:(NSString *)message detail:(NSString *)detail {
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = PLVProgressHUDModeText;
    hud.label.text = message;
    hud.detailsLabel.text = detail;
    [hud hideAnimated:YES afterDelay:3.0];
}

/// 云课堂场景-直播间
- (void)loginCloudClassLiveRoomWithChannelType:(PLVChannelType)channelType
                                successHandler:(void (^)(void))successHandler {
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    [hud.label setText:@"登录中..."];
    
    __weak typeof(self)weakSelf = self;
    [PLVRoomLoginClient loginLiveRoomWithChannelType:channelType
                                           channelId:self.channelIdTF.text
                                              userId:self.userIDTF.text
                                               appId:self.appIDTF.text
                                           appSecret:self.appSecretTF.text
                                            roomUser:^(PLVRoomUser * _Nonnull roomUser) {
        // 可在此处配置自定义的登录用户ID、昵称、头像，不配则均使用默认值
//        roomUser.viewerId = @"用户ID";
//        roomUser.viewerName = @"用户昵称";
//        roomUser.viewerAvatar = @"用户头像";
    } completion:^(PLVViewLogCustomParam * _Nonnull customParam) {
        [hud hideAnimated:YES];
        [weakSelf saveParamsToFile];
        
        if (successHandler) {
            successHandler();
        }
    } failure:^(NSString * _Nonnull errorMessage) {
        [hud hideAnimated:YES];
        [weakSelf showHud:errorMessage detail:nil];
    }];
}

/// 云课堂场景-直播回放
- (void)loginCloudClassPlaybackRoomWithChannelType:(PLVChannelType)channelType
                                    successHandler:(void (^)(void))successHandler {
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    [hud.label setText:@"登录中..."];
    
    __weak typeof(self)weakSelf = self;
    [PLVRoomLoginClient loginPlaybackRoomWithChannelType:channelType
                                               channelId:self.channelIdTF.text
                                                 vodList:self.vodListSwitch.isOn
                                                     vid:self.vIdTF.text
                                                  userId:self.userIDTF.text
                                                   appId:self.appIDTF.text
                                               appSecret:self.appSecretTF.text
                                                roomUser:^(PLVRoomUser * _Nonnull roomUser) {
        // 可在此处配置自定义的登录用户ID、昵称、头像，不配则均使用默认值
//        roomUser.viewerId = @"用户ID";
//        roomUser.viewerName = @"用户昵称";
//        roomUser.viewerAvatar = @"用户头像";
    } completion:^(PLVViewLogCustomParam * _Nonnull customParam) {
        [hud hideAnimated:YES];
        [weakSelf saveParamsToFile];
        
        if (successHandler) {
            successHandler();
        }
    } failure:^(NSString * _Nonnull errorMessage) {
        [hud hideAnimated:YES];
        [weakSelf showHud:errorMessage detail:nil];
    }];
}

/// 直播带货场景-直播间
- (void)loginEcommerceLiveRoomWithChannelType:(PLVChannelType)channelType
                               successHandler:(void (^)(void))successHandler {
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    [hud.label setText:@"登录中..."];
    
    __weak typeof(self)weakSelf = self;
    [PLVRoomLoginClient loginLiveRoomWithChannelType:channelType
                                           channelId:self.channelIdTF.text
                                              userId:self.userIDTF.text
                                               appId:self.appIDTF.text
                                           appSecret:self.appSecretTF.text
                                            roomUser:^(PLVRoomUser * _Nonnull roomUser) {
        // 可在此处配置自定义的登录用户ID、昵称、头像，不配则均使用默认值
//        roomUser.viewerId = @"用户ID";
//        roomUser.viewerName = @"用户昵称";
//        roomUser.viewerAvatar = @"用户头像";
    } completion:^(PLVViewLogCustomParam * _Nonnull customParam) {
        [hud hideAnimated:YES];
        [weakSelf saveParamsToFile];
        
        if (successHandler) {
            successHandler();
        }
    } failure:^(NSString * _Nonnull errorMessage) {
        [hud hideAnimated:YES];
        [weakSelf showHud:errorMessage detail:nil];
    }];
}

/// 直播带货场景-直播回放
- (void)loginEcommercePlaybackRoomWithChannelType:(PLVChannelType)channelType
                                   successHandler:(void (^)(void))successHandler {
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    [hud.label setText:@"登录中..."];
    
    __weak typeof(self)weakSelf = self;
    [PLVRoomLoginClient loginPlaybackRoomWithChannelType:channelType
                                               channelId:self.channelIdTF.text
                                                 vodList:self.vodListSwitch.isOn
                                                     vid:self.vIdTF.text
                                                  userId:self.userIDTF.text
                                                   appId:self.appIDTF.text
                                               appSecret:self.appSecretTF.text
                                                roomUser:^(PLVRoomUser * _Nonnull roomUser) {
        // 可在此处配置自定义的登录用户ID、昵称、头像，不配则均使用默认值
//        roomUser.viewerId = @"用户ID";
//        roomUser.viewerName = @"用户昵称";
//        roomUser.viewerAvatar = @"用户头像";
    } completion:^(PLVViewLogCustomParam * _Nonnull customParam) {
        [hud hideAnimated:YES];
        [weakSelf saveParamsToFile];
        
        if (successHandler) {
            successHandler();
        }
    } failure:^(NSString * _Nonnull errorMessage) {
        [hud hideAnimated:YES];
        [weakSelf showHud:errorMessage detail:nil];
    }];
    
}

#pragma mark - 读写缓存账号信息

- (void)recoverParamsFromFile {
    NSArray *loginInfo = [[NSUserDefaults standardUserDefaults] objectForKey:kPLVUserDefaultLoginInfoKey];
    if (loginInfo.count < 5) {
        return;
    }
    self.appIDTF.text = loginInfo[0];
    self.userIDTF.text = loginInfo[1];
    self.appSecretTF.text = loginInfo[2];
    self.channelIdTF.text = loginInfo[3];
    self.vIdTF.text = loginInfo[4];
}

- (void)saveParamsToFile {
    [[NSUserDefaults standardUserDefaults] setObject:@[self.appIDTF.text, self.userIDTF.text, self.appSecretTF.text, self.channelIdTF.text, self.vIdTF.text] forKey:kPLVUserDefaultLoginInfoKey];
}

#pragma mark - 扫码功能

/// 创建扫码按钮
- (void)setupQRCodeScanButton {
    self.qrCodeScanButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.qrCodeScanButton setTitle:@"扫码配置" forState:UIControlStateNormal];
    [self.qrCodeScanButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.qrCodeScanButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:1.0];
    self.qrCodeScanButton.layer.cornerRadius = 8.0;
    self.qrCodeScanButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.qrCodeScanButton addTarget:self action:@selector(qrCodeScanButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    self.qrCodeScanButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.qrCodeScanButton];
    
    // 设置约束：固定在屏幕底部
    [NSLayoutConstraint activateConstraints:@[
        [self.qrCodeScanButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.qrCodeScanButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20],
        [self.qrCodeScanButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:40],
        [self.qrCodeScanButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-40],
        [self.qrCodeScanButton.heightAnchor constraintEqualToConstant:44]
    ]];
}

/// 扫码按钮点击事件
- (void)qrCodeScanButtonAction:(UIButton *)sender {
    [self checkCameraPermissionAndStartScan];
}

/// 检查相机权限并开始扫描
- (void)checkCameraPermissionAndStartScan {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if (status == AVAuthorizationStatusAuthorized) {
        // 已授权，直接开始扫描
        [self startQRCodeScanning];
    } else if (status == AVAuthorizationStatusNotDetermined) {
        // 未请求过权限，请求权限
        __weak typeof(self) weakSelf = self;
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted) {
                    [weakSelf startQRCodeScanning];
                } else {
                    [weakSelf showHud:@"需要相机权限才能扫描二维码" detail:@"请在设置中开启相机权限"];
                }
            });
        }];
    } else if (status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
        // 权限被拒绝或受限
        [self showHud:@"相机权限未开启" detail:@"请在设置-隐私-相机中开启权限"];
    }
}

/// 开始二维码扫描
- (void)startQRCodeScanning {
    // 创建扫描器视图
    self.scannerView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.scannerView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.scannerView];
    
    // 创建 AVCaptureSession
    self.captureSession = [[AVCaptureSession alloc] init];
    
    // 获取摄像头设备
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!captureDevice) {
        [self showHud:@"无法访问摄像头" detail:nil];
        [self.scannerView removeFromSuperview];
        return;
    }
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (error || !input) {
        [self showHud:@"摄像头初始化失败" detail:error.localizedDescription];
        [self.scannerView removeFromSuperview];
        return;
    }
    
    [self.captureSession addInput:input];
    
    // 创建输出对象
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    [self.captureSession addOutput:output];
    
    // 设置代理并指定处理队列
    dispatch_queue_t queue = dispatch_queue_create("com.polyv.qrCodeScanQueue", DISPATCH_QUEUE_SERIAL);
    [output setMetadataObjectsDelegate:self queue:queue];
    
    // 设置元数据类型为二维码
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    
    // 创建预览层
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.previewLayer.frame = self.scannerView.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.scannerView.layer addSublayer:self.previewLayer];
    
    // 添加关闭按钮
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [closeButton setTitle:@"取消" forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeButton.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    closeButton.layer.cornerRadius = 8.0;
    closeButton.frame = CGRectMake(20, 44, 80, 40);
    [closeButton addTarget:self action:@selector(stopQRCodeScanning) forControlEvents:UIControlEventTouchUpInside];
    [self.scannerView addSubview:closeButton];
    
    // 添加扫描提示
    UILabel *tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(closeButton.frame) + 20, self.scannerView.bounds.size.width, 60)];
    tipLabel.text = @"将二维码放入框内\n即可自动扫描";
    tipLabel.textColor = [UIColor whiteColor];
    tipLabel.textAlignment = NSTextAlignmentCenter;
    tipLabel.numberOfLines = 2;
    tipLabel.font = [UIFont systemFontOfSize:16];
    [self.scannerView addSubview:tipLabel];
    
    // 添加扫描框
    CGFloat scanSize = 250;
    CGFloat scanX = (self.scannerView.bounds.size.width - scanSize) / 2.0;
    CGFloat scanY = (self.scannerView.bounds.size.height - scanSize) / 2.0;
    UIView *scanFrame = [[UIView alloc] initWithFrame:CGRectMake(scanX, scanY, scanSize, scanSize)];
    scanFrame.layer.borderColor = [UIColor greenColor].CGColor;
    scanFrame.layer.borderWidth = 2.0;
    [self.scannerView addSubview:scanFrame];
    
    // 启动扫描
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.captureSession startRunning];
    });
}

/// 停止二维码扫描
- (void)stopQRCodeScanning {
    if (self.captureSession) {
        [self.captureSession stopRunning];
        self.captureSession = nil;
    }
    
    if (self.previewLayer) {
        [self.previewLayer removeFromSuperlayer];
        self.previewLayer = nil;
    }
    
    if (self.scannerView) {
        [self.scannerView removeFromSuperview];
        self.scannerView = nil;
    }
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects.firstObject;
        if ([metadataObject.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            NSString *qrCodeString = metadataObject.stringValue;
            
            // 回到主线程处理
            dispatch_async(dispatch_get_main_queue(), ^{
                [self stopQRCodeScanning];
                [self parseQRCodeString:qrCodeString];
            });
        }
    }
}

/// 解析二维码字符串并填充参数
- (void)parseQRCodeString:(NSString *)qrCodeString {
    if (!qrCodeString || qrCodeString.length == 0) {
        [self showHud:@"二维码内容为空" detail:nil];
        return;
    }
    
    // 解析 JSON
    NSData *jsonData = [qrCodeString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (error || !jsonDict) {
        [self showHud:@"二维码格式错误" detail:@"无法解析JSON数据"];
        return;
    }
    
    // 获取 params 字典
    NSDictionary *params = jsonDict[@"params"];
    if (!params || ![params isKindOfClass:[NSDictionary class]]) {
        [self showHud:@"配置格式错误" detail:@"缺少 params 字段"];
        return;
    }
    
    // 直接读取字段并填充
    NSString *channelId = params[@"liveChannelId"];
    NSString *userId = params[@"liveUserId"];
    NSString *appId = params[@"liveAppId"];
    NSString *appSecret = params[@"liveAppSecret"];
    NSString *videoId = params[@"playbackVideoId"];
    
    if ([self isValidString:channelId]) {
        self.channelIdTF.text = channelId;
    }
    if ([self isValidString:userId]) {
        self.userIDTF.text = userId;
    }
    if ([self isValidString:appId]) {
        self.appIDTF.text = appId;
    }
    if ([self isValidString:appSecret]) {
        self.appSecretTF.text = appSecret;
    }
    if ([self isValidString:videoId]) {
        self.vIdTF.text = videoId;
    }
    
    [self showHud:@"配置加载成功" detail:nil];
}

/// 检查字符串是否有效
- (BOOL)isValidString:(NSString *)string {
    return string && [string isKindOfClass:[NSString class]] && string.length > 0;
}

@end
