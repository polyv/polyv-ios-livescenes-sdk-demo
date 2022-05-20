//
//  PLVLoginViewController.m
//  PLVLiveScenesDemo
//
//  Created by Hank on 2020/11/4.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLiveWatchLoginController.h"

#import <PLVFoundationSDK/PLVProgressHUD.h>
#import "PLVRoomLoginClient.h"
#import "PLVRoomDataManager.h"

#import "PLVLCCloudClassViewController.h"
#import "PLVECWatchRoomViewController.h"
#import "PLVBugReporter.h"

#import <PLVLiveScenesSDK/PLVLivePictureInPictureManager.h>

#define PushOrModel 0 // 进入页面方式（1-push、0-model）
static NSString *kPLVUserDefaultLoginInfoKey = @"kPLVUserDefaultLoginInfoKey_demo";

@interface PLVLiveWatchLoginController ()

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

@property (weak, nonatomic) IBOutlet UISwitch *vodListSwitch;
@property (weak, nonatomic) IBOutlet UILabel *vodListSwitchLabel;

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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}

- (void)dealloc {
    [self removeNotification];
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
    NSLog(@"%@", sender.isOn ? @"打开点播列表" : @"关闭点播列表");
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
            PLVLCCloudClassViewController * cloudClassVC = [[PLVLCCloudClassViewController alloc] init];
            if (PushOrModel) {
                [self.navigationController pushViewController:cloudClassVC animated:YES];
            }else{
                cloudClassVC.modalPresentationStyle = UIModalPresentationFullScreen;
                [self presentViewController:cloudClassVC animated:YES completion:nil];
            }
            
            PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
            [PLVBugReporter setUserIdentifier:roomUser.viewerId];
        };
        
        if (self.liveSelectView.hidden) { // 回放
            [self loginCloudClassPlaybackRoomWithChannelType:PLVChannelTypePPT | PLVChannelTypeAlone successHandler:successBlock];
        } else { // 直播
            // 如果当前正在开启系统画中画，那么需要不走恢复逻辑关闭画中画
            if ([PLVLivePictureInPictureManager sharedInstance].pictureInPictureActive) {
                [PLVLivePictureInPictureManager sharedInstance].restoreDelegate = nil;
                [[PLVLivePictureInPictureManager sharedInstance] stopPictureInPicture];
            }
            [self loginCloudClassLiveRoomWithChannelType:PLVChannelTypePPT | PLVChannelTypeAlone successHandler:successBlock];
        }
    } else { // 直播带货场景
        void(^successBlock)(void) = ^() { // 登录成功页面跳转回调
            PLVECWatchRoomViewController * watchLiveVC = [[PLVECWatchRoomViewController alloc] init];
            if (PushOrModel) {
                [self.navigationController pushViewController:watchLiveVC animated:YES];
            }else{
                watchLiveVC.modalPresentationStyle = UIModalPresentationFullScreen;
                [self presentViewController:watchLiveVC animated:YES completion:nil];
            }
            
            PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
            [PLVBugReporter setUserIdentifier:roomUser.viewerId];
        };
        
        if (self.liveSelectView.hidden) { // 回放
            [self loginEcommercePlaybackRoomWithChannelType:PLVChannelTypeAlone successHandler:successBlock];
        } else { // 直播
            // 如果当前正在开启系统画中画，那么需要不走恢复逻辑关闭画中画
            if ([PLVLivePictureInPictureManager sharedInstance].pictureInPictureActive) {
                [PLVLivePictureInPictureManager sharedInstance].restoreDelegate = nil;
                [[PLVLivePictureInPictureManager sharedInstance] stopPictureInPicture];
            }
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
        // 可在此处配置自定义的登陆用户ID、昵称、头像，不配则均使用默认值
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
        // 可在此处配置自定义的登陆用户ID、昵称、头像，不配则均使用默认值
//        roomUser.viewerId = @"用户ID";
//        roomUser.viewerName = @"用户昵称";
//        roomUser.viewerAvatar = @"用户头像";
    } completion:^(PLVViewLogCustomParam * _Nonnull customParam) {
        [hud hideAnimated:YES];
        if([PLVRoomDataManager sharedManager].roomData.channelType == PLVChannelTypePPT && weakSelf.vodListSwitch.isOn)
        {
            [weakSelf showHud:@"三分屏场景暂不支持使用点播列表播放" detail:nil];
            return;
        }
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
        // 可在此处配置自定义的登陆用户ID、昵称、头像，不配则均使用默认值
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
        // 可在此处配置自定义的登陆用户ID、昵称、头像，不配则均使用默认值
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

@end
