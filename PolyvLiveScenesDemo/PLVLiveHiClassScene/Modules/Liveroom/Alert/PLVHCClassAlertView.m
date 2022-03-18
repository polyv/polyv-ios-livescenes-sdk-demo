//
//  PLVHCClassAlertView.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2021/7/4.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCClassAlertView.h"

//UI
#import "PLVHCStudentGroupCountdownView.h"

//工具类
#import "PLVHCUtils.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCClassAlertView ()
/// view hierarchy
///
/// (UIView) frontView || contentView (lowest)
/// ├── (PLVHCClassAlertView) self
/// │   ├── (PLVHCClassCountdownView) view
/// │   ├── ...
/// │   └── (PLVHCStudentLinkMicAlertView) view (top)
@property (nonatomic, strong, readonly) UIView *frontView;

@end

@implementation PLVHCClassAlertView

//初始化弹窗主窗口,弹窗底层管理所有弹窗显示隐藏
+ (PLVHCClassAlertView *)sharedView {
    static dispatch_once_t once;
    static PLVHCClassAlertView *sharedView;
    dispatch_once(&once, ^{
        sharedView = [[self alloc] initWithFrame:[[[UIApplication sharedApplication] delegate] window].bounds];
    });
    return sharedView;
}

#pragma mark - [ Public Methods ]
#pragma mark - Show Methods

+ (void)showExitClassroomAlertInView:(UIView *)view
                   cancelActionBlock:(PLVHCClassAlertBlock _Nullable)cancelActionBlock
                  confirmActionBlock:(PLVHCClassAlertBlock _Nullable)confirmActionBlock {
    [[self sharedView] exitClassroomAlertInView:view
                              cancelActionBlock:cancelActionBlock
                             confirmActionBlock:confirmActionBlock];
}

+ (void)showFinishClassConfirmInView:(UIView *)view
                 cancelActionBlock:(PLVHCClassAlertBlock _Nullable)cancelActionBlock
                confirmActionBlock:(PLVHCClassAlertBlock _Nullable)confirmActionBlock {
    [[self sharedView] finishClassConfirmInView:view cancelActionBlock:cancelActionBlock confirmActionBlock:confirmActionBlock];
}

+ (void)showTeacherLessonFinishNoticeInView:(UIView * _Nullable)view
                                   duration:(NSInteger)duration
                            confirmCallback:(PLVHCClassAlertBlock _Nullable)callback {
    [[self sharedView] showViewLessonAlertInView:view type:PLVRoomUserTypeTeacher duration:duration confirmActionBlock:callback];
}

+ (void)showStudeentLessonFinishNoticeInView:(UIView * _Nullable)view
                                    duration:(NSInteger)duration
                               haveNextClass:(BOOL)nextClass
                                  classTitle:(NSString * _Nullable)title
                                   classTime:(NSString * _Nullable)time
                             confirmCallback:(PLVHCClassAlertBlock _Nullable)callback {
    if (nextClass) {//有下一节课权限
        [[self sharedView] showStudentEndClassNoticeInView:view duration:duration classTitle:title classTime:time confirmCallback:callback];
    } else { //没有下一节课权限
        [[self sharedView] showViewLessonAlertInView:view type:PLVRoomUserTypeSCStudent duration:duration confirmActionBlock:callback];
    }
}

+ (void)showTeacherStartClassCountdownInView:(UIView *)view
                                 endCallback:(PLVHCClassAlertBlock _Nullable)callback {
    [[self sharedView] showTeacherStartClassCountdownInView:view endCallback:callback];
}

+ (void)showStudentClassCountdownInView:(UIView *)view
                               duration:(NSInteger)duration
                            endCallback:(PLVHCClassAlertBlock _Nullable)callback {
    [[self sharedView] showStudentClassCountdownInView:view duration:duration endCallback:callback];
}

+ (void)showGoClassNowCountdownInView:(UIView * _Nullable)view
                      goClassCallback:(PLVHCClassAlertBlock _Nullable)goClassCallback
                          endCallback:(PLVHCClassAlertBlock _Nullable)callback {
    [[self sharedView] showGoClassNowCountdownInView:view goClassCallback:goClassCallback endCallback:callback];
}

+ (void)showOvertimeNoClassInView:(UIView *)view {
    [[self sharedView] showOvertimeNoClassInView:view];
}

+ (void)showStudentLinkMicAlertInView:(UIView *)view
                      linkMicCallback:(PLVHCClassAlertBlock)callback {
    [[self sharedView] showStudentLinkMicAlertInView:view linkMicCallback:callback];
}

+ (void)showStudentGroupCountdownInView:(UIView *)view titleString:(NSString *)titleString confirmActionTitle:(NSString *)confirmActionTitle endCallback:(PLVHCClassAlertBlock)callback {
    [[self sharedView] showStudentGroupCountdownInView:view titleString:titleString confirmActionTitle:confirmActionTitle endCallback:callback];
}

+ (void)showStudentStartGroupCountdownInView:(UIView *)view endCallback:(PLVHCClassAlertBlock)callback {
    [[self sharedView] showStudentStartGroupCountdownInView:view endCallback:callback];
}

+ (void)clear {
    [[self sharedView] clearAnimated:NO];
}

#pragma mark - [ Private Methods ]

///上课中 - 离开教室确认提醒  学生或者讲师
- (void)exitClassroomAlertInView:(UIView *)view
               cancelActionBlock:(PLVHCClassAlertBlock _Nullable)cancelActionBlock
              confirmActionBlock:(PLVHCClassAlertBlock _Nullable)confirmActionBlock {
    NSString *content = @"课程还未结束，确定离开教室吗？";
    [self showClassAlertInView:view content:content cancelActionBlock:cancelActionBlock confirmActionBlock:confirmActionBlock];
}

///讲师 - 下课确认提醒
- (void)finishClassConfirmInView:(UIView *)view
               cancelActionBlock:(PLVHCClassAlertBlock _Nullable)cancelActionBlock
              confirmActionBlock:(PLVHCClassAlertBlock _Nullable)confirmActionBlock {
    NSString *content = @"确定要下课吗？";
    [self showClassAlertInView:view content:content cancelActionBlock:cancelActionBlock confirmActionBlock:confirmActionBlock];
}

