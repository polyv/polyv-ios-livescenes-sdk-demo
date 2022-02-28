//
//  PLVHCLiveroomViewModel.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/8/12.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCLiveroomViewModel.h"

//UI
#import "PLVHCClassAlertView.h"
#import "PLVHCGuidePagesView.h"
#import "PLVHCGroupLeaderGuidePagesView.h"
#import "PLVHCBroadcastAlertView.h"

//工具类
#import "PLVHCUtils.h"

// 模块
#import "PLVRoomDataManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVHCLiveroomViewModel ()<
PLVHiClassManagerDelegate,
PLVSocketManagerProtocol // socket回调
>

// 是否修改过系统的常亮状态（0 表示未记录；负值对应NO状态；正值对应YES状态）
@property (nonatomic, assign) int originalIdleTimerDisabled;
// 外部数据封装，主页控制器视图
@property (nonatomic, weak, readonly) UIView *homeVCView;
// 状态，socket是否重连中
@property (nonatomic, assign) BOOL socketReconnecting;

@end

@implementation PLVHCLiveroomViewModel

#pragma mark - [ Public Method ]

#pragma mark Teacher & Student 通用方法

+ (instancetype)sharedViewModel {
    static dispatch_once_t onceToken;
    static PLVHCLiveroomViewModel *viewModel;
    dispatch_once(&onceToken, ^{
        viewModel = [[self alloc] init];
    });
    return viewModel;
}

- (void)setup {
    [PLVHiClassManager sharedManager].delegate = self;
    self.originalIdleTimerDisabled = 0;
}

- (void)clear {
    // 恢复屏幕原始常亮与否的设置
    [self resumeScreenStatus];
    
    self.delegate = nil;
    self.originalIdleTimerDisabled = 0;
    
    [PLVHiClassManager sharedManager].delegate = nil;
    [[PLVHiClassManager sharedManager] clear];
    
    [PLVHCClassAlertView clear];
}

- (void)enterClassroom {
    // 监听socket消息
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
    // 开始课节情况监控
    [[PLVHiClassManager sharedManager] enterClassroom];
    
    __weak typeof(self) weakSelf = self;
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    if (roomUser.viewerType == PLVRoomUserTypeTeacher) { // 显示讲师端引导页，方法内部已经进行了判断，只会显示一次
        [self showTeacherGuideViewWithCompletion:^{
            if ([PLVHiClassManager sharedManager].status == PLVHiClassStatusInClass) { // 进入教室如果是上课状态则直接触发上课回调
                [weakSelf notifyStartClass];
            }
        }];
    } else {
        if ([PLVHiClassManager sharedManager].status == PLVHiClassStatusNotInClass) { // 未上课
            if ([PLVFdUtil curTimeInterval] < [PLVHiClassManager sharedManager].lessonStartTime) { // 显示学生端距离上课倒计时
                [self showStudentClassCountdownWithEndHandler:^{
                    [weakSelf notifyDelayInClass];
                }];
            } else { // 超时未上课通知主页上课延误
                [weakSelf notifyDelayInClass];
                // 讲师超时未上课显示占位图
                [PLVHCClassAlertView showOvertimeNoClassInView:weakSelf.homeVCView];
            }
        } else if ([PLVHiClassManager sharedManager].status == PLVHiClassStatusInClass) { // 已经处于上课中则显示开始上课倒计时
            [self startStudentThreeSesondCountDownWithCompletion:^{
                [weakSelf notifyStartClass];
                
            }];
        } else if ([PLVHiClassManager sharedManager].status == PLVHiClassStatusFinishClass) { // 已结束则显示课程结束提示弹窗
            [self showStudentLessonFinishAlertWithCompletion:^(BOOL haveNextClass) {
                if (haveNextClass) {
                    [weakSelf notifyReadyExitClassroom];
                } else {
                    [weakSelf notifyReadyExitClassroomToStudentLogin];
                }
            }];
        }
    }
    // 进入教室后屏幕保持常亮
    [self setScreenAlwaysOn];
}

- (void)exitClassroom {
    __weak typeof(self) weakSelf = self;
    void(^completionBlock)(void) = ^() {
        [weakSelf notifyReadyExitClassroom];
    };
    
   if ([PLVHiClassManager sharedManager].status == PLVHiClassStatusInClass) { // 上课时退出教室需二次弹窗确认
       [self showExitClassroomAlertWithConfirmBlock:completionBlock];
   } else {
       completionBlock();
   }
}

