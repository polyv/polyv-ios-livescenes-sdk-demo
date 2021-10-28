//
//  PLVHCLiveroomViewModel.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2021/8/12.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCLiveroomViewModel.h"

//UI
#import "PLVHCClassAlertView.h"
#import "PLVHCGuidePagesView.h"

//工具类
#import "PLVHCUtils.h"

// 模块
#import "PLVRoomDataManager.h"
#import "PLVRoomLoginClient.h"

@interface PLVHCLiveroomViewModel ()<
PLVSocketManagerProtocol // socket协议
>

//下一课节id
@property (nonatomic, copy) NSString *nextLessonId;
//下一课节时间
@property (nonatomic, copy) NSString *nextLessonTime;
//下一课节标题
@property (nonatomic, copy) NSString *nextLessonTitle;
//本节课持续时间
@property (nonatomic, assign) NSTimeInterval lessonDuration;
//本节课节号id
@property (nonatomic, copy) NSString *currentLessonId;
//课程号
@property (nonatomic, copy) NSString *courseCode;
//是否有下节课
@property (nonatomic, assign) BOOL haveNextClass;
//是否是讲师
@property (nonatomic, assign) BOOL isTeacher;
//上课状态监听计时器
@property (nonatomic, strong) NSTimer *inLiveTimer;
// 是否修改过系统的常亮状态（0 表示未记录；负值对应NO状态；正值对应YES状态）
@property (nonatomic, assign) int originalIdleTimerDisabled;

@end

@implementation PLVHCLiveroomViewModel{
    /// PLVSocketManager回调的执行队列
    dispatch_queue_t socketDelegateQueue;
    /// 操作上下课状态的的信号量，防止重复操作
    dispatch_semaphore_t _classLock;
}

#pragma mark - [ Public Method ]

+ (instancetype)sharedViewModel {
    static dispatch_once_t onceToken;
    static PLVHCLiveroomViewModel *viewModel;
    dispatch_once(&onceToken, ^{
        viewModel = [[self alloc] init];
    });
    return viewModel;
}

- (void)setup {
    // 监听socket消息
    socketDelegateQueue = dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT);
    [[PLVSocketManager sharedManager] addDelegate:self delegateQueue:socketDelegateQueue];
    //初始化信号量
    _classLock = dispatch_semaphore_create(1);

    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    self.currentLessonId = roomData.lessonInfo.lessonId;
    self.courseCode = roomData.lessonInfo.courseCode;
    self.isTeacher = roomData.roomUser.viewerType == PLVRoomUserTypeTeacher;
    self.haveNextClass = NO;
    if (!self.isTeacher) {
        [self startInLiveTimer];
    }
    self.originalIdleTimerDisabled = 0;
}

- (void)enterClassroom {
    UIView *homeView = [PLVHCUtils sharedUtils].homeVC.view;
    __weak typeof(self) weakSelf = self;
    if (self.isTeacher) {
        //讲师端引导页加载完成回调
        [PLVHCGuidePagesView showGuidePagesViewinView:homeView endBlock:^{
            //进入教室如果是上课状态则直接发送上课回调
            if ([PLVRoomDataManager sharedManager].roomData.lessonInfo.hiClassStatus == PLVHiClassStatusInClass) {
                [weakSelf notifyLessonStatusChangeResult:YES success:YES];
            }
        }];
    } else {
        //进入教室如果是上课状态则进行上课倒计时
        if ([PLVRoomDataManager sharedManager].roomData.lessonInfo.hiClassStatus == PLVHiClassStatusInClass) {
            //开始上课倒计时
            [self startClassCountdown];
            return;
        }
        
        if ([PLVRoomDataManager sharedManager].roomData.lessonInfo.hiClassStatus == PLVHiClassStatusFinishClass) {
            //课节信息提醒
            [self loadLessonFinishInfo];
            return;
        }
        
        //学生端上课倒计时结束
        [PLVHCClassAlertView showStudentClassCountdownInView:homeView endCallback:^{
            //讲师超时未上课学生端回调，需要显示占位图
            [PLVHCClassAlertView showOvertimeNoClassInView:homeView];
            [weakSelf notifyDelayInClass];
        }];
    }
    // 进入教室后屏幕保持常亮
    [self setScreenAlwaysOn];
}