- (void)showClassAlertInView:(UIView *)view
                     content:(NSString *)content
               cancelActionBlock:(PLVHCClassAlertBlock _Nullable)cancelActionBlock
              confirmActionBlock:(PLVHCClassAlertBlock _Nullable)confirmActionBlock {
    PLVHCFinishClassConfirmAlertView *alertView = [[PLVHCFinishClassConfirmAlertView alloc] init];
    alertView.content = content;
    __weak typeof(self) weakSelf = self;
    [alertView finishClassConfirmCancelActionBlock:^{
        [weakSelf dismissView];
        cancelActionBlock ? cancelActionBlock() : nil;
    } confirmActionBlock:^{
        [weakSelf dismissView];
        confirmActionBlock ? confirmActionBlock() : nil;
    }];
    UIView *baseView = view ? view : self.frontView;
    [self showAlertViewInView:baseView subview:alertView];
    self.frame = baseView.bounds;
    self.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.75/1.0];
    alertView.center = CGPointMake(view.center.x, view.center.y - 12);
}

- (void)showViewLessonAlertInView:(UIView * _Nullable)view
                             type:(PLVRoomUserType)type
                         duration:(NSInteger)duration
               confirmActionBlock:(PLVHCClassAlertBlock _Nullable)confirmActionBlock {
    PLVHCClassFinishNoNextLessonAlertView *alertView = [[PLVHCClassFinishNoNextLessonAlertView alloc] init];
    if (type == PLVRoomUserTypeTeacher) {
        alertView.confirmTitle = @"查看课节";
    } else {
        alertView.confirmTitle = @"确定";
    }
    __weak typeof(self) weakSelf = self;
    [alertView setupLessonAlertWithDuration:duration confirmActionBlock:^{
        [weakSelf dismissView];
        confirmActionBlock ? confirmActionBlock() : nil;
    }];
    UIView *baseView = view ? view : self.frontView;
    [self showAlertViewInView:baseView subview:alertView];
    self.frame = baseView.bounds;
    alertView.center = CGPointMake(view.center.x, view.center.y - 12);
    self.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.75/1.0];
}

- (void)showTeacherStartClassCountdownInView:(UIView *)view
                                 endCallback:(PLVHCClassAlertBlock _Nullable)callback {
    PLVHCTeacherStartClassCountdownView *countdownView = [[PLVHCTeacherStartClassCountdownView alloc] init];
    __weak typeof(self) weakSelf = self;
    [countdownView countdownViewEndCallback:^{
        [weakSelf dismissView];
        callback ? callback() : nil;
    }];
    UIView *baseView = view ? view : self.frontView;
    [self showAlertViewInView:baseView subview:countdownView];
    self.frame = baseView.bounds;
    countdownView.center = self.center;
}

- (void)showStudentClassCountdownInView:(UIView *)view
                               duration:(NSInteger)duration
                            endCallback:(PLVHCClassAlertBlock _Nullable)callback {
    if (duration <= 0) {
        callback ? callback() : nil;
        return;
    }
    
    PLVHCStudentClassCountdownView *countdownView = [[PLVHCStudentClassCountdownView alloc] init];
    UIView *baseView = view ? view : self.frontView;
    __weak typeof(self) weakSelf = self;
    [countdownView studentStartClassCountdownDuration:duration endCallback:^{
        [weakSelf dismissView];
        callback ? callback() : nil;
    }];
    [self showAlertViewInView:baseView subview:countdownView];
    self.bounds = CGRectMake(0, 0, 106 + 164, 118);
    self.center = baseView.center;
    countdownView.frame = self.bounds;
}

- (void)showGoClassNowCountdownInView:(UIView *)view
                      goClassCallback:(PLVHCClassAlertBlock _Nullable)goClassCallback
                          endCallback:(PLVHCClassAlertBlock _Nullable)callback {
    PLVHCStudentGoClassCountdownView *goClassView = [[PLVHCStudentGoClassCountdownView alloc] init];
    __weak typeof(self) weakSelf = self;
    [goClassView startClassCountdownGoClassCallback:^{
        [weakSelf dismissView];
        goClassCallback ? goClassCallback() : nil;
    } endCallback:^{
        [weakSelf dismissView];
        callback ? callback() : nil;
    }];
    UIView *baseView = view ? view : self.frontView;
    [self showAlertViewInView:baseView subview:goClassView];
    self.frame = baseView.bounds;
    goClassView.center = self.center;
}
- (void)showStudentEndClassNoticeInView:(UIView * _Nullable)view
                                 duration:(NSInteger)duration
                               classTitle:(NSString *)title
                                classTime:(NSString *)time
                          confirmCallback:(PLVHCClassAlertBlock _Nullable)callback {
    PLVHCClassFinishHaveNextLessonAlertView *nextClassView = [[PLVHCClassFinishHaveNextLessonAlertView alloc] init];
    UIView *baseView = view ? view : self.frontView;
    __weak typeof(self) weakSelf = self;
    [nextClassView setupDuration:duration classTitle:title classTime:time nextClassCallback:^{
        [weakSelf dismissView];
        callback ? callback() : nil;
    }];
    [self showAlertViewInView:baseView subview:nextClassView];
    self.frame = baseView.bounds;
    self.backgroundColor = [PLVColorUtil colorFromHexString:@"#000000" alpha:0.75];
}

- (void)showOvertimeNoClassInView:(UIView *)view {
    PLVHCPlaceholderAlertView *overtimeView = [[PLVHCPlaceholderAlertView alloc] init];
    UIView *baseView = view ? view : self.frontView;
    [self showAlertViewInView:baseView subview:overtimeView];
    self.bounds = CGRectMake(0, 0, 190, 84);
    self.center = CGPointMake(baseView.center.x, baseView.center.y + 30);
    overtimeView.frame = self.bounds;
}

- (void)showStudentLinkMicAlertInView:(UIView *)view
                      linkMicCallback:(PLVHCClassAlertBlock)callback {
    PLVHCStudentLinkMicAlertView *linkMicView = [[PLVHCStudentLinkMicAlertView alloc] init];
    UIView *baseView = view ? view : self.frontView;
    __weak typeof(self) weakSelf = self;
    [linkMicView studentLinkMicAlertCallback:^{
        [weakSelf dismissView];
        callback ? callback() : nil;
    }];
    [self showAlertViewInView:baseView subview:linkMicView];
    self.frame = baseView.bounds;
    linkMicView.frame = CGRectMake(0, 0, 242, 147);
    linkMicView.center = CGPointMake(baseView.center.x, baseView.center.y + 30);
}