#pragma mark Teacher 专用方法

- (void)startClass {
    [self showTeacherThreeSesondCountDownWithCompletion:^{
        [[PLVHiClassManager sharedManager] startClass];
    }];
}

- (void)finishClass {
    [self showTeacherFinishClassComfirmAlertWithConfirmBlock:^{
        [[PLVHiClassManager sharedManager] finishClass];
    }];
}

#pragma mark Student 专用方法

- (void)remindStudentInvitedJoinLinkMicWithConfirmHandler:(void (^)(void))confirmHandler {
    [self showStudentLinkMicAlertWithConfirmBlock:confirmHandler];
}

#pragma mark - [ Private Method ]

- (void)updateTeacherStartClassLessonId:(NSString * _Nullable)lessonId {
    Class PLVHCTeacherLoginManager = NSClassFromString(@"PLVHCTeacherLoginManager");
    if (PLVHCTeacherLoginManager) {
        SEL selector = NSSelectorFromString(@"updateTeacherLoginLessonId:");
        IMP imp = [PLVHCTeacherLoginManager methodForSelector:selector];
        void (*func)(id, SEL, NSString *) = (void *)imp;
        func(PLVHCTeacherLoginManager, selector, lessonId);
    }
}

#pragma mark Teacher & Student 通用弹窗方法

/// 显示离开教室确认提醒弹窗
- (void)showExitClassroomAlertWithConfirmBlock:(void (^)(void))confirmActionBlock {
    plv_dispatch_main_async_safe(^{
        [PLVHCClassAlertView showExitClassroomAlertInView:self.homeVCView cancelActionBlock:nil confirmActionBlock:confirmActionBlock];
    })
}

#pragma mark Teacher 专用弹窗方法

/// 显示教师新手引导视图
- (void)showTeacherGuideViewWithCompletion:(void (^)(void))completion {
    plv_dispatch_main_async_safe(^{
        [PLVHCGuidePagesView showGuidePagesViewinView:self.homeVCView endBlock:completion];
    })
}

/// 显示讲师开始上课3s倒计时
- (void)showTeacherThreeSesondCountDownWithCompletion:(void (^)(void))completion {
    plv_dispatch_main_async_safe(^{
        [PLVHCClassAlertView showTeacherStartClassCountdownInView:self.homeVCView endCallback:completion];
    })
}

/// 显示是否确认下课弹窗
- (void)showTeacherFinishClassComfirmAlertWithConfirmBlock:(void (^)(void))confirmActionBlock {
    plv_dispatch_main_async_safe(^{
        [PLVHCClassAlertView showFinishClassConfirmInView:self.homeVCView cancelActionBlock:nil confirmActionBlock:confirmActionBlock];
    })
}

/// 显示课程结束弹窗
- (void)showTeacherLessonFinishAlertWithCompletion:(void (^)(void))completion {
    plv_dispatch_main_async_safe(^{
        [PLVHCClassAlertView showTeacherLessonFinishNoticeInView:self.homeVCView
                                                        duration:[PLVHiClassManager sharedManager].duration
                                                 confirmCallback:completion];
    })
}

#pragma mark Student 专用弹窗方法

/// 显示学生端距离上课倒计时
- (void)showStudentClassCountdownWithEndHandler:(void (^)(void))endHandler {
    plv_dispatch_main_async_safe(^{
        __weak typeof(self) weakSelf = self;
        void(^countdownFinishHandler)(void) = ^() {
            [PLVHCClassAlertView showOvertimeNoClassInView:weakSelf.homeVCView]; //讲师超时未上课学生端回调，需要显示占位图
            if (endHandler) {
                endHandler();
            }
        };
        
        NSTimeInterval duration = ([PLVHiClassManager sharedManager].lessonStartTime - [PLVFdUtil curTimeInterval])/1000; // 当前倒数计时剩余秒数
        if (duration > 0) {
            [PLVHCClassAlertView showStudentClassCountdownInView:self.homeVCView duration:duration endCallback:countdownFinishHandler];
        } else {
            countdownFinishHandler();
        }
    })
}

/// 学生端开始上课提醒弹窗，点击可立即前往
- (void)startStudentThreeSesondCountDownWithCompletion:(void (^)(void))completion {
    plv_dispatch_main_async_safe(^{
        [PLVHCClassAlertView showGoClassNowCountdownInView:nil goClassCallback:completion endCallback:completion];
    })
}