- (void)startClass {
    __weak typeof(self) weakSelf = self;
    void(^successStartClassBlock)(void) = ^() {
        [weakSelf receiveOnSliceStartEvent];
    };
    [PLVHCClassAlertView showTeacherStartClassCountdownInView:[PLVHCUtils sharedUtils].homeVC.view endCallback:^{
        [weakSelf changeLessonStatusStart:YES success:successStartClassBlock];
    }];
}

- (void)remindStudentInvitedJoinLinkMic {
    __weak typeof(self) weakSelf = self;
    [PLVHCClassAlertView showStudentLinkMicAlertInView:[PLVHCUtils sharedUtils].homeVC.view linkMicCallback:^{
        [weakSelf notifyStudentLinkMic];
    }];
}

- (void)finishClassIsForced:(BOOL)forced {
    __weak typeof(self) weakSelf = self;
    void(^successFinishClassBlock)(void) = ^() {
        [weakSelf receiveFinishClassEvent];
    };
    if (forced) {
        [weakSelf changeLessonStatusStart:NO success:successFinishClassBlock];
    } else {
        //非强制下课时需要下课确认提醒
        [PLVHCClassAlertView showFinishClassConfirmInView:[PLVHCUtils sharedUtils].homeVC.view cancelActionBlock:nil confirmActionBlock:^{
            [weakSelf changeLessonStatusStart:NO success:successFinishClassBlock];
        }];
    }
}

- (void)exitClassroom {
    __weak typeof(self) weakSelf = self;
    [PLVHCClassAlertView showExitClassroomAlertInView:[PLVHCUtils sharedUtils].homeVC.view cancelActionBlock:nil confirmActionBlock:^{
        //通知主页面退出教室
        [weakSelf notifyReadyExitClassroom];
        // 恢复屏幕原始常亮与否的设置
        [weakSelf resumeScreenStatus];
    }];
    
}

#pragma mark - [ Private Method ]

- (void)startInLiveTimer {
    if(self.inLiveTimer) {
        return;
    }
    
    self.inLiveTimer = [NSTimer timerWithTimeInterval:10.0 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(inLiveTimerEvent) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.inLiveTimer forMode:NSRunLoopCommonModes];
}

- (void)stopInLiveTimer {
    if(_inLiveTimer) {
        [_inLiveTimer invalidate];
        _inLiveTimer = nil;
    }
}

- (void)clear {
    [[PLVSocketManager sharedManager] removeDelegate:self];
    
    [PLVHCClassAlertView clear];
    
    [self stopInLiveTimer];
    
    self.delegate = nil;
}

- (void)startClassCountdown {
    __weak typeof(self) weakSelf = self;
    void(^startClassBlock)(void) = ^() {
        [weakSelf notifyLessonStatusChangeResult:YES success:YES];
    };
        
    if (self.isTeacher) {
        startClassBlock();
    } else {
        [PLVHCClassAlertView showGoClassNowCountdownInView:nil goClassCallback:startClassBlock endCallback:startClassBlock];
    }
}

- (void)loadLessonFinishInfo {
    __weak typeof(self) weakSelf = self;
    [self requestLessonFinishInfoSuccess:^{
        if (!weakSelf.isTeacher) {
            //学生端需要请求是否有下节课权限提示
            [weakSelf requestLessonArrayCallback:^{
                [weakSelf showLessonFinishNoticeView];
            }];
        } else {
            //如果是讲师则直接弹出课程结束提醒
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf showLessonFinishNoticeView];
            });
        }
    }];
}

