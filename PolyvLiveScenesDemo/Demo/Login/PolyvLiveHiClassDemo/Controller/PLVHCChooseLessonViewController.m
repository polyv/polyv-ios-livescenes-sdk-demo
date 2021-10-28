//
//  PLVHCChooseClassViewController.m
//  PolyvLiveScenesDemo
//
//  Created by jiaweihuang on 2021/7/1.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCChooseLessonViewController.h"

// UI
#import "PLVHCHiClassViewController.h"
#import "PLVHCLessonTableViewCell.h"
#import "PLVHCTeacherLogoutAlertView.h"

// 工具类
#import "PLVHCDemoUtils.h"
#import "PLVHCTeacherLoginManager.h"

// 模块
#import "PLVRoomLoginClient.h"
#import "PLVBugReporter.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCChooseLessonViewController ()<UITableViewDelegate, UITableViewDataSource>

#pragma mark UI

@property (nonatomic, strong) UILabel *titleLabel; // 标题
@property (nonatomic, strong) UIButton *backButton; // 返回按钮
@property (nonatomic, strong) UIImageView *backgroundImageView; // 背景图
@property (nonatomic, strong) UITableView *tableView; // 课节列表
@property (nonatomic, strong) UIView *noneLessonContentView; // 课节为空时的父视图
@property (nonatomic, strong) UIImageView *noneLessonImageView; // 空课节图标
@property (nonatomic, strong) UILabel *noneLessonLabel; // 空课节提示文本
@property (nonatomic, strong) UIButton *teacherBackButton; //讲师端退出二次确认

#pragma mark 数据

@property (nonatomic, assign, getter=isTeacher) BOOL teacher; // 用户是否是讲师，默认为NO
@property (nonatomic, copy) NSString *viewerId; // 用户唯一标识
@property (nonatomic, copy) NSString *viewerName; // 用户昵称
@property (nonatomic, strong) NSArray<PLVHCLessonModel *> *lessonArray; // 课节列表数据
@property (nonatomic, assign) BOOL requestNextTime; // 初次进入页面是否需要加载课节列表数据

@end

@implementation PLVHCChooseLessonViewController

#pragma mark - [ Life Cycle ]

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.backgroundImageView.frame = self.view.bounds;
    
    self.backButton.frame = CGRectMake(24, 53, 36, 36);
    self.teacherBackButton.frame = CGRectMake(CGRectGetWidth(self.view.bounds) - 24 - 72, 53, 72, 26);
    CGFloat titleLabelHeight = [self.titleLabel sizeThatFits:CGSizeMake(234, MAXFLOAT)].height;
    self.titleLabel.frame = CGRectMake(34, 115, 234, titleLabelHeight);
    self.tableView.frame = CGRectMake(0, UIViewGetBottom(self.titleLabel) + 23, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - (UIViewGetBottom(self.titleLabel) + 23) - 30);
    
    self.noneLessonContentView.frame = CGRectMake((CGRectGetWidth(self.view.frame) - 92) / 2, (CGRectGetHeight(self.view.frame) - 88) / 2, 92, 88);
    self.noneLessonImageView.frame = CGRectMake(0, 0, 92, 60);
    self.noneLessonLabel.frame = CGRectMake(16, CGRectGetMaxY(self.noneLessonImageView.frame) + 6, 60, 12);

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.requestNextTime) {
        self.requestNextTime = NO;
    } else {
        [self requestLessonList];
    }
}

#pragma mark - [ Override ]

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;//只支持竖屏方向
}

#pragma mark - [ Public Method ]