- (void)showStudentGroupCountdownInView:(UIView *)view titleString:(NSString *)titleString confirmActionTitle:(NSString *)confirmActionTitle endCallback:(PLVHCClassAlertBlock)callback {
    PLVHCStudentGroupCountdownView *groupCountDownView = [[PLVHCStudentGroupCountdownView alloc] initWithFrame:CGRectMake(0, 0, 282, 140)];
    __weak typeof(self) weakSelf = self;
    [groupCountDownView countdownViewWithTitleString:titleString confirmActionTitle:confirmActionTitle endCallback:^{
        [weakSelf dismissView];
        callback ? callback() : nil;
    }];
    UIView *baseView = view ? view : self.frontView;
    [self showAlertViewInView:baseView subview:groupCountDownView];
    self.frame = baseView.bounds;
    groupCountDownView.center = self.center;
}

- (void)showStudentStartGroupCountdownInView:(UIView *)view endCallback:(PLVHCClassAlertBlock)callback {
    PLVHCStudentGroupCountdownView *groupCountDownView = [[PLVHCStudentGroupCountdownView alloc] initWithFrame:CGRectMake(0, 0, 164, 136)];
    __weak typeof(self) weakSelf = self;
    [groupCountDownView countdownViewEndCallback:^{
        [weakSelf dismissView];
        callback ? callback() : nil;
    }];
    UIView *baseView = view ? view : self.frontView;
    [self showAlertViewInView:baseView subview:groupCountDownView];
    self.frame = baseView.bounds;
    groupCountDownView.center = self.center;
}

#pragma mark - show

///subview 属性需要在此方法后设置避免clearAnimated将其清除
- (void)showAlertViewInView:(UIView *)superview subview:(UIView *)subview {
    [self clearAnimated:NO];
    subview.alpha = 0.0;
    [superview addSubview:self];
    [self addSubview:subview];
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1.0;
        subview.alpha = 1.0;
    }];
}

#pragma mark - dismiss

- (void)dismissView {
    //因为上个视图添加动画，会导致下个视图不显示异常，暂时移除动画
    [self clearAnimated:NO];
}

- (void)clearAnimated:(BOOL)animate {
    if (self.subviews.count == 0 && !self.superview) {
        return;
    }
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[PLVHCStudentClassCountdownView class]]) {
            [(PLVHCStudentClassCountdownView *)obj clear];
        }
        if ([obj isKindOfClass:[PLVHCStudentGroupCountdownView class]]) {
            [(PLVHCStudentGroupCountdownView *)obj clear];
        }
    }];
    if (animate) {
        [UIView animateWithDuration:0.3 animations:^{
            self.alpha = 0.0;
            self.backgroundColor = [UIColor clearColor];
        } completion:^(BOOL finished) {
            [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [self removeFromSuperview];
        }];
    } else {
        self.alpha = 0.0;
        self.backgroundColor = [UIColor clearColor];
        [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self removeFromSuperview];
    }
}

#pragma mark - [ Getter ]

- (UIView *)frontView {
    if ([PLVHCUtils sharedUtils].homeVC) {
        return [PLVHCUtils sharedUtils].homeVC.view;
    }
    return [PLVHCUtils getCurrentWindow];
}

@end

@interface PLVHCTeacherStartClassCountdownView ()

//倒计时
@property (nonatomic, strong) UILabel *countdownLabel;
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation PLVHCTeacherStartClassCountdownView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, 164, 136);
        self.backgroundColor = [UIColor colorWithRed:43/255.0 green:47/255.0 blue:72/255.0 alpha:1/1.0];
        self.layer.cornerRadius = 10.0f;
        self.clipsToBounds = YES;
        [self addSubview:self.countdownLabel];
        [self addSubview:self.titleLabel];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.countdownLabel.frame = CGRectMake(0, 14, CGRectGetWidth(self.bounds), 70);
    self.titleLabel.frame = CGRectMake(0, self.countdownLabel.frame.origin.y + 70 + 8, CGRectGetWidth(self.bounds), 15);
}

#pragma mark - [ Getter ]

- (UILabel *)countdownLabel {
    if (!_countdownLabel) {
        _countdownLabel = [[UILabel alloc] init];
        _countdownLabel.textColor = [UIColor whiteColor];
        _countdownLabel.font = [UIFont boldSystemFontOfSize:72];
        _countdownLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _countdownLabel;
}
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:14.0];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = @"秒后开始上课";
    }
    return _titleLabel;
}

#pragma mark - [ Public Methods ]

- (void)countdownViewEndCallback:(PLVHCClassAlertBlock)callback {
    __block NSInteger countdown = 3;
    dispatch_queue_t quene = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, quene);
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(timer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (countdown == 0) {
                dispatch_cancel(timer);
                callback ? callback() : nil;
            } else {
                self.countdownLabel.text = [NSString stringWithFormat:@"%ld", (long)countdown];
                countdown--;
            }
        });
    });
    dispatch_resume(timer);
}

@end

@interface PLVHCStudentClassCountdownView ()
///UI
//倒计时时间显示
@property (nonatomic, strong) UILabel *countdownLabel;
//倒计时文字
@property (nonatomic, strong) UILabel *titleLabel;
//时间和文字的背景
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
///数据
//倒计时器
@property (nonatomic, strong) dispatch_source_t countdownTimer;
//倒计时时长(秒)
@property (nonatomic, assign) NSTimeInterval duration;
//倒计时结束回调
@property (nonatomic, copy) PLVHCClassAlertBlock countdownEndCallback;
//倒计时结束时对应系统时间戳(秒)用于矫正退出后台重新激活后的计时操作
@property (nonatomic, assign) NSTimeInterval countdownEndTimestamp;
@end

@implementation PLVHCStudentClassCountdownView