/// 开始上课
- (void)receiveOnSliceStartEvent {
    dispatch_semaphore_wait(_classLock, DISPATCH_TIME_FOREVER);
    if ([PLVRoomDataManager sharedManager].roomData.lessonInfo.hiClassStatus == PLVHiClassStatusInClass) {
        dispatch_semaphore_signal(_classLock);
        return;
    }
    [PLVRoomDataManager sharedManager].roomData.lessonInfo.hiClassStatus = PLVHiClassStatusInClass;
    dispatch_semaphore_signal(_classLock);

    //开始监听inLive 上课状态
    [self startInLiveTimer];
    
    [self startClassCountdown];
}

/// 课程结束
- (void)receiveFinishClassEvent {
    dispatch_semaphore_wait(_classLock, DISPATCH_TIME_FOREVER);
    if ([PLVRoomDataManager sharedManager].roomData.lessonInfo.hiClassStatus != PLVHiClassStatusInClass) {
        dispatch_semaphore_signal(_classLock);
        return;
    }
    [PLVRoomDataManager sharedManager].roomData.lessonInfo.hiClassStatus = PLVHiClassStatusFinishClass;
    dispatch_semaphore_signal(_classLock);

    [self stopInLiveTimer];
    //通知主页面下课
    [self notifyLessonStatusChangeResult:NO success:YES];
    //课节信息提醒
    [self loadLessonFinishInfo];
}

///课程结束提示弹窗
- (void)showLessonFinishNoticeView {
    __weak typeof(self) weakSelf = self;
    [PLVHCClassAlertView showLessonFinishNoticeInView:[PLVHCUtils sharedUtils].homeVC.view
                                            isTeacher:self.isTeacher
                                             duration:self.lessonDuration
                                        haveNextClass:self.haveNextClass classTitle:self.nextLessonTitle classTime:self.nextLessonTime confirmCallback:^{
        [weakSelf notifyReadyExitClassroom];
    }];
}

- (void)updateTeacherStartClassLessonId:(NSString * _Nullable)lessonId {
    Class PLVHCTeacherLoginManager = NSClassFromString(@"PLVHCTeacherLoginManager");
    if (PLVHCTeacherLoginManager) {
        SEL selector = NSSelectorFromString(@"updateTeacherLoginLessonId:");
        IMP imp = [PLVHCTeacherLoginManager methodForSelector:selector];
        void (*func)(id, SEL, NSString *) = (void *)imp;
        func(PLVHCTeacherLoginManager, selector, lessonId);
    }
}

#pragma mark Notify Delegate

- (void)notifyLessonStatusChangeResult:(BOOL)start success:(BOOL)success {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (start) {
            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(liveroomViewModelStartClass:success:)]) {
                [self.delegate liveroomViewModelStartClass:self success:success];
            }
        } else {
            if (self.delegate &&
                [self.delegate respondsToSelector:@selector(liveroomViewModelFinishClass:success:)]) {
                [self.delegate liveroomViewModelFinishClass:self success:success];
            }
        }
    });
}

- (void)notifyReadyExitClassroom {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(liveroomViewModelReadyExitClassroom:)]) {
            [self.delegate liveroomViewModelReadyExitClassroom:self];
        }
    });
}

- (void)notifyStudentLinkMic {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(liveroomViewModelStudentAnswerJoinLinkMic:)]) {
            [self.delegate liveroomViewModelStudentAnswerJoinLinkMic:self];
        }
    });
}

- (void)notifyDelayInClass {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate &&
            [self.delegate respondsToSelector:@selector(liveroomViewModelDelayInClass:)]) {
            [self.delegate liveroomViewModelDelayInClass:self];
        }
    });
}

#pragma mark Utils