/// 学生端收到老师的上台连麦通知弹窗
- (void)showStudentLinkMicAlertWithConfirmBlock:(void (^)(void))confirmActionBlock {
    plv_dispatch_main_async_safe(^{
        [PLVHCClassAlertView showStudentLinkMicAlertInView:self.homeVCView linkMicCallback:confirmActionBlock];
    })
}

/// 显示学生端课程结束提示弹窗
- (void)showStudentLessonFinishAlertWithCompletion:(void (^)(BOOL haveNextClass))completion {
    __weak typeof(self) weakSelf = self;
    [[PLVHiClassManager sharedManager] requestWatcherNextLessonInfoWithCompletion:^(NSDictionary * _Nonnull lessonDict, NSInteger duration) {
        BOOL haveNextClass = lessonDict;
        NSString *nextLessonTitle = PLV_SafeStringForDictKey(lessonDict, @"name") ?: @"";
        NSString *nextLessonTime = PLV_SafeStringForDictKey(lessonDict, @"startTime") ?: @"";
        NSInteger resultDuration = duration > 0 ? duration : [PLVHiClassManager sharedManager].duration;
        
        plv_dispatch_main_async_safe(^{
            [PLVHCClassAlertView showStudeentLessonFinishNoticeInView:weakSelf.homeVCView
                                                             duration:resultDuration
                                                        haveNextClass:haveNextClass
                                                           classTitle:nextLessonTitle
                                                            classTime:nextLessonTime
                                                      confirmCallback:^{
                if (completion) {
                    completion(haveNextClass);
                }
            }];
        })
    }];
}

#pragma mark Getter & Setter

- (UIView *)homeVCView {
    return [PLVHCUtils sharedUtils].homeVC.view;
}

#pragma mark Notify Delegate

- (void)notifyStartClass {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(liveroomViewModelStartClass:)]) {
            [self.delegate liveroomViewModelStartClass:self];
        }
    })
}

- (void)notifyFinishClass {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(liveroomViewModelFinishClass:)]) {
            [self.delegate liveroomViewModelFinishClass:self];
        }
    })
}

- (void)notifyClassDurationChanged:(NSInteger)duration {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(liveroomViewModelDurationChanged:duration:)]) {
            [self.delegate liveroomViewModelDurationChanged:self duration:duration];
        }
    })
}

- (void)notifyReadyExitClassroom {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(liveroomViewModelReadyExitClassroom:)]) {
            [self.delegate liveroomViewModelReadyExitClassroom:self];
        }
    })
}

- (void)notifyReadyExitClassroomToStudentLogin {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(liveroomViewModelReadyExitClassroomToStudentLogin:)]) {
            [self.delegate liveroomViewModelReadyExitClassroomToStudentLogin:self];
        }
    })
}

- (void)notifyDelayInClass {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(liveroomViewModelDelayInClass:)]) {
            [self.delegate liveroomViewModelDelayInClass:self];
        }
    })
}

- (void)notifyJoinGroupSuccessWithData:(NSDictionary *)data {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(liveroomViewModelDidJoinGroupSuccess:ackData:)]) {
            [self.delegate liveroomViewModelDidJoinGroupSuccess:self ackData:data];
        }
    })
}

- (void)notifyGroupLeaderUpdate {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(liveroomViewModelDidGroupLeaderUpdate:groupName:groupLeaderId:groupLeaderName:)]) {
            PLVHiClassManager *manager = [PLVHiClassManager sharedManager];
            [self.delegate liveroomViewModelDidGroupLeaderUpdate:self
                                                       groupName:manager.groupName
                                                   groupLeaderId:manager.groupLeaderId
                                                 groupLeaderName:manager.groupLeaderName];
        }
    })
}

- (void)notifyLeaveGroupWithData:(NSDictionary *)data {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(liveroomViewModelDidLeaveGroup:ackData:)]) {
            [self.delegate liveroomViewModelDidLeaveGroup:self ackData:data];
        }
    })
}

- (void)notifyCancelRequestHelp {
    plv_dispatch_main_async_safe(^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(liveroomViewModelDidCancelRequestHelp:)]) {
            [self.delegate liveroomViewModelDidCancelRequestHelp:self];
        }
    })
}

#pragma mark 屏幕常亮设置