#pragma mark - [ Life Cycle ]

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.backgroundView];
        [self addSubview:self.imageView];
        [self.backgroundView.layer addSublayer:self.gradientLayer];
        [self.backgroundView addSubview:self.titleLabel];
        [self.backgroundView addSubview:self.countdownLabel];
        /// 设置 监听 事件
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageView.frame = CGRectMake(5, 4, 94, 113);
    self.backgroundView.frame = CGRectMake(self.imageView.center.x, self.imageView.center.y - 94/2 , 217, 95);
    self.titleLabel.frame = CGRectMake(64, 16, 120, 17);
    self.countdownLabel.frame = CGRectMake(CGRectGetMinX(self.titleLabel.frame), CGRectGetMaxY(self.titleLabel.frame) + 6, 145, 45);
    self.gradientLayer.frame = self.backgroundView.bounds;
}

#pragma mark - [ Getter ]

- (UILabel *)countdownLabel {
    if (!_countdownLabel) {
        _countdownLabel = [[UILabel alloc] init];
        _countdownLabel.textColor = [UIColor whiteColor];
        _countdownLabel.font = [UIFont fontWithName:@"DINAlternate-Bold" size:36];
        _countdownLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _countdownLabel;
}
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.text = @"距离课程开始还有";
    }
    return _titleLabel;
}
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.image = [PLVHCUtils imageForLiveroomResource:@"plvhc_liveroom_student_countdown_clock_icon"];
    }
    return _imageView;
}
- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
    }
    return _backgroundView;
}
- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)[PLVColorUtil colorFromHexString:@"#30344F" alpha:0.0].CGColor, (__bridge id)[PLVColorUtil colorFromHexString:@"#2D324C" alpha:0.9].CGColor];
        _gradientLayer.locations = @[@0.0, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
    }
    return _gradientLayer;
}

#pragma mark - [ Private Methods ]

- (void)startClassCountdownTimer {
    dispatch_queue_t quene = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.countdownTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, quene);
    dispatch_source_set_timer(self.countdownTimer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0);
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(self.countdownTimer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.duration <= 0) {
                [weakSelf clear];
                weakSelf.countdownEndCallback ? weakSelf.countdownEndCallback() : nil;
            } else {
                NSString *timeText = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",lround(floor(weakSelf.duration / 60 / 60)), lround(floor(weakSelf.duration / 60)) % 60, lround(floor(weakSelf.duration)) % 60];
                weakSelf.countdownLabel.text = timeText;
                weakSelf.duration --;
            }
        });
    });
    dispatch_resume(self.countdownTimer);
}

#pragma mark - [ Public Methods ]

/// 开始倒计时，并且结束时回调
- (void)studentStartClassCountdownDuration:(NSTimeInterval)duration
                               endCallback:(PLVHCClassAlertBlock)callback {
    self.duration = duration;
    self.countdownEndCallback = callback;
    NSTimeInterval nowInterval = [[NSDate date] timeIntervalSince1970];
    self.countdownEndTimestamp = nowInterval + duration;
    [self startClassCountdownTimer];
}

- (void)clear {
    if (self.countdownTimer) {
        dispatch_source_cancel(self.countdownTimer);
        self.countdownTimer = nil;
    }
}

#pragma mark - [ Event ]
#pragma mark Notification
/// 回到前台
- (void)didBecomeActive:(NSNotification *)notification {
    NSTimeInterval nowInterval = [[NSDate date] timeIntervalSince1970];
    self.duration = self.countdownEndTimestamp - nowInterval;
}

@end

@interface PLVHCStudentGoClassCountdownView ()

//倒计时进入教室的按钮
@property (nonatomic, strong) UIButton *goClassButton;
//倒计时文字
@property (nonatomic, strong) UILabel *titleLabel;
//点击立即前往回调
@property (nonatomic, copy) PLVHCClassAlertBlock goClassCallback;

@end

@implementation PLVHCStudentGoClassCountdownView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.bounds = CGRectMake(0, 0, 242, 147);
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#2B2F48"];
        self.layer.cornerRadius = 16.0f;
        self.clipsToBounds = YES;
        [self addSubview:self.titleLabel];
        [self addSubview:self.goClassButton];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.titleLabel.center = CGPointMake(CGRectGetWidth(self.bounds)/2, 35 + CGRectGetHeight(self.titleLabel.bounds)/2);
    self.goClassButton.center = CGPointMake(self.titleLabel.center.x, CGRectGetMaxY(self.titleLabel.frame) + 22 + CGRectGetHeight(self.goClassButton.bounds)/2);
}

#pragma mark - [ Getter ]

- (UIButton *)goClassButton {
    if (!_goClassButton) {
        _goClassButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _goClassButton.bounds = CGRectMake(0, 0, 126, 36);
        _goClassButton.layer.masksToBounds = YES;
        _goClassButton.layer.cornerRadius = 18.0f;
        _goClassButton.layer.borderWidth = 1.0f;
        _goClassButton.layer.borderColor = [PLVColorUtil colorFromHexString:@"#ffffff"].CGColor;
        _goClassButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:14];
        [_goClassButton setTitle:@"立即前往" forState:UIControlStateNormal];
        [_goClassButton addTarget:self action:@selector(goClassNowAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _goClassButton;
}
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.bounds = CGRectMake(0, 0, 130, 20);
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:18];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = @"老师开始上课了";
    }
    return _titleLabel;
}

#pragma mark - [ Public Methods ]

- (void)startClassCountdownGoClassCallback:(PLVHCClassAlertBlock)goClassCallback
                               endCallback:(PLVHCClassAlertBlock)callback {
    self.goClassCallback = goClassCallback;
    __block NSInteger countdown = 3;
    dispatch_queue_t quene = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, quene);
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(timer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (countdown == 0) {
                dispatch_cancel(timer);
                callback ? callback() : nil;
            } else {
                NSString *goClassText = [NSString stringWithFormat:@"立即前往(%lds)",(long)countdown];
                [self.goClassButton setTitle:goClassText forState:UIControlStateNormal];
                countdown--;
            }
        });
    });
    dispatch_resume(timer);
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)goClassNowAction {
    self.goClassCallback ? self.goClassCallback() : nil;
}

@end

@interface PLVHCFinishClassConfirmAlertView ()

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) UIButton *cancelButton;
///确定操作回调
@property (nonatomic, copy) PLVHCClassAlertBlock confirmBlock;
///取消操作的回调
@property (nonatomic, copy) PLVHCClassAlertBlock cancelBlock;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end