- (NSString *)inLiveStringFormArray:(NSArray *)array {
    if (array &&
        [array isKindOfClass:[NSArray class]] &&
        array.count > 0) {
        NSInteger code = PLV_SafeIntegerForDictKey(array.firstObject, @"code");
        if (code == 200) {
            NSDictionary *data = PLV_SafeDictionaryForDictKey(array.firstObject, @"data");
            NSString *inLive = PLV_SafeStringForDictKey(data, @"inLive");
            return inLive;
        }
    }
    return nil;
}

#pragma mark HTTP

//获取课节结束信息
- (void)requestLessonFinishInfoSuccess:(void(^)(void))successHandler {
    __weak typeof(self) weakSelf = self;
    [PLVLiveVClassAPI lessonFinishInfoWithLessonId:self.currentLessonId
                                           isTeach:self.isTeacher
                                           success:^(NSDictionary * _Nonnull responseDict) {
        NSInteger status = PLV_SafeIntegerForDictKey(responseDict, @"status");
        if (status == 2) { //下课状态
            NSInteger startTime = PLV_SafeIntegerForDictKey(responseDict, @"startTime");
            NSInteger endTime = PLV_SafeIntegerForDictKey(responseDict, @"endTime");
            //课程持续时间
            weakSelf.lessonDuration = (endTime - startTime)/1000;
            successHandler ? successHandler() : nil;
        } else {
            [PLVHCUtils showToastInWindowWithMessage:@"当前课节未下课"];
        }
    } failure:^(NSError * _Nonnull error) {
        [PLVHCUtils showToastInWindowWithMessage:error.localizedDescription];
    }];
}

///请求课节列表获取是否有下一节课
- (void)requestLessonArrayCallback:(void(^ _Nullable)(void))callback {
    __weak typeof(self) weakSelf = self;
    [PLVLiveVClassAPI watcherLessonListWithCourseCode:self.courseCode lessonId:self.currentLessonId success:^(NSArray * _Nonnull responseArray) {
        //获取下节课的lessonId
        [responseArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj && [obj isKindOfClass:[NSDictionary class]]) {
                NSString *lessonId = PLV_SafeStringForDictKey(obj, @"lessonId");
                NSInteger status = PLV_SafeIntegerForDictKey(obj, @"status");
                if (![weakSelf.currentLessonId isEqualToString:lessonId] &&
                    status == 0) {
                    weakSelf.nextLessonId = PLV_SafeStringForDictKey(obj, @"lessonId");
                    weakSelf.nextLessonTitle = PLV_SafeStringForDictKey(obj, @"name");
                    weakSelf.nextLessonTime = PLV_SafeStringForDictKey(obj, @"startTime");
                    weakSelf.haveNextClass = YES;
                    *stop = YES;
                }
            }
        }];
        callback ? callback() : nil;
    } failure:^(NSError * _Nonnull error) {
        [PLVHCUtils showToastInWindowWithMessage:error.localizedDescription];
        callback ? callback() : nil;
    }];
}

- (void)changeLessonStatusStart:(BOOL)start
                        success:(void(^)(void))successHandler {
    if (![PLVSocketManager sharedManager].login) {
        // 触发socket未登录
        [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_NetworkError message:@"登录异常，请重试"];
        [self notifyLessonStatusChangeResult:start success:NO];
        return;
    }
    
    PLVProgressHUD *hud = [PLVProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:YES];
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    NSInteger status = start ? 1 : 2;
    __weak typeof(self) weakSelf = self;
    [PLVLiveVClassAPI teacherChangeLessonStatusWithLessonId:roomData.lessonInfo.lessonId status:status success:^(id  _Nonnull responseObject) {
        [hud hideAnimated:YES];
        successHandler ? successHandler() : nil;
        NSString *localLessonId = start ? roomData.lessonInfo.lessonId : nil;
        [weakSelf updateTeacherStartClassLessonId:localLessonId];
        //上下课接口调用成功后需要发送Socket消息
        if (start) {
            [weakSelf emitStartClassEvent];
        } else {
            [weakSelf emitFinishClassEvent];
        }
    } failure:^(NSError * _Nonnull error) {
        [hud hideAnimated:YES];
        [weakSelf notifyLessonStatusChangeResult:start success:NO];
        [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_NetworkError message:error.localizedDescription];
    }];
}