- (instancetype)initWithViewerId:(NSString *)viewerId
                      viewerName:(NSString *)viewerName
                         teacher:(BOOL)teacher
                     lessonArray:(NSArray *)lessonArray {
    self = [super init];
    if (self) {
        self.viewerId = viewerId;
        self.viewerName = viewerName;
        self.teacher = teacher;
        
        if ([lessonArray count] > 0) {
            NSMutableArray<PLVHCLessonModel *> *tempArray = [NSMutableArray array];
            for (NSDictionary *dict in lessonArray) {
                PLVHCLessonModel *model = [PLVHCLessonModel lessonModelWithDict:dict];
                if (model) {
                    [tempArray addObject:model];
                }
            }
            
            self.lessonArray = [tempArray copy];
            self.requestNextTime = YES;
        }
    }
    return self;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)backButtonAction {
    if (self.isTeacher) {
        [PLVLiveVClassAPI teacherLogout];
    } else {
        [PLVLiveVClassAPI watcherLogout];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)teacherBackButtonAction {
    __weak typeof(self) weakSelf = self;
    [PLVHCTeacherLogoutAlertView showLogoutConfirmViewInView:self.view confirmCallback:^{
        [PLVLiveVClassAPI teacherLogout];
        [PLVHCTeacherLoginManager clearTeacherLoginInfo];
        [PLVHCTeacherLoginManager teacherLogoutFromViewController:weakSelf];
    }];
}

#pragma mark - Delegate

#pragma mark UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    self.noneLessonContentView.hidden = (self.lessonArray.count > 0);
    return [self.lessonArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.lessonArray.count <= indexPath.row) { // 数据保护
        return [PLVHCLessonTableViewCell new];
    }
    
    PLVHCLessonModel *lessonModel = self.lessonArray[indexPath.row];
    static NSString *identifier = @"PLVHCLessonTableViewCell";
    PLVHCLessonTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
     if (cell == nil) {
         cell = [[PLVHCLessonTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
     }
    
    if (indexPath.row == 0) {
        [cell updateWithModel:lessonModel title:@"当前课节" line:NO cellShape:PLVHCLessonTableViewCellAllRoundedCorners];
    } else if (indexPath.row == 1) {
        PLVHCLessonTableViewCellShape cellShape = PLVHCLessonTableViewCellTopRoundedCorners;
        if (indexPath.row == self.lessonArray.count - 1) {
            cellShape = PLVHCLessonTableViewCellAllRoundedCorners;
        }
        [cell updateWithModel:lessonModel title:@"其它课节" line:NO cellShape:cellShape];
    } else {
        PLVHCLessonTableViewCellShape cellShape = PLVHCLessonTableViewCellNoneRoundedCorners;
        if (indexPath.row == self.lessonArray.count - 1) {
            cellShape = PLVHCLessonTableViewCellBottomRoundedCorners;
        }
        [cell updateWithModel:lessonModel title:nil line:YES cellShape:cellShape];

    }
    return cell;
}

#pragma mark UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.lessonArray.count <= indexPath.row) {
        return;
    }
    
    PLVHCLessonModel *model = self.lessonArray[indexPath.row];
    [self enterHiClassWithLessonId:model.lessonId];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.lessonArray.count <= indexPath.row) {
        return 0;
    }
    
    PLVHCLessonModel *model = self.lessonArray[indexPath.row];
    NSString *text = model.name;
    CGFloat cellWidth = CGRectGetWidth(self.tableView.frame);
    switch (indexPath.row) {
        case 0:{
            return [PLVHCLessonTableViewCell cellHeightWithText:text cellWidth:cellWidth isTitle:YES] + 16;
        }
        case 1:{
            return [PLVHCLessonTableViewCell cellHeightWithText:text cellWidth:cellWidth isTitle:YES];
        }
        default:{
            return [PLVHCLessonTableViewCell cellHeightWithText:text cellWidth:cellWidth isTitle:NO];
        }
    }
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    [self.view addSubview:self.backgroundImageView];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.tableView];
    /// 当前无课节提示视图
    [self.view addSubview:self.noneLessonContentView];
    [self.noneLessonContentView addSubview:self.noneLessonImageView];
    [self.noneLessonContentView addSubview:self.noneLessonLabel];
    
    PLVHCTokenLoginModel *loginModel = [PLVHCTeacherLoginManager readLoginInfo];
    if (loginModel.token) {
        [self.view addSubview:self.teacherBackButton];
    } else {
        [self.view addSubview:self.backButton];
    }
}

#pragma mark Getter & Setter

- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] initWithImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_bg_image"]];
    }
    return _backgroundImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:26];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.numberOfLines = 0;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.text = [NSString stringWithFormat:@"Hello %@%@\n请选择要进入的课节", self.viewerName, (self.isTeacher ? @"老师" : @"同学")];
    }
    return _titleLabel;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [[UIButton alloc] init];
        [_backButton setImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_btn_back"] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UIButton *)teacherBackButton {
    if (!_teacherBackButton) {
        _teacherBackButton = [[UIButton alloc] init];
        _teacherBackButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _teacherBackButton.layer.cornerRadius = 13.0f;
        _teacherBackButton.layer.borderColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"].CGColor;
        _teacherBackButton.layer.borderWidth = 1.0f;
        [_teacherBackButton setTitle:@"退出登录" forState:UIControlStateNormal];
        [_teacherBackButton setTitleColor:[PLVColorUtil colorFromHexString:@"#FFFFFF"] forState:UIControlStateNormal];
        [_teacherBackButton addTarget:self action:@selector(teacherBackButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _teacherBackButton;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] init];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (UIView *)noneLessonContentView {
    if (!_noneLessonContentView) {
        _noneLessonContentView = [[UIView alloc] init];
        _noneLessonContentView.hidden = YES;
    }
    return _noneLessonContentView;
}

- (UIImageView *)noneLessonImageView {
    if (!_noneLessonImageView) {
        _noneLessonImageView = [[UIImageView alloc] initWithImage:[PLVHCDemoUtils imageForHiClassResource:@"plvhc_none_lesson_image"]];
    }
    return _noneLessonImageView;
}

- (UILabel *)noneLessonLabel {
    if (!_noneLessonLabel) {
        _noneLessonLabel = [[UILabel alloc] init];
        _noneLessonLabel.text = @"当前无课节";
        _noneLessonLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _noneLessonLabel.textColor = PLV_UIColorFromRGBA(@"#FFFFFF", 0.5);
    }
    return _noneLessonLabel;
}

#pragma mark Http Request

// 登录成功后请求课节列表
- (void)requestLessonList {
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:YES];
    [hud.label setText:@"获取课节列表..."];
    
    __weak typeof(self) weakSelf = self;
    void(^successBlock)(NSArray * _Nonnull responseArray) = ^(NSArray * _Nonnull responseArray) {
        [hud hideAnimated:YES];
        
        NSMutableArray<PLVHCLessonModel *> *lessonArray = [NSMutableArray array];
        for (NSDictionary *dict in responseArray) {
            PLVHCLessonModel *model = [PLVHCLessonModel lessonModelWithDict:dict];
            if (model) {
                [lessonArray addObject:model];
            }
        }
        
        weakSelf.lessonArray = [lessonArray copy];
        [weakSelf.tableView reloadData];
    };
    
    void(^failureBlock)(NSError * _Nonnull error) = ^(NSError * _Nonnull error) {
        [hud hideAnimated:YES];
        
        weakSelf.lessonArray = [[NSArray array] copy];
        [weakSelf.tableView reloadData];
        PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:weakSelf.view animated:YES];
        hud.mode = PLVProgressHUDModeText;
        hud.label.text = error.localizedDescription;
        hud.detailsLabel.text = nil;
        [hud hideAnimated:YES afterDelay:2.0];
    };
    
    if (self.isTeacher) {
        [PLVLiveVClassAPI teacherLessonListWithUserId:self.userId success:successBlock failure:failureBlock];
    } else {
        [PLVLiveVClassAPI watcherLessonListWithCourseCode:self.courseCode lessonId:self.lessonId success:successBlock failure:failureBlock];
    }
}

- (void)checkLessonStatusWithLessonId:(NSString *)lessonId
                              success:(void (^)(void))successHandler
                              failure:(void (^)(NSString * errorMessage))failureHandler {
    void(^successBlock)(NSDictionary *dict) = ^(NSDictionary *dict) {
        NSInteger status = PLV_SafeIntegerForDictKey(dict, @"status");
        if (status == 1) { //上课中的课程需要判断是否是本设备上课
            PLVHCTokenLoginModel *loginModel = [PLVHCTeacherLoginManager readLoginInfo];
            if (loginModel.lessonId &&
                [loginModel.lessonId isEqualToString:lessonId]) {
                successHandler ? successHandler() : nil;
            } else {
                failureHandler ? failureHandler(@"课节正在进行，您不能重复进入") : nil;
            }
        } else {
            successHandler ? successHandler() : nil;
        }
    };
    [PLVLiveVClassAPI teacherLessonStatusWithLessonId:lessonId
                                              success:successBlock
                                              failure:^(NSError * _Nonnull error) {
        failureHandler ? failureHandler(error.localizedDescription) : nil;
    }];
}

- (void)enterHiClassWithLessonId:(NSString *)lessonId {
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:YES];
    [hud.label setText:@"进入课节..."];
    
    __weak typeof(self) weakSelf = self;
    void(^successBlock)(void) = ^() {
        [PLVBugReporter setUserIdentifier:weakSelf.viewerId];
        PLVHCHiClassViewController *vctrl = [[PLVHCHiClassViewController alloc] init];
        //避免跳转时卡顿
        plv_dispatch_main_async_safe(^{
            [hud hideAnimated:YES];
            [weakSelf.navigationController pushViewController:vctrl animated:YES];
            [PLVFdUtil changeDeviceOrientation:UIDeviceOrientationLandscapeLeft];
        })
    };
    
    void(^failureBlock)(NSString * _Nonnull errorMessage) = ^(NSString * _Nonnull errorMessage) {
        [hud hideAnimated:YES];

        PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:weakSelf.view animated:YES];
        hud.mode = PLVProgressHUDModeText;
        hud.label.text = errorMessage;
        hud.detailsLabel.text = nil;
        [hud hideAnimated:YES afterDelay:2.0];
    };
    
    if (self.isTeacher) {
        [self checkLessonStatusWithLessonId:lessonId success:^{
            [PLVRoomLoginClient teacherEnterHiClassWithViewerId:weakSelf.viewerId
                                                     viewerName:weakSelf.viewerName
                                                          lessonId:lessonId
                                                        completion:successBlock
                                                           failure:failureBlock];
        } failure:failureBlock];
    } else {
        [PLVRoomLoginClient watcherEnterHiClassWithViewerId:self.viewerId
                                                    viewerName:self.viewerName
                                                    courseCode:self.courseCode
                                                      lessonId:lessonId
                                                    completion:successBlock
                                                       failure:failureBlock];
    }
}

@end