@implementation PLVHCFinishClassConfirmAlertView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.bounds = CGRectMake(0, 0, 260, 220);
        self.layer.cornerRadius = 16.0f;
        self.clipsToBounds = YES;
        [self addSubview:self.backgroundView];
        [self addSubview:self.imageView];
        [self.backgroundView addSubview:self.titleLabel];
        [self.backgroundView addSubview:self.cancelButton];
        [self.backgroundView addSubview:self.confirmButton];
        [self.backgroundView.layer insertSublayer:self.gradientLayer atIndex:0];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageView.center = CGPointMake(CGRectGetWidth(self.bounds)/2, 54.5);
    self.backgroundView.center = CGPointMake(self.imageView.center.x, CGRectGetHeight(self.imageView.bounds) + 55.5);
    self.titleLabel.center = CGPointMake(CGRectGetWidth(self.backgroundView.bounds)/2, 32);
    self.cancelButton.center = CGPointMake(24 + 50, CGRectGetHeight(self.backgroundView.bounds) - 34);
    self.confirmButton.center = CGPointMake(CGRectGetWidth(self.backgroundView.bounds) - 24 - 50, self.cancelButton.center.y);
    self.gradientLayer.frame = self.backgroundView.bounds;
}

#pragma mark - Getter && Setter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.bounds = CGRectMake(0, 0, 240, 20);
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:14.0];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = @"确定要下课吗？";
    }
    return _titleLabel;
}
- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
        _backgroundView.bounds = CGRectMake(0, 0, 260, 111);
        _backgroundView.backgroundColor = [PLVColorUtil colorFromHexString:@"#2D324C"];
    }
    return _backgroundView;
}
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.bounds = CGRectMake(0, 0, 260, 109);
        _imageView.image = [PLVHCUtils imageForLiveroomResource:@"plvhc_liveroom_alert_exitclass_icon"];
    }
    return _imageView;
}
- (UIButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.bounds = CGRectMake(0, 0, 100, 36);
        _cancelButton.layer.masksToBounds = YES;
        _cancelButton.layer.cornerRadius = 18.0f;
        _cancelButton.layer.borderWidth = 1.0f;
        _cancelButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
        UIColor *textColor = [UIColor colorWithRed:0/255.0 green:177/255.0 blue:108/255.0 alpha:1/1.0];
        _cancelButton.layer.borderColor = textColor.CGColor;
        [_cancelButton setTitle:@"按错了" forState:UIControlStateNormal];
        [_cancelButton setTitleColor:textColor forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(cancelAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}
- (UIButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _confirmButton.bounds = CGRectMake(0, 0, 100, 36);
        _confirmButton.layer.masksToBounds = YES;
        _confirmButton.layer.cornerRadius = 18.0f;
        _confirmButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
        _confirmButton.backgroundColor = [UIColor colorWithRed:0/255.0 green:177/255.0 blue:108/255.0 alpha:1/1.0];
        [_confirmButton setTitle:@"确定" forState:UIControlStateNormal];
        [_confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_confirmButton addTarget:self action:@selector(confirmAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}
- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)[PLVColorUtil colorFromHexString:@"#30344F" alpha:0.9].CGColor, (__bridge id)[PLVColorUtil colorFromHexString:@"#2D324C" alpha:0.9].CGColor];
        _gradientLayer.locations = @[@0.5, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
    }
    return _gradientLayer;
}

- (void)setContent:(NSString *)content {
    self.titleLabel.text = content;
}

#pragma mark - [ Public Methods ]

- (void)finishClassConfirmCancelActionBlock:(PLVHCClassAlertBlock)cancelActionBlock
                        confirmActionBlock:(PLVHCClassAlertBlock)confirmActionBlock {
    self.cancelBlock = cancelActionBlock;
    self.confirmBlock = confirmActionBlock;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)cancelAction {
    self.cancelBlock ? self.cancelBlock() : nil;
}
- (void)confirmAction {
    self.confirmBlock ? self.confirmBlock() : nil;
}

@end

@interface PLVHCClassFinishNoNextLessonAlertView ()

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *durationTitleLabel;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

///确定操作回调
@property (nonatomic, copy) PLVHCClassAlertBlock confirmBlock;

@end

@implementation PLVHCClassFinishNoNextLessonAlertView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.center = CGPointMake(CGRectGetWidth(self.bounds)/2, 50);
    self.backgroundView.center = CGPointMake(self.imageView.center.x, CGRectGetHeight(self.imageView.bounds) + 46);
    self.titleLabel.center = CGPointMake(24 + CGRectGetWidth(self.titleLabel.bounds)/2, 25 + CGRectGetHeight(self.titleLabel.bounds)/2);
    self.durationTitleLabel.center = CGPointMake(24 + CGRectGetWidth(self.durationTitleLabel.bounds)/2, CGRectGetHeight(self.backgroundView.bounds) - 20 - CGRectGetHeight(self.durationTitleLabel.bounds)/2);
    self.durationLabel.center = CGPointMake(CGRectGetWidth(self.durationTitleLabel.bounds) + self.durationTitleLabel.frame.origin.x + 6 + CGRectGetWidth(self.durationLabel.bounds)/2, self.durationTitleLabel.center.y - 2);
    self.confirmButton.center = CGPointMake(CGRectGetWidth(self.backgroundView.bounds) - 24 - CGRectGetWidth(self.confirmButton.bounds)/2, 34 + CGRectGetHeight(self.confirmButton.bounds)/2);
    self.gradientLayer.frame = self.backgroundView.bounds;
}

#pragma mark - Getter && Setter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.bounds = CGRectMake(0, 0, 100, 20);
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:18.0];
        _titleLabel.text = @"课节已结束";
    }
    return _titleLabel;
}
- (UILabel *)durationTitleLabel {
    if (!_durationTitleLabel) {
        _durationTitleLabel = [[UILabel alloc] init];
        _durationTitleLabel.bounds = CGRectMake(0, 0, 60, 16);
        _durationTitleLabel.textColor = [UIColor whiteColor];
        _durationTitleLabel.font = [UIFont systemFontOfSize:14.0];
        _durationTitleLabel.text = @"上课时长";
    }
    return _durationTitleLabel;
}
- (UILabel *)durationLabel {
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.bounds = CGRectMake(0, 0, 105, 24);
        _durationLabel.textColor = [UIColor whiteColor];
        _durationLabel.font = [UIFont boldSystemFontOfSize:21.0f];
    }
    return _durationLabel;
}

- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
        _backgroundView.bounds = CGRectMake(0, 0, 320, 92);
        _backgroundView.backgroundColor = [UIColor colorWithRed:43/255.0 green:47/255.0 blue:72/255.0 alpha:1/1.0];
    }
    return _backgroundView;
}
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.bounds = CGRectMake(0, 0, 320, 100);
        _imageView.image = [PLVHCUtils imageForLiveroomResource:@"plvhc_liveroom_alert_endclass_icon"];
    }
    return _imageView;
}
- (UIButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _confirmButton.bounds = CGRectMake(0, 0, 100, 36);
        _confirmButton.layer.masksToBounds = YES;
        _confirmButton.layer.cornerRadius = 18.0f;
        _confirmButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.colors = @[(__bridge id)[UIColor colorWithRed:26/255.0 green:177/255.0 blue:110/255.0 alpha:1.0].CGColor, (__bridge id)[UIColor colorWithRed:34/255.0 green:230/255.0 blue:144/255.0 alpha:1.0].CGColor];
        gradientLayer.locations = @[@0.5, @1.0];
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(1.0, 0);
        gradientLayer.frame = CGRectMake(0, 0, 100, 36);
        [_confirmButton.layer insertSublayer:gradientLayer atIndex:0];
        [_confirmButton setTitle:@"查看课节" forState:UIControlStateNormal];
        [_confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_confirmButton addTarget:self action:@selector(confirmAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}
- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)[PLVColorUtil colorFromHexString:@"#30344F"].CGColor, (__bridge id)[PLVColorUtil colorFromHexString:@"#2D324C"].CGColor];
        _gradientLayer.locations = @[@0.5, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
    }
    return _gradientLayer;
}
- (void)setConfirmTitle:(NSString *)confirmTitle {
    [self.confirmButton setTitle:confirmTitle forState:UIControlStateNormal];
}

#pragma mark - [ Public Methods ]

- (void)setupLessonAlertWithDuration:(NSInteger)duration
                  confirmActionBlock:(PLVHCClassAlertBlock)confirmActionBlock {
    self.confirmBlock = confirmActionBlock;
    NSString *durTimeStr = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",lround(floor(duration / 60 / 60)), lround(floor(duration / 60)) % 60, lround(floor(duration)) % 60];
    self.durationLabel.text = durTimeStr;
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    self.bounds = CGRectMake(0, 0, 320, 192);
    self.layer.cornerRadius = 16.0f;
    self.clipsToBounds = YES;
    [self addSubview:self.backgroundView];
    [self addSubview:self.imageView];
    [self.backgroundView addSubview:self.titleLabel];
    [self.backgroundView addSubview:self.durationLabel];
    [self.backgroundView addSubview:self.durationTitleLabel];
    [self.backgroundView addSubview:self.confirmButton];
    [self.backgroundView.layer insertSublayer:self.gradientLayer atIndex:0];
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)confirmAction {
    self.confirmBlock ? self.confirmBlock() : nil;
}

@end

@interface PLVHCClassFinishHaveNextLessonAlertView ()

@property (nonatomic, strong) UIImageView *classImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *durationTitleLabel;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UIView *nextClassView;
@property (nonatomic, strong) UIButton *nextClassButton;
@property (nonatomic, strong) UIView *nextClassNoticeView;
@property (nonatomic, strong) UILabel *nextClassNoticeLabel;
@property (nonatomic, strong) UILabel *nextClassTitleLabel;
@property (nonatomic, strong) UILabel *nextClassTimeLabel;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

///数据
///进入下节课回调
@property (nonatomic, copy) PLVHCClassAlertBlock nextClassBlock;

@end

@implementation PLVHCClassFinishHaveNextLessonAlertView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    
    CGFloat mainViewWidth = 370; //弹窗宽度
    CGPoint superviewCenter = self.superview.center;
    
    //预告课部分不包含预告课节名称的高度;
    CGFloat notContainClassTitleHeight = 94;
    self.nextClassView.bounds = CGRectMake(0, 0, mainViewWidth, notContainClassTitleHeight + CGRectGetHeight(self.nextClassTitleLabel.bounds));
    //总弹窗高度
    CGFloat alertViewHeight = CGRectGetHeight(self.classImageView.bounds) +  CGRectGetHeight(self.nextClassView.bounds);
    self.bounds = (CGRect){{0, 0}, CGSizeMake(mainViewWidth, alertViewHeight)};
    self.center = CGPointMake(superviewCenter.x, superviewCenter.y - 13);
    self.classImageView.frame = (CGRect){{0, 0}, { mainViewWidth, 110}};
    self.nextClassView.frame = (CGRect){CGPointMake(0, CGRectGetMaxY(self.classImageView.frame)), self.nextClassView.bounds.size};
    
    //本节课视图
    self.titleLabel.frame = (CGRect){CGPointMake(24, 43), self.titleLabel.bounds.size};
    self.durationTitleLabel.frame = (CGRect){CGPointMake(CGRectGetMinX(self.titleLabel.frame), CGRectGetMaxY(self.titleLabel.frame) + 10), self.durationTitleLabel.bounds.size};
    self.durationLabel.center = CGPointMake(CGRectGetMaxX(self.durationTitleLabel.frame) + 5 + CGRectGetWidth(self.durationLabel.bounds)/2, CGRectGetMaxY(self.durationTitleLabel.frame) - CGRectGetHeight(self.durationLabel.bounds)/2);
    
    //预告部分视图
    self.nextClassNoticeView.frame = (CGRect){{0, 0}, self.nextClassNoticeView.bounds.size};
    self.nextClassNoticeLabel.frame = self.nextClassNoticeView.bounds;
    self.nextClassTitleLabel.frame = (CGRect){{24, CGRectGetMaxY(self.nextClassNoticeView.frame) + 10},
        self.nextClassTitleLabel.bounds.size};
    self.nextClassTimeLabel.frame =  (CGRect){
        {CGRectGetMinX(self.nextClassTitleLabel.frame), CGRectGetMaxY(self.nextClassTitleLabel.frame) + 10}, self.nextClassTimeLabel.bounds.size};
    self.nextClassButton.frame = (CGRect){
        {CGRectGetWidth(self.bounds) - 24 - CGRectGetWidth(self.nextClassButton.bounds),
        52
        }, self.nextClassButton.bounds.size};

    self.gradientLayer.frame = self.nextClassView.bounds;
    self.gradientLayer.mask = [self shapeLayerWithRect:self.nextClassView.bounds cornerRadius:16.0];
}

