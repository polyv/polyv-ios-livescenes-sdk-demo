//
//  PLVLoginViewController.m
//  PolyvLiveScenesDemo
//
//  Created by Hank on 2020/11/4.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLoginViewController.h"

#import <PolyvFoundationSDK/PLVProgressHUD.h>
#import <PLVLiveScenesSDK/PLVSceneLoginManager.h>
#import "PLVLiveSDKConfig.h"

#import "PLVLCCloudClassViewController.h"
#import "PLVECWatchRoomViewController.h"

#define PushOrModel 0 // 进入页面方式（1-push、0-model）
static NSString *kPLVUserDefaultLoginInfoKey = @"kPLVUserDefaultLoginInfoKey_demo";

@interface PLVLoginViewController ()

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

@property (nonatomic, copy) NSString *channelId;
@property (nonatomic, copy) NSString *vid;

@end

@implementation PLVLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configUIData];
    
    [self initUI];
    [self addNotification];
    [self addGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}

- (void)configUIData {
    PLVLiveAccount *accouunt = PLVLiveSDKConfig.sharedSDK.account;
    if (accouunt) { // 从SDK配置中还原
        self.appIDTF.text = accouunt.appId;
        self.userIDTF.text = accouunt.userId;
        self.appSecretTF.text = accouunt.appSecret;
        self.channelIdTF.text = self.channelId;
        self.vIdTF.text = self.vid;
    } else { // 从UserDefault中还原
        [self recoverParamsFromFile];
    }
}

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

- (void)dealloc {
    [self removeNotification];
}

#pragma mark - init
- (void)initUI {
    for (UIView *textField in self.view.subviews) {
        if ([textField isKindOfClass:UITextField.class]) {
            //使用了私有的实现修改UITextField里clearButton的图片
            UIButton *clearButton = [textField valueForKey:@"_clearButton"];
            [clearButton setImage:[UIImage imageNamed:@"plv_clear.png"] forState:UIControlStateNormal];
        }
    }
    
    [self setTFStyle:self.userIDTF];
    [self setTFStyle:self.channelIdTF];
    [self setTFStyle:self.appIDTF];
    [self setTFStyle:self.appSecretTF];
    
    self.liveSelectView.hidden = YES;
    [self switchLiveAction:self.liveBtn];
    self.loginBtn.layer.cornerRadius = self.loginBtn.bounds.size.height * 0.5;
    
    self.btnCloundClass.layer.cornerRadius = self.btnCloundClass.bounds.size.height * 0.5;
    [self.btnCloundClass addTarget:self action:@selector(liveSwitch:) forControlEvents:UIControlEventTouchUpInside];
    
    self.btnLive.layer.cornerRadius = self.btnLive.bounds.size.height * 0.5;
    [self.btnLive addTarget:self action:@selector(liveSwitch:) forControlEvents:UIControlEventTouchUpInside];
    
    [self liveSwitch:self.btnCloundClass];
}

- (void)setTFStyle:(UITextField *)tf {
    NSDictionary *attrs = @{NSForegroundColorAttributeName: [UIColor systemGrayColor]};
    tf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:tf.placeholder attributes:attrs];
    tf.textColor = [UIColor blackColor];
}

#pragma mark - UIViewController+UIViewControllerRotation
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;//登录窗口只支持竖屏方向
}

#pragma mark - Notification
- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - GestureRecognizer
- (void)addGestureRecognizer {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [self.view addGestureRecognizer:tap];
}

- (void)tapAction {
    [self.view endEditing:YES];
}

#pragma mark - IBAction
- (IBAction)switchLiveAction:(UIButton *)sender {
    [self switchToLiveUI];
}

- (IBAction)switchVodAction:(UIButton *)sender {
    [self switchToVodUI];
}

- (IBAction)loginButtonClickAction:(UIButton *)sender {
    [self tapAction];
    [self loginRequest];
}