/// 进入教室后屏幕保持常亮
- (void)setScreenAlwaysOn {
    plv_dispatch_main_async_safe(^{
        if (![UIApplication sharedApplication].idleTimerDisabled) {
            self.originalIdleTimerDisabled = -1;
            [UIApplication sharedApplication].idleTimerDisabled = YES;
        }
    });
}

/// 恢复屏幕原始常亮与否的设置
- (void)resumeScreenStatus {
    if (self.originalIdleTimerDisabled != 0) {
        plv_dispatch_main_async_safe(^{
            [UIApplication sharedApplication].idleTimerDisabled = self.originalIdleTimerDisabled < 0 ? NO : YES;
            self.originalIdleTimerDisabled = 0;
        });
    }
}

#pragma mark - [ Delegate ]

#pragma mark PLVSocketManager Protocol

- (void)socketMananger_didLoginSuccess:(NSString *)ackString { // 登陆成功
    [PLVHCUtils showToastInWindowWithMessage:@"聊天室登录成功"];
}

- (void)socketMananger_didLoginFailure:(NSError *)error {
    if ((error.code == PLVSocketLoginErrorCodeLoginRefuse ||
        error.code == PLVSocketLoginErrorCodeRelogin ||
        error.code == PLVSocketLoginErrorCodeKick) &&
        error.localizedDescription) {
        __weak typeof(self) weakSelf = self;
        [PLVFdUtil showAlertWithTitle:nil message:error.localizedDescription viewController:[PLVHCUtils sharedUtils].homeVC cancelActionTitle:@"确定" cancelActionStyle:UIAlertActionStyleDefault cancelActionBlock:^(UIAlertAction * _Nonnull action) {
            [weakSelf notifyReadyExitClassroom];
        } confirmActionTitle:nil confirmActionStyle:UIAlertActionStyleDefault confirmActionBlock:nil];
    }
}

- (void)socketMananger_didConnectStatusChange:(PLVSocketConnectStatus)connectStatus {
    if (connectStatus == PLVSocketConnectStatusReconnect) {
        self.socketReconnecting = YES;
        [PLVHCUtils showToastInWindowWithMessage:@"聊天室重连中"];
    } else if(connectStatus == PLVSocketConnectStatusConnected) {
        if (self.socketReconnecting) {
            [PLVHCUtils showToastInWindowWithMessage:@"聊天室重连成功"];
        }
        self.socketReconnecting = NO;
    }
}

#pragma mark PLVHiClassManagerDelegate

- (void)hiClassManagerClassStartSuccess:(PLVHiClassManager *)manager {
    [self updateTeacherStartClassLessonId:[PLVHiClassManager sharedManager].lessonId];
    
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    if (roomUser.viewerType == PLVRoomUserTypeTeacher) {
        [PLVHCUtils showToastInWindowWithMessage:@"课程开始"];
        [self notifyStartClass];
    } else { // 学生需要先进行倒计时，倒计时完毕在触发回调 '-liveroomViewModelStartClass:'
        __weak typeof(self) weakSelf = self;
        [self startStudentThreeSesondCountDownWithCompletion:^{
            [weakSelf notifyStartClass];
        }];
    }
}

- (void)hiClassManagerClassFinishSuccess:(PLVHiClassManager *)manager {
    [self updateTeacherStartClassLessonId:nil];
    
    __weak typeof(self) weakSelf = self;
    PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
    if (roomUser.viewerType == PLVRoomUserTypeTeacher) { // 显示讲师课程结束弹窗
        [self showTeacherLessonFinishAlertWithCompletion:^{
            [weakSelf notifyReadyExitClassroom];
        }];
    } else {
        [self showStudentLessonFinishAlertWithCompletion:^(BOOL haveNextClass) {
            if (haveNextClass) {
                [weakSelf notifyReadyExitClassroom];
            } else {
                [weakSelf notifyReadyExitClassroomToStudentLogin];
            }
        }];
    }
    [self notifyFinishClass];
}

- (void)hiClassManagerClassDurationChanged:(PLVHiClassManager *)manager duration:(NSInteger)duration {
    [self notifyClassDurationChanged:duration];
}

- (void)hiClassManagerClassStartFailure:(PLVHiClassManager *)manager errorMessage:(NSString *)errorMessage {
    [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_NetworkError message:errorMessage];
}

- (void)hiClassManagerClassFinishFailure:(PLVHiClassManager *)manager errorMessage:(NSString *)errorMessage {
    [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_NetworkError message:errorMessage];
}