#pragma mark Getter & Setter

- (UIImageView *)classImageView {
    if (!_classImageView) {
        _classImageView = [[UIImageView alloc] init];
        _classImageView.bounds = CGRectMake(0, 0, 370, 110);
        _classImageView.image = [PLVHCUtils imageForLiveroomResource:@"plvhc_liveroom_alert_havenextclass_icon"];
    }
    return _classImageView;
}
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.bounds = CGRectMake(0, 0, 100, 20);
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:18.0];
        _titleLabel.text = @"课节已结束";
    }
    return _titleLabel;
}
- (UILabel *)durationTitleLabel {
    if (!_durationTitleLabel) {
        _durationTitleLabel = [[UILabel alloc] init];
        _durationTitleLabel.bounds = CGRectMake(0, 0, 60, 16);
        _durationTitleLabel.textColor = [UIColor whiteColor];
        _durationTitleLabel.font = [UIFont systemFontOfSize:14.0];
        _durationTitleLabel.text = @"上课时长";
    }
    return _durationTitleLabel;
}
- (UILabel *)durationLabel {
    if (!_durationLabel) {
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.bounds = CGRectMake(0, 0, 105, 24);
        _durationLabel.textColor = [UIColor whiteColor];
        _durationLabel.font = [UIFont boldSystemFontOfSize:21.0f];
    }
    return _durationLabel;
}
- (UIView *)nextClassView {
    if (!_nextClassView) {
        _nextClassView = [[UIView alloc] init];
    }
    return _nextClassView;
}
- (UIView *)nextClassNoticeView {
    if (!_nextClassNoticeView) {
        _nextClassNoticeView = [[UIView alloc] init];
        _nextClassNoticeView.bounds = CGRectMake(0, 0, 116, 30);
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.colors = @[(__bridge id)[PLVColorUtil colorFromHexString:@"#3B7DFE"].CGColor, (__bridge id)[PLVColorUtil colorFromHexString:@"#4B8FFF"].CGColor];
        gradientLayer.locations = @[@0.5, @1.0];
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(1.0, 0);
        gradientLayer.frame = _nextClassNoticeView.bounds;
        
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:_nextClassNoticeView.bounds byRoundingCorners:UIRectCornerBottomRight cornerRadii:CGSizeMake(16.0, 16.0)];
        CAShapeLayer *layer = [[CAShapeLayer alloc] init];
        layer.path = path.CGPath;
        gradientLayer.mask = layer;
        [_nextClassNoticeView.layer insertSublayer:gradientLayer atIndex:0];
    }
    return _nextClassNoticeView;
}
- (UILabel *)nextClassNoticeLabel {
    if (!_nextClassNoticeLabel) {
        _nextClassNoticeLabel = [[UILabel alloc] init];
        _nextClassNoticeLabel.textColor = [UIColor whiteColor];
        _nextClassNoticeLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:14];
        _nextClassNoticeLabel.textAlignment = NSTextAlignmentCenter;
        _nextClassNoticeLabel.text = @"下节课预告";
    }
    return _nextClassNoticeLabel;
}
- (UILabel *)nextClassTitleLabel {
    if (!_nextClassTitleLabel) {
        _nextClassTitleLabel = [[UILabel alloc] init];
        _nextClassTitleLabel.textColor = [UIColor whiteColor];
        _nextClassTitleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        _nextClassTitleLabel.numberOfLines = 2;
    }
    return _nextClassTitleLabel;
}
- (UILabel *)nextClassTimeLabel {
    if (!_nextClassTimeLabel) {
        _nextClassTimeLabel = [[UILabel alloc] init];
        _nextClassTimeLabel.bounds = CGRectMake(0, 0, 160, 22);
        _nextClassTimeLabel.textColor = [UIColor whiteColor];
        _nextClassTimeLabel.font = [UIFont fontWithName:@"DINAlternate-Bold" size:20];
    }
    return _nextClassTimeLabel;
}
- (UIButton *)nextClassButton {
    if (!_nextClassButton) {
        _nextClassButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _nextClassButton.bounds = CGRectMake(0, 0, 100, 36);
        _nextClassButton.layer.masksToBounds = YES;
        _nextClassButton.layer.cornerRadius = 18.0f;
        _nextClassButton.layer.borderWidth = 1.0f;
        _nextClassButton.layer.borderColor = [UIColor whiteColor].CGColor;
        _nextClassButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
        [_nextClassButton setTitle:@"进入下节课" forState:UIControlStateNormal];
        [_nextClassButton addTarget:self action:@selector(goNextClassAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _nextClassButton;
}
- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)[PLVColorUtil colorFromHexString:@"#00B16C"].CGColor, (__bridge id)[PLVColorUtil colorFromHexString:@"#00E78D"].CGColor];
        _gradientLayer.locations = @[@0.5, @1.0];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1.0, 0);
    }
    return _gradientLayer;
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    [self addSubview:self.classImageView];
    [self.classImageView addSubview:self.titleLabel];
    [self.classImageView addSubview:self.durationTitleLabel];
    [self.classImageView addSubview:self.durationLabel];
    [self addSubview:self.nextClassView];
    [self.nextClassView addSubview:self.nextClassNoticeView];
    [self.nextClassNoticeView addSubview:self.nextClassNoticeLabel];
    [self.nextClassView addSubview:self.nextClassTitleLabel];
    [self.nextClassView addSubview:self.nextClassTimeLabel];
    [self.nextClassView addSubview:self.nextClassButton];
    [self.nextClassView.layer insertSublayer:self.gradientLayer atIndex:0];
}

- (void)updateClassTitleLabelBounds {
    CGSize labelSize = [self.nextClassTitleLabel textRectForBounds:CGRectMake(0.0, 0.0, 200, MAXFLOAT)
                                     limitedToNumberOfLines:2].size;
    self.nextClassTitleLabel.bounds = (CGRect){{0,0}, labelSize};
}

- (CAShapeLayer *)shapeLayerWithRect:(CGRect)rect cornerRadius:(CGFloat)cornerRadius {
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners: UIRectCornerBottomLeft|UIRectCornerBottomRight cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    layer.path = path.CGPath;
    return layer;
}