#pragma mark Socket消息发送

- (void)emitStartClassEvent {
    NSMutableDictionary * jsonDict = [NSMutableDictionary dictionary];
    jsonDict[@"EVENT"] = @"onSliceStart";
    jsonDict[@"courseType"] = @"smallClass";
    jsonDict[@"docType"] = @(1);
    jsonDict[@"emitMode"] = @(0);
    jsonDict[@"timeStamp"] = @(0);
    
    NSString *userId = [PLVSocketManager sharedManager].viewerId;
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    NSTimeInterval classInterval = roomData.lessonInfo.lessonEndTime - [PLVFdUtil curTimeInterval];
    jsonDict[@"classInterval"] = @(classInterval);
    jsonDict[@"userId"] = [NSString stringWithFormat:@"%@", userId];
    jsonDict[@"roomId"] = [NSString stringWithFormat:@"%@", roomData.channelId];
    jsonDict[@"sessionId"] = [NSString stringWithFormat:@"%@", roomData.sessionId];
    [[PLVSocketManager sharedManager] emitMessage:jsonDict timeout:5.0 callback:^(NSArray * _Nonnull ackArray) {
        NSLog(@"PLVMultiRoleLinkMicPresenter - Socket 'onSliceStart' ackArray: %@", ackArray);
    }];
}

- (void)emitFinishClassEvent {
    NSMutableDictionary * jsonDict = [NSMutableDictionary dictionary];
    jsonDict[@"EVENT"] = @"finishClass";
    jsonDict[@"clearPermission"] = @(1);
    [[PLVSocketManager sharedManager] emitMessage:jsonDict timeout:5.0 callback:^(NSArray * _Nonnull ackArray) {
        NSLog(@"PLVMultiRoleLinkMicPresenter - Socket 'finishClass' ackArray: %@", ackArray);
    }];
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

#pragma mark PLVSocketManagerProtocol

- (void)socketMananger_didReceiveMessage:(NSString *)subEvent
                                    json:(NSString *)jsonString
                              jsonObject:(id)object {
    NSDictionary *jsonDict = (NSDictionary *)object;
    if (![jsonDict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    //讲师或者学生收到上下课的监听
    if ([subEvent isEqualToString:@"onSliceStart"]) {
        plv_dispatch_main_async_safe(^{
            [self receiveOnSliceStartEvent];
        })
    } else if ([subEvent isEqualToString:@"finishClass"]) {
        plv_dispatch_main_async_safe(^{
            [self receiveFinishClassEvent];
        })
   }
}

#pragma mark - [ Event ]

#pragma mark Timer

///轮询上下课状态监听，讲师端只在上课后才有效
- (void)inLiveTimerEvent {
    NSString *event = @"inLive";
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (![PLVFdUtil checkStringUseable:roomData.sessionId]) {
        NSLog(@"sessionId 不能为空");
        return;
    }
    NSDictionary *paramDict = @{ @"sessionId" : roomData.sessionId };
    __weak typeof(self) weakSelf = self;
    [[PLVSocketManager sharedManager] emitEvent:event content:paramDict timeout:5.0 callback:^(NSArray *ackArray) {
        NSString *inLive = [weakSelf inLiveStringFormArray:ackArray];
        if (PLV_SafeStringForValue(inLive)) {
            if ([inLive isEqualToString:@"live"]) {
                [weakSelf receiveOnSliceStartEvent];
            } else if ([inLive isEqualToString:@"end"]) {
                [weakSelf receiveFinishClassEvent];
            }
        }
    }];
}

@end
