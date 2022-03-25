//
//  PLVHCChooseCompanyViewController.m
//  PLVLiveScenesDemo
//
//  Created by jiaweihuang on 2021/6/30.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCChooseCompanyViewController.h"

// UI
#import "PLVHCCompanyTableViewCell.h"
#import "PLVHCChooseLessonViewController.h"

// 工具类
#import "PLVHCDemoUtils.h"
#import "PLVHCTeacherLoginManager.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSString *kCompanyKey = @"company";
static NSString *kUserIdKey = @"userId";
static NSString *kSelectedIndexKey = @"selectedIndex";
static NSString *kUserDefaultsLastSelectedIndex = @"UserDefaultsLastSelectedIndex";

@interface PLVHCChooseCompanyViewController ()<UITableViewDelegate, UITableViewDataSource>

// 背景图
@property (nonatomic, strong) UIImageView *backgroundImageView;
// 返回按钮
@property (nonatomic, strong) UIButton *backButton;
// 标题
@property (nonatomic, strong) UILabel *titleLable;
// 公司列表
@property (nonatomic, strong) UITableView *tableView;
// 登录按钮父视图
@property (nonatomic, strong) UIView *bottomView;
// 登录按钮
@property (nonatomic, strong) UIButton *loginButton;
// 登录按钮渐变layer
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

#pragma mark 数据

@property (nonatomic, copy) NSString *mobileString; // 上个登陆页输入的手机号
@property (nonatomic, copy) NSString *passwordString; // 上个登陆页输入的密码
@property (nonatomic, strong) NSArray *companyArray; // 公司列表
@property (nonatomic, assign) NSInteger selectedIndex; // 选中公司的index，一开始初始值设置为-1
@property (nonatomic, assign) BOOL isSelectedCompany; // 是否已经选中上一次选择的公司

@end

@implementation PLVHCChooseCompanyViewController

#pragma mark - [ Life Cycle ]

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.backgroundImageView.frame = self.view.bounds;
    self.backButton.frame = CGRectMake(24, 53, 36, 36);
    self.titleLable.frame = CGRectMake(34, UIViewGetBottom(self.backButton) + 30, 104, 37);
    self.tableView.frame = CGRectMake(0, UIViewGetBottom(self.titleLable) + 20, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - (UIViewGetBottom(self.titleLable) + 20) - 114);
    self.bottomView.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - 114, CGRectGetWidth(self.view.bounds), 114);
    self.loginButton.frame = CGRectMake(30, 32, CGRectGetWidth(self.view.bounds) - 60, 50);
    self.gradientLayer.frame = self.loginButton.bounds;
}

#pragma mark - [ Override ]

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;//只支持竖屏方向
}

#pragma mark - [ Public Method ]

- (instancetype)initWithMobile:(NSString *)mobile
                      password:(NSString *)password
                  companyArray:(NSArray <NSDictionary *> *)companyArray {
    self = [super init];
    if (self) {
        self.mobileString = mobile;
        self.passwordString = password;
        self.companyArray = companyArray;
        self.selectedIndex = -1;
        self.isSelectedCompany = NO;
    }
    return self;
}


#pragma mark - [ Event ]

#pragma mark Action

- (void)backButtonAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)loginButtonAction {
    if (self.selectedIndex < 0
        || self.selectedIndex > self.companyArray.count - 1) {
        return;
    }
    
    NSDictionary *companyDict = self.companyArray[self.selectedIndex];
    if (!companyDict ||
        ![companyDict isKindOfClass:[NSDictionary class]] ||
        [companyDict count] == 0) { // 数据保护
        PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = PLVProgressHUDModeText;
        hud.label.text = @"公司数据出错";
        hud.detailsLabel.text = nil;
        [hud hideAnimated:YES afterDelay:2.0];
        return;
    }
    
    NSString *userId = companyDict[kUserIdKey];
    if (![PLVFdUtil checkStringUseable:userId]) {
        PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = PLVProgressHUDModeText;
        hud.label.text = @"公司数据出错";
        hud.detailsLabel.text = nil;
        [hud hideAnimated:YES afterDelay:2.0];
        return;
    }
    
    [self loginWithUserId:userId];
}

#pragma mark - [ Delegate ]

#pragma mark UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.companyArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *companyDict = self.companyArray[indexPath.row];
    if (![PLVFdUtil checkDictionaryUseable:companyDict]) { // 数据保护
        return [PLVHCCompanyTableViewCell new];
    }
    
    static NSString *identifier = @"PLVHCCompanyTableViewCell";
    PLVHCCompanyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[PLVHCCompanyTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    [cell setCompanyName:companyDict[kCompanyKey]];
    return cell;
}