#pragma mark - [ Public Methods ]

- (void)setupDuration:(NSInteger)duration
           classTitle:(NSString *)title
            classTime:(NSString *)time
    nextClassCallback:(PLVHCClassAlertBlock)callback {
    if (title) {
        NSMutableString *titleMutableString = [NSMutableString stringWithString:title];
        //对课节名称换行处理 每行14个
        if (title.length > 14) {
            [titleMutableString insertString:@"\n" atIndex:14];
        }
        self.nextClassTitleLabel.text = titleMutableString;
    }
    NSString *durTimeStr = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",lround(floor(duration / 60 / 60)), lround(floor(duration / 60)) % 60, lround(floor(duration)) % 60];
    self.durationLabel.text = durTimeStr;
    self.nextClassTimeLabel.text = time;
    self.nextClassBlock = callback;
    [self updateClassTitleLabelBounds];
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)goNextClassAction {
    self.nextClassBlock ? self.nextClassBlock() : nil;
}

@end


@interface PLVHCStudentLinkMicAlertView ()

#pragma mark UI
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messgaeLabel;
@property (nonatomic, strong) UIButton *linkMicButton;

#pragma mark 数据
@property (nonatomic, copy) PLVHCClassAlertBlock linkMicCallback;//学生需要连麦回调
@property (nonatomic, strong) NSTimer *linkMicTimer; //连麦倒计时器
@property (nonatomic, assign) NSTimeInterval linkMicCountdown; //连麦倒计时长

@end

@implementation PLVHCStudentLinkMicAlertView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.linkMicCountdown = 5; //倒计时时长
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.titleLabel.center = CGPointMake(CGRectGetWidth(self.bounds)/2, 24 + CGRectGetHeight(self.titleLabel.bounds)/2);
    self.messgaeLabel.center = CGPointMake(self.titleLabel.center.x, CGRectGetMaxY(self.titleLabel.frame) + 12 + CGRectGetHeight(self.messgaeLabel.bounds)/2);
    self.linkMicButton.center = CGPointMake(self.titleLabel.center.x, CGRectGetMaxY(self.messgaeLabel.frame) + 17 + CGRectGetHeight(self.linkMicButton.bounds)/2);
}

#pragma mark - [ Public Method ]

- (void)studentLinkMicAlertCallback:(PLVHCClassAlertBlock)callback  {
    self.linkMicCallback = callback;
    self.linkMicTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:[PLVFWeakProxy proxyWithTarget:self] selector:@selector(linkMicCountdownTimerEvent) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.linkMicTimer forMode:NSRunLoopCommonModes];
    [self.linkMicTimer fire];
}

#pragma mark - [ Private Method ]

- (void)setupUI {
    self.backgroundColor = [PLVColorUtil colorFromHexString:@"#2B2F48"];
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = 16.0f;
    [self addSubview:self.titleLabel];
    [self addSubview:self.messgaeLabel];
    [self addSubview:self.linkMicButton];
}

#pragma mark Getter & Setter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.bounds = CGRectMake(0, 0, 170, 18);
        _titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Medium" size:18];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = @"老师正在邀请你上台";
    }
    return _titleLabel;
}
- (UILabel *)messgaeLabel {
    if (!_messgaeLabel) {
        _messgaeLabel = [[UILabel alloc] init];
        _messgaeLabel.bounds = CGRectMake(0, 0, 180, 16);
        _messgaeLabel.textColor = [PLVColorUtil colorFromHexString:@"#EEEEEE"];
        _messgaeLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        _messgaeLabel.textAlignment = NSTextAlignmentCenter;
        _messgaeLabel.alpha = 0.5;
        _messgaeLabel.text = @"5秒后将自动上台";
    }
    return _messgaeLabel;
}
- (UIButton *)linkMicButton {
    if (!_linkMicButton) {
        _linkMicButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _linkMicButton.bounds = CGRectMake(0, 0, 126, 36);
        _linkMicButton.layer.masksToBounds = YES;
        _linkMicButton.layer.cornerRadius = 18.0f;
        _linkMicButton.layer.borderWidth = 1.0f;
        _linkMicButton.layer.borderColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"].CGColor;
        _linkMicButton.titleLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:14];
        [_linkMicButton setTitleColor:[PLVColorUtil colorFromHexString:@"#FFFFFF"] forState:UIControlStateNormal];
        [_linkMicButton setTitle:@"立即上台" forState:UIControlStateNormal];
        [_linkMicButton addTarget:self action:@selector(linkMicButtonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _linkMicButton;
}

- (void)setLinkMicTimer:(NSTimer *)linkMicTimer {
    if (_linkMicTimer) {
        [_linkMicTimer invalidate];
        _linkMicTimer = nil;
    }
    if (linkMicTimer) {
        _linkMicTimer = linkMicTimer;
    }
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)linkMicButtonAction {
    if (self.linkMicCallback) { self.linkMicCallback();}
}

#pragma mark Timer

- (void)linkMicCountdownTimerEvent {
    if (self.linkMicCountdown > 0) {
        NSString *linkMicText = [NSString stringWithFormat:@"立即上台(%lds)",(long)self.linkMicCountdown];
        [self.linkMicButton setTitle:linkMicText forState:UIControlStateNormal];
        self.linkMicCountdown --;
    } else {
        //倒计时结束
        if (self.linkMicCallback) { self.linkMicCallback();}
        self.linkMicTimer = nil;
    }
}

@end

@implementation PLVHCPlaceholderAlertView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    self.imageView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.imageView.bounds));
    self.titleLabel.frame = CGRectMake(0, CGRectGetMaxY(self.imageView.frame) + 8, CGRectGetWidth(self.bounds), 16);
}

#pragma mark Getter & Setter

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.bounds = CGRectMake(0, 0, 60, 60);
        _imageView.image = [PLVHCUtils imageForLiveroomResource:@"plvhc_liveroom_placeholder_overtimenoclass_icon"];
    }
    return _imageView;
}
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [PLVColorUtil colorFromHexString:@"#EEEEEE"];
        _titleLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:12];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = @"老师正在准备课程,请稍后";
    }
    return _titleLabel;
}

- (void)setupUI {
    [self addSubview:self.imageView];
    [self addSubview:self.titleLabel];
}

@end