- (void)hiClassManagerClassWillForceFinishInTenMins:(PLVHiClassManager *)manager {
    [PLVHCUtils showToastInWindowWithMessage:@"拖堂时间过长，10分钟后将强制下课"];
}

- (void)hiClassManagerTeacherRelogin:(PLVHiClassManager *)manager errorMessage:(NSString *)errorMessage {
    __weak typeof(self) weakSelf = self;
    [PLVFdUtil showAlertWithTitle:nil
                          message:errorMessage
                   viewController:[PLVHCUtils sharedUtils].homeVC
                cancelActionTitle:@"确定"
                cancelActionStyle:UIAlertActionStyleDefault
                cancelActionBlock:^(UIAlertAction * _Nonnull action) {
        [weakSelf notifyReadyExitClassroom];
    } confirmActionTitle:nil
               confirmActionStyle:UIAlertActionStyleDefault
               confirmActionBlock:nil];
}

- (void)hiClassManagerDidPrepareJoinGroup:(PLVHiClassManager *)manager {
    [PLVHCClassAlertView showStudentStartGroupCountdownInView:self.homeVCView endCallback:nil];
}

- (void)hiClassManagerDidJoinGroupSuccess:(PLVHiClassManager *)manager ackData:(NSDictionary *)data {
    [PLVHCHiClassToast showToastWithType:PLVHCToastTypeIcon_StartGroup message:@"已开始分组讨论"];
    [self notifyJoinGroupSuccessWithData:data];
}

- (void)hiClassManagerDidJoinGroupFailure:(PLVHiClassManager *)manager {
    [PLVHCHiClassToast showToastWithMessage:@"进入分组失败"];
}

- (void)hiClassManagerDidGroupLeaderUpdate:(PLVHiClassManager *)manager originalLeaderId:(NSString *)originalLeaderId currentLeaderId:(NSString *)currentLeaderId {
    NSString *message = nil;
    if ([PLVHiClassManager sharedManager].currentUserIsGroupLeader) { // 当前组长是自己
        message = [NSString stringWithFormat:@"你已进入 %@,并成为组长", manager.groupName];
    } else { // 当前组长是其他人
        NSString *userId = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerId;
        if ([originalLeaderId isEqualToString:userId] || originalLeaderId) { // 刚从组长位置卸任，或者切换组长时
            NSString *groupLeaderName = manager.groupLeaderName;
            groupLeaderName = [PLVFdUtil checkStringUseable:groupLeaderName] ? groupLeaderName : @"";
            message = [NSString stringWithFormat:@"老师已将 %@ 设为组长", groupLeaderName];
        } else {
            NSString *groupName = manager.groupName;
            groupName = [PLVFdUtil checkStringUseable:groupName] ? groupName : @"";
            message = [NSString stringWithFormat:@"老师已将你分配至 %@,成为组员", groupName];
        }
    }
    
    if (message) {
        [PLVHCClassAlertView showStudentGroupCountdownInView:self.homeVCView titleString:message confirmActionTitle:nil endCallback:nil];
    }
    
    [PLVHCGroupLeaderGuidePagesView showGuidePagesViewinView:[PLVHCUtils sharedUtils].homeVC.view endBlock:nil];
    [self notifyGroupLeaderUpdate];
}

- (void)hiClassManagerDidLeaveGroup:(PLVHiClassManager *)manager ackData:(NSDictionary *)data {
    NSString *message = @"老师结束分组讨论,即将返回教室";
    [PLVHCClassAlertView showStudentGroupCountdownInView:self.homeVCView titleString:message confirmActionTitle:@"返回教室" endCallback:nil];
    [self notifyLeaveGroupWithData:data];
}

- (void)hiClassManagerDidTeacherJoinGroup:(PLVHiClassManager *)manager {
    [PLVHCHiClassToast showToastWithMessage:@"老师已进入分组"];
}

- (void)hiClassManagerDidTeacherLeaveGroup:(PLVHiClassManager *)manager {
    [PLVHCHiClassToast showToastWithMessage:@"老师已离开分组"];
}

- (void)hiClassManagerDidCancelRequestHelp:(PLVHiClassManager *)manager {
    [self notifyCancelRequestHelp];
}

- (void)hiClassManager:(PLVHiClassManager *)manager didReceiveHostBroadcast:(NSString *)content {
    [PLVHCBroadcastAlertView showAlertViewWithMessage:content confirmActionBlock:nil];
}

@end