#pragma mark UITableView Delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    dispatch_async(dispatch_get_main_queue(),^{
        /// 默认选中上一次的公司
        if (!self.isSelectedCompany) {
            self.isSelectedCompany = YES;
            NSDictionary *userInfoDict = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsLastSelectedIndex];
            NSDictionary *indexDict = [userInfoDict objectForKey:self.mobileString];
            if ([PLVFdUtil checkDictionaryUseable:indexDict]) {
                NSInteger lastSelectedIndex = [[indexDict objectForKey:kSelectedIndexKey] integerValue];
                if (lastSelectedIndex < self.companyArray.count) {
                    [tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:lastSelectedIndex inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
                    [self updateSelectedIndex:lastSelectedIndex];
                }
            }
        }
    });
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self updateSelectedIndex:indexPath.row];
    [self saveSelectedIndex:indexPath.row];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *companyDict = self.companyArray[indexPath.row];
    if (!companyDict ||
        ![companyDict isKindOfClass:[NSDictionary class]] ||
        [companyDict count] == 0) { // 数据保护
        return 0;
    }
    
    CGFloat cellHeight = [PLVHCCompanyTableViewCell cellHeightWithText:companyDict[kCompanyKey] cellWidth:self.view.frame.size.width];
    return cellHeight;
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self.view addSubview:self.backgroundImageView];
    [self.view addSubview:self.backButton];
    [self.view addSubview:self.titleLable];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.bottomView];
    
    [self.bottomView addSubview:self.loginButton];
}

// 更新选中索引，同时更新登录按钮的enable状态
- (void)updateSelectedIndex:(NSInteger)index {
    self.selectedIndex = index;
    self.loginButton.enabled = (self.selectedIndex >= 0);
    self.gradientLayer.hidden = !self.loginButton.enabled;
}

// 保存当前选中的公司，下一次初始化列表时要默认选中该公司
- (void)saveSelectedIndex:(NSInteger)index {
    NSDictionary *indexDict = @{kSelectedIndexKey : @(index)};
    NSDictionary *userInfoDict = @{self.mobileString : indexDict};
    [[NSUserDefaults standardUserDefaults] setObject:userInfoDict forKey:kUserDefaultsLastSelectedIndex];
}

#pragma mark Getter & Setter

- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] initWithImage: [PLVHCDemoUtils imageForHiClassResource:@"plvhc_bg_image"]];
    }
    return _backgroundImageView;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [[UIButton alloc] init];
        [_backButton setImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_btn_back"] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UILabel *)titleLable {
    if (!_titleLable) {
        _titleLable = [[UILabel alloc] init];
        _titleLable.text = @"选择公司";
        _titleLable.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:26];
        _titleLable.textColor = [UIColor whiteColor];
    }
    return _titleLable;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}

- (UIButton *)loginButton {
    if (!_loginButton) {
        _loginButton = [[UIButton alloc] init];
        [_loginButton addTarget:self action:@selector(loginButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [_loginButton.layer insertSublayer:self.gradientLayer atIndex:0];
        [_loginButton setTitle:@"登录" forState:UIControlStateNormal];
        _loginButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:16];
        _loginButton.backgroundColor = PLV_UIColorFromRGB(@"#2D3452");
        [_loginButton setTitleColor:PLV_UIColorFromRGBA(@"#FFFFFF",0.5) forState:UIControlStateDisabled];
        [_loginButton setTitleColor:PLV_UIColorFromRGBA(@"#FFFFFF",1) forState:UIControlStateNormal];
         _loginButton.layer.cornerRadius = 25;
        _loginButton.layer.masksToBounds = YES;
        _loginButton.enabled = NO;
    }
    return _loginButton;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)PLV_UIColorFromRGB(@"#00B16C").CGColor, (__bridge id)PLV_UIColorFromRGB(@"#00E78D").CGColor];
        _gradientLayer.locations = @[@0.5, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
        _gradientLayer.hidden = YES;
    }
    return _gradientLayer;
}

- (UIView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
        _bottomView.backgroundColor = [UIColor clearColor];
    }
    return _bottomView;
}

#pragma mark Http Request

// 加上公司的userId再次进行登录请求
- (void)loginWithUserId:(NSString *)userId {
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:YES];
    [hud.label setText:@"登录中..."];
    
    __weak typeof(self) weakSelf = self;
    [PLVLiveVClassAPI teacherLoginWithMobile:self.mobileString password:self.passwordString code:nil userId:userId mutipleCompany:^(NSArray * _Nonnull responseArray) { // 一般来说，不会进入这个block，只有userId为空才有可能进入
        [hud hideAnimated:YES];
        
        [weakSelf updateSelectedIndex:-1];
        weakSelf.companyArray = responseArray;
        [weakSelf.tableView reloadData];
    } success:^(NSDictionary * _Nonnull responseDict, NSArray * _Nonnull lessonArray) {
        [hud hideAnimated:YES];
        
        NSString *viewerId = responseDict[@"viewerId"];
        NSString *viewerName = responseDict[@"nickname"];
        NSString *token = responseDict[@"token"];
        PLVHCTokenLoginModel *loginInfo = [[PLVHCTokenLoginModel alloc] init];
        loginInfo.nickname = viewerName;
        loginInfo.userId = viewerId;
        loginInfo.token = token;
        [PLVHCTeacherLoginManager updateTeacherLoginInfo:loginInfo];

        PLVHCChooseLessonViewController *lessonVC = [[PLVHCChooseLessonViewController alloc] initWithViewerId:viewerId viewerName:viewerName teacher:YES lessonArray:lessonArray];
        lessonVC.userId = userId;
        [weakSelf.navigationController pushViewController:lessonVC animated:YES];
    } failure:^(NSError * _Nonnull error) {
        [hud hideAnimated:YES];
        
        PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:weakSelf.view animated:YES];
        hud.mode = PLVProgressHUDModeText;
        hud.label.text = error.localizedDescription;
        hud.detailsLabel.text = nil;
        [hud hideAnimated:YES afterDelay:2.0];
    }];
}

@end