- (IBAction)textEditChangedAction:(id)sender {
    [self refreshLoginBtnUI];
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

- (IBAction)vodListSwitchChanged:(UISwitch *)sender {
    NSLog(@"%@", sender.isOn ? @"打开点播列表" : @"关闭点播列表");
}

#pragma mark - UI control
- (void)refreshLoginBtnUI {
    if (!self.liveSelectView.hidden) {
        if ([self checkTextField:self.channelIdTF] || [self checkTextField:self.appIDTF] || [self checkTextField:self.userIDTF] || [self checkTextField:self.appSecretTF]) {
            self.loginBtn.enabled = NO;
            self.loginBtn.alpha = 0.4;
        } else {
            self.loginBtn.enabled = YES;
            self.loginBtn.alpha = 1.0;
        }
    } else {
        if ([self checkTextField:self.vIdTF] || [self checkTextField:self.appIDTF] || [self checkTextField:self.userIDTF] || [self checkTextField:self.channelIdTF] ) {
            self.loginBtn.enabled = NO;
            self.loginBtn.alpha = 0.4;
        } else {
            self.loginBtn.enabled = YES;
            self.loginBtn.alpha = 1.0;
        }
    }
}

- (void)switchToLiveUI {
    if (self.liveSelectView.hidden) {
        [self switchScenes:NO];
//        [self configUIData];
        [self refreshLoginBtnUI];
    }
}

- (void)switchToVodUI {
    if (self.vodSelectView.hidden) {
        [self switchScenes:YES];
//        [self configUIData];
        [self refreshLoginBtnUI];
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

- (BOOL)initParams:(BOOL)live {
    if (self.appIDTF.text.length &&self.userIDTF.text.length &&self.appSecretTF.text.length &&self.channelIdTF.text.length) {
        if (!live && !self.vIdTF.text.length) {
            [self showHud:@"回放vid参数不能为空！" detail:nil];
            return NO;
        }
        
        /// 参数配置
        [PLVLiveSDKConfig configAccountWithUserId:self.userIDTF.text appId:self.appIDTF.text appSecret:self.appSecretTF.text];
        self.channelId = self.channelIdTF.text;
        self.vid = self.vIdTF.text;
        
        return YES;
    } else {
        [self showHud:@"参数不能为空！" detail:nil];
        return NO;
    }
}

//#pragma mark - network request
- (void)loginRequest {
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:YES];
    [hud.label setText:@"登录中..."];
    
    [self initParams:!self.liveSelectView.hidden];
    if (!self.liveSelectView.hidden) {
        if (self.btnCloundClass.alpha == 1.0f) {
            [self loginLiveCloudClass:hud];
        } else {
            [self loginLive:hud];
        }
    } else {
        if (self.btnCloundClass.alpha == 1.0f) {
            [self loginLivePlaybackCloudClass:hud];
            //[hud hideAnimated:YES];
            //[self showHud:@"该场景暂不支持三分屏频道类型！" detail:nil];
        } else {
            [self loginVod:hud];
        }
    }
}

#pragma mark -- 登录直播带货场景直播页
- (void)loginLive:(PLVProgressHUD *)hud
{
    PLVLiveAccount *account = PLVLiveSDKConfig.sharedSDK.account;
    // 登录直播带货场景直播页
    __weak typeof(self)weakSelf = self;
    [PLVSceneLoginManager loginLive:self.channelId
                             userId:account.userId
                              appId:account.appId
                          appSecret:account.appSecret
                         completion:^(PLVLiveChannelType channelType, PLVLiveStreamState liveState) {
        [hud hideAnimated:YES];
        [weakSelf saveParamsToFile];
        
        if (channelType != PLVLiveChannelTypeAlone) {
            [weakSelf showHud:@"直播带货场景仅支持普通直播类型频道" detail:nil];
            return;
        }
        
        // 2.配置观看用户及频道信息
        PLVLiveWatchUser *watchUser = [PLVLiveWatchUser watchUserWithViewerId:nil viewerName:nil viewerAvatar:nil viewerType:PLVLiveUserTypeStudent];
        PLVLiveChannelConfig *channel = [PLVLiveChannelConfig channelWithChannelId:self.channelId watchUser:watchUser account:PLVLiveSDKConfig.sharedSDK.account];
        
        // 3.配置直播间信息
        PLVLiveRoomData *roomData = [[PLVLiveRoomData alloc] initWithLiveChannel:channel];
        roomData.liveState = liveState;
        roomData.videoType = PLVWatchRoomVideoType_Live;

        // 4.使用直播间对象初始化直播观看页
        PLVECWatchRoomViewController * watchLiveVC = [[PLVECWatchRoomViewController alloc] initWithLiveRoomData:roomData];

        // 5.进入直播间
        if (PushOrModel) {
            [weakSelf.navigationController pushViewController:watchLiveVC animated:YES];
        }else{
            watchLiveVC.modalPresentationStyle = UIModalPresentationFullScreen;
            [weakSelf presentViewController:watchLiveVC animated:YES completion:nil];
        }
    } failure:^(NSError * _Nonnull error) {
        [hud hideAnimated:YES];
        [weakSelf showHud:@"进入直播间失败！" detail:error.localizedDescription];
    }];
}

#pragma mark -- 登录云课堂场景直播页
- (void)loginLiveCloudClass:(PLVProgressHUD *)hud
{
    PLVLiveAccount *account = PLVLiveSDKConfig.sharedSDK.account;
    // 登录云课堂场景直播页
    __weak typeof(self)weakSelf = self;
    [PLVSceneLoginManager loginLive:self.channelId
                             userId:account.userId
                              appId:account.appId
                          appSecret:account.appSecret
                         completion:^(PLVLiveChannelType channelType, PLVLiveStreamState liveState) {
        [hud hideAnimated:YES];
        [weakSelf saveParamsToFile];
        
        if (channelType != PLVLiveChannelTypePPT) {
            [weakSelf showHud:@"云课堂场景仅支持三分屏类型频道" detail:nil];
            return;
        }
        
        // 2.配置观看用户及频道信息
        PLVLiveWatchUser *watchUser = [PLVLiveWatchUser watchUserWithViewerId:nil viewerName:nil viewerAvatar:nil viewerType:PLVLiveUserTypeSlice];
        PLVLiveChannelConfig *channel = [PLVLiveChannelConfig channelWithChannelId:self.channelId watchUser:watchUser account:PLVLiveSDKConfig.sharedSDK.account];
        
        // 3.配置直播间信息
        PLVLiveRoomData *roomData = [[PLVLiveRoomData alloc] initWithLiveChannel:channel];
        roomData.liveState = liveState;
        roomData.videoType = PLVWatchRoomVideoType_Live;

        // 4.使用直播间对象初始化云课堂观看页
        PLVLCCloudClassViewController * cloudClassVC = [[PLVLCCloudClassViewController alloc] initWithWatchRoomData:roomData];

        // 5.进入云课堂直播间
        if (PushOrModel) {
            [weakSelf.navigationController pushViewController:cloudClassVC animated:YES];
        }else{
            cloudClassVC.modalPresentationStyle = UIModalPresentationFullScreen;
            [weakSelf presentViewController:cloudClassVC animated:YES completion:nil];
        }
    } failure:^(NSError * _Nonnull error) {
        [hud hideAnimated:YES];
        [weakSelf showHud:@"进入直播间失败！" detail:error.localizedDescription];
    }];
}

- (void)loginLivePlaybackCloudClass:(PLVProgressHUD *)hud
{
    PLVLiveAccount *account = PLVLiveSDKConfig.sharedSDK.account;
    
    // 登录 云课堂场景 直播回放页
    __weak typeof(self)weakSelf = self;
    [PLVSceneLoginManager loginPlayback:self.channelId vid:self.vid userId:account.userId appId:account.appId appSecret:account.appSecret completion:^(PLVLiveChannelType channelType) {
        [hud hideAnimated:YES];
        [weakSelf saveParamsToFile];
        
        if (channelType != PLVLiveChannelTypePPT) {
            [weakSelf showHud:@"云课堂场景仅支持三分屏类型频道" detail:nil];
            return;
        }
        
        // 2.配置观看用户及频道信息
        PLVLiveWatchUser *watchUser = [PLVLiveWatchUser watchUserWithViewerId:nil viewerName:nil viewerAvatar:nil viewerType:PLVLiveUserTypeSlice];
        PLVLiveChannelConfig *channel = [PLVLiveChannelConfig channelWithChannelId:self.channelId vid:self.vid watchUser:watchUser account:PLVLiveSDKConfig.sharedSDK.account];

        // 3.配置直播间信息
        PLVLiveRoomData *roomData = [[PLVLiveRoomData alloc] initWithLiveChannel:channel];
        roomData.videoType = PLVWatchRoomVideoType_LivePlayback;
        
        // 4.使用直播间对象初始化云课堂观看页
        PLVLCCloudClassViewController * cloudClassVC = [[PLVLCCloudClassViewController alloc] initWithWatchRoomData:roomData];
                
        // 5.进入云课堂直播间
        if (PushOrModel) {
            [weakSelf.navigationController pushViewController:cloudClassVC animated:YES];
        }else{
            cloudClassVC.modalPresentationStyle = UIModalPresentationFullScreen;
            [weakSelf presentViewController:cloudClassVC animated:YES completion:nil];
        }
    } failure:^(NSError * _Nonnull error) {
        [hud hideAnimated:YES];
        [weakSelf showHud:@"进入直播回放间失败！" detail:error.localizedDescription];
    }];
}




#pragma mark -- 登录直播带货场景回放页
- (void)loginVod:(PLVProgressHUD *)hud
{
    PLVLiveAccount *account = PLVLiveSDKConfig.sharedSDK.account;
    // 登录直播带货场景回放页
    __weak typeof(self)weakSelf = self;
    [PLVSceneLoginManager loginPlayback:self.channelId
                                    vid:self.vid
                                 userId:account.userId
                                  appId:account.appId
                              appSecret:account.appSecret
                             completion:^(PLVLiveChannelType channelType) {
        [hud hideAnimated:YES];
        [weakSelf saveParamsToFile];
        
        if (channelType != PLVLiveChannelTypeAlone) {
            [weakSelf showHud:@"直播带货场景仅支持普通直播类型频道" detail:nil];
            return;
        }
        
        // 2.配置观看用户及频道信息
        PLVLiveWatchUser *watchUser = [PLVLiveWatchUser watchUserWithViewerId:nil viewerName:nil];
        PLVLiveChannelConfig *channel = [PLVLiveChannelConfig channelWithChannelId:self.channelId vid:self.vid watchUser:watchUser account:PLVLiveSDKConfig.sharedSDK.account];
        
        // 3.配置直播间信息
        PLVLiveRoomData *roomData = [[PLVLiveRoomData alloc] initWithLiveChannel:channel];
        roomData.videoType = PLVWatchRoomVideoType_LivePlayback;

        // 4.使用直播间对象初始化回放观看页
        PLVECWatchRoomViewController * watchLiveVC = [[PLVECWatchRoomViewController alloc] initWithLiveRoomData:roomData];

        // 5.进入直播间回放页
        if (PushOrModel) {
            [weakSelf.navigationController pushViewController:watchLiveVC animated:YES];
        }else{
            watchLiveVC.modalPresentationStyle = UIModalPresentationFullScreen;
            [weakSelf presentViewController:watchLiveVC animated:YES completion:nil];
        }
    } failure:^(NSError * _Nonnull error) {
        [hud hideAnimated:YES];
        [weakSelf showHud:@"进入直播回放失败！" detail:error.localizedDescription];
    }];
}

#pragma mark - keyboard control
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

#pragma mark - textfield input validate
- (BOOL)checkTextField:(UITextField *)textField {
    textField.text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (textField.text.length == 0) {
        return YES;
    }
    return NO;
}

#pragma mark - 提示
- (void)showHud:(NSString *)message detail:(NSString *)detail {
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = PLVProgressHUDModeText;
    hud.label.text = message;
    hud.detailsLabel.text = detail;
    [hud hideAnimated:YES afterDelay:3.0];
}

@end
