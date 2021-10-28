//
//  PLVHCToolbarAreaView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCToolbarAreaView.h"

//工具类
#import "PLVHCUtils.h"
// 模块
#import "PLVRoomDataManager.h"

static CGFloat KPLVHCToolButtonSize = 36;
///讲师举手动画时长
static NSInteger KPLVHCTeacherRaiseHandDuration = 5;
///学生举手持续时间
static NSInteger KPLVHCStudentRaiseHandDuration = 10;

typedef NS_ENUM(NSInteger, PLVHCToolbarViewButtonType) {
    PLVHCToolbarViewButtonTypeClass = 1000,//上下课
    PLVHCToolbarViewButtonTypeDocument = 1001,//文档
    PLVHCToolbarViewButtonTypeMember = 1002,//成员
    PLVHCToolbarViewButtonTypeChat = 1003,//聊天
    PLVHCToolbarViewButtonTypeSetting = 1004,//设置
    PLVHCToolbarViewButtonTypeRaiseHand = 1006//举手
};

@interface PLVHCToolbarAreaView ()

/// 学生端
//举手
@property (nonatomic, strong) UIButton *raiseHandButton;
//倒计时遮罩层
@property (nonatomic, strong) UILabel *countdownLabel;
//学生举手持续时间
@property (nonatomic, strong) dispatch_source_t raiseHandTimer;

///教师端
//上下课按钮
@property (nonatomic, strong) UIButton *classButton;
//成员列表
@property (nonatomic, strong) UIButton *memberButton;
//文档按钮
@property (nonatomic, strong) UIButton *documentButton;
//收到学生端举手
@property (nonatomic, strong) UIImageView *raiseHandRemindImageView;
@property (nonatomic, strong) UILabel *raiseHandRemindLabel;
//举手提醒倒计时
@property (nonatomic, assign) NSInteger raiseHandRemindCountdown;
@property (nonatomic, strong) dispatch_source_t raiseHandRemindTimer;

///共用
@property (nonatomic, strong) UIView *backgroundView;
//设置按钮
@property (nonatomic, strong) UIButton *settingButton;
//发言
@property (nonatomic, strong) UIButton *chatButton;
//有新消息时的红点
@property (nonatomic, strong) UIView *messageRemindView;

///数据
//用户角色
@property (nonatomic, assign) PLVRoomUserType viewerType;
//讲师统计举手数量每次举手动画结束后清零
@property (nonatomic, assign) NSInteger raiseHandCount;

@end

@implementation PLVHCToolbarAreaView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupUI];
        [self setupModule];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateLayoutByStatus:_toolbarStatus];
}

#pragma mark - Getter && Setter

- (UIButton *)chatButton {
    if (!_chatButton) {
        UIButton *chatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        chatButton.frame = CGRectMake(0, 0, KPLVHCToolButtonSize, KPLVHCToolButtonSize);
        chatButton.tag = PLVHCToolbarViewButtonTypeChat;
        [chatButton setImage:[PLVHCUtils imageForToolbarResource:@"plvhc_toolbar_chat_normal"] forState:UIControlStateNormal];
        [chatButton setImage:[PLVHCUtils imageForToolbarResource:@"plvhc_toolbar_chat_actived"] forState:UIControlStateHighlighted];
        [chatButton setImage:[PLVHCUtils imageForToolbarResource:@"plvhc_toolbar_chat_actived"] forState:UIControlStateSelected];
        [chatButton addTarget:self action:@selector(chatAction:) forControlEvents:UIControlEventTouchUpInside];
        _chatButton = chatButton;
    }
    return _chatButton;
}
- (UIView *)messageRemindView {
    if (!_messageRemindView) {
        _messageRemindView = [[UIView alloc] init];
        _messageRemindView.bounds = CGRectMake(0, 0, 10, 10);
        _messageRemindView.layer.cornerRadius = 5;
        _messageRemindView.backgroundColor = [PLVColorUtil colorFromHexString:@"#FA5151"];
        _messageRemindView.hidden = YES;
    }
    return _messageRemindView;
}
- (UIButton *)settingButton {
    if (!_settingButton) {
        UIButton *settingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        settingButton.frame = CGRectMake(0, 0, KPLVHCToolButtonSize, KPLVHCToolButtonSize);
        settingButton.tag = PLVHCToolbarViewButtonTypeSetting;
        [settingButton setImage:[PLVHCUtils imageForToolbarResource:@"plvhc_toolbar_setting_normal"] forState:UIControlStateNormal];
        [settingButton setImage:[PLVHCUtils imageForToolbarResource:@"plvhc_toolbar_setting_actived"] forState:UIControlStateHighlighted];
        [settingButton setImage:[PLVHCUtils imageForToolbarResource:@"plvhc_toolbar_setting_actived"] forState:UIControlStateSelected];
        [settingButton addTarget:self action:@selector(settingAction:) forControlEvents:UIControlEventTouchUpInside];
        _settingButton = settingButton;
    }
    return _settingButton;
}
- (UIButton *)raiseHandButton {
    if (!_raiseHandButton) {
        UIButton *raiseHandButton = [UIButton buttonWithType:UIButtonTypeCustom];
        raiseHandButton.frame = CGRectMake(0, 0, KPLVHCToolButtonSize, KPLVHCToolButtonSize);
        raiseHandButton.tag = PLVHCToolbarViewButtonTypeRaiseHand;
        [raiseHandButton setImage:[PLVHCUtils imageForToolbarResource:@"plvhc_toolbar_raisehand_normal"] forState:UIControlStateNormal];
        [raiseHandButton setImage:[PLVHCUtils imageForToolbarResource:@"plvhc_toolbar_raisehand_actived"] forState:UIControlStateHighlighted];
        [raiseHandButton setImage:[PLVHCUtils imageForToolbarResource:@"plvhc_toolbar_raisehand_actived"] forState:UIControlStateSelected];
        [raiseHandButton addTarget:self action:@selector(raiseHandAction:) forControlEvents:UIControlEventTouchUpInside];
        _raiseHandButton = raiseHandButton;
    }
    return _raiseHandButton;
}

- (UIButton *)classButton {
    if (!_classButton) {
        UIButton *classButton = [UIButton buttonWithType:UIButtonTypeCustom];
        classButton.frame = CGRectMake(0, 0, KPLVHCToolButtonSize, KPLVHCToolButtonSize);
        classButton.tag = PLVHCToolbarViewButtonTypeClass;
        [classButton setImage:[PLVHCUtils imageForToolbarResource:@"plvhc_toolbar_startclass_normal"] forState:UIControlStateNormal];
        [classButton addTarget:self action:@selector(classAction:) forControlEvents:UIControlEventTouchUpInside];
        _classButton = classButton;
    }
    return _classButton;
}
- (UIButton *)memberButton {
    if (!_memberButton) {
        UIButton *memberButton = [UIButton buttonWithType:UIButtonTypeCustom];
        memberButton.frame = CGRectMake(0, 0, KPLVHCToolButtonSize, KPLVHCToolButtonSize);
        memberButton.tag = PLVHCToolbarViewButtonTypeMember;
        [memberButton setImage:[PLVHCUtils imageForToolbarResource:@"plvhc_toolbar_member_normal"] forState:UIControlStateNormal];
        [memberButton setImage:[PLVHCUtils imageForToolbarResource:@"plvhc_toolbar_member_actived"] forState:UIControlStateHighlighted];
        [memberButton setImage:[PLVHCUtils imageForToolbarResource:@"plvhc_toolbar_member_actived"] forState:UIControlStateSelected];
        [memberButton addTarget:self action:@selector(memberAction:) forControlEvents:UIControlEventTouchUpInside];
        _memberButton = memberButton;
    }
    return _memberButton;
}
- (UIButton *)documentButton {
    if (!_documentButton) {
        UIButton *documentButton = [UIButton buttonWithType:UIButtonTypeCustom];
        documentButton.frame = CGRectMake(0, 0, KPLVHCToolButtonSize, KPLVHCToolButtonSize);
        documentButton.tag = PLVHCToolbarViewButtonTypeDocument;
        [documentButton setImage:[PLVHCUtils imageForToolbarResource:@"plvhc_toolbar_document_normal"] forState:UIControlStateNormal];
        [documentButton setImage:[PLVHCUtils imageForToolbarResource:@"plvhc_toolbar_document_actived"] forState:UIControlStateHighlighted];
        [documentButton setImage:[PLVHCUtils imageForToolbarResource:@"plvhc_toolbar_document_actived"] forState:UIControlStateSelected];
        [documentButton addTarget:self action:@selector(documentAction:) forControlEvents:UIControlEventTouchUpInside];
        _documentButton = documentButton;
    }
    return _documentButton;
}
- (UIImageView *)raiseHandRemindImageView {
    if (!_raiseHandRemindImageView) {
        _raiseHandRemindImageView = [[UIImageView alloc] init];
        _raiseHandRemindImageView.bounds = CGRectMake(0, 0, 30, 30);
        ///举手动画数据
        NSMutableArray *imageArray = [NSMutableArray arrayWithCapacity:7];
        for (NSInteger index = 0; index < 7; index ++) {
            NSInteger imageNameIndex = index + 1;
            NSString *imageName = [NSString stringWithFormat:@"plvhc_toolbar_raisehand_0%ld", (long)imageNameIndex];
            UIImage *image = [PLVHCUtils imageForToolbarResource:imageName];
            [imageArray addObject:image];
        }
        _raiseHandRemindImageView.animationImages = imageArray;
        _raiseHandRemindImageView.animationDuration = 0.6; //2s/3个循环动画」
        _raiseHandRemindImageView.animationRepeatCount = 0;
        _raiseHandRemindImageView.hidden = YES;
        _raiseHandRemindImageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(raiseHandTapAction)];
        [_raiseHandRemindImageView addGestureRecognizer:tapGesture];
    }
    return _raiseHandRemindImageView;
}
- (UILabel *)raiseHandRemindLabel {
    if (!_raiseHandRemindLabel) {
        UILabel *raiseHandRemindLabel = [[UILabel alloc] init];
        raiseHandRemindLabel.frame = CGRectMake(KPLVHCToolButtonSize - 16, KPLVHCToolButtonSize - 16, 16, 16);
        raiseHandRemindLabel.textColor = [UIColor whiteColor];
        raiseHandRemindLabel.font = [UIFont fontWithName:@"PingFangSC-Semibold" size:12];
        raiseHandRemindLabel.textAlignment = NSTextAlignmentCenter;
        raiseHandRemindLabel.layer.cornerRadius = 8.0f;
        raiseHandRemindLabel.layer.backgroundColor = [PLVColorUtil colorFromHexString:@"#FF2639"].CGColor;
        raiseHandRemindLabel.layer.masksToBounds = YES;
        _raiseHandRemindLabel = raiseHandRemindLabel;
    }
    return _raiseHandRemindLabel;
}
- (UILabel *)countdownLabel {
    if (!_countdownLabel) {
        UILabel *countdownLabel = [[UILabel alloc] init];
        countdownLabel.frame = CGRectMake(0, 0, KPLVHCToolButtonSize, KPLVHCToolButtonSize);
        countdownLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
        countdownLabel.textColor = [UIColor whiteColor];
        countdownLabel.font = [UIFont fontWithName:@"DINAlternate-Bold" size:14.0f];
        countdownLabel.textAlignment = NSTextAlignmentCenter;
        countdownLabel.layer.cornerRadius = KPLVHCToolButtonSize/2;
        countdownLabel.clipsToBounds = YES;
        countdownLabel.hidden = YES;
        _countdownLabel = countdownLabel;
    }
    return _countdownLabel;
}
- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
        _backgroundView.backgroundColor = [UIColor clearColor];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction)];
        [_backgroundView addGestureRecognizer:tapGesture];
    }
    return _backgroundView;
}

- (void)setToolbarStatus:(PLVHCToolbarViewStatus)toolbarStatus {
    _toolbarStatus = toolbarStatus;
    if (_toolbarStatus == PLVHCToolbarViewStatusTeacherPreparing) {
        [self.classButton setImage:[PLVHCUtils imageForToolbarResource:@"plvhc_toolbar_startclass_normal"] forState:UIControlStateNormal];
    } else if (_toolbarStatus == PLVHCToolbarViewStatusTeacherInClass) {
        [self.classButton setImage:[PLVHCUtils imageForToolbarResource:@"plvhc_toolbar_finishclass_normal"] forState:UIControlStateNormal];
    }
    [self updateLayoutByStatus:toolbarStatus];
}

#pragma mark - [ Public Methods ]

- (void)startClass {
    if (self.viewerType == PLVRoomUserTypeSCStudent) {
        self.toolbarStatus = PLVHCToolbarViewStatusStudentInClass;
    } else {
        self.toolbarStatus = PLVHCToolbarViewStatusTeacherInClass;
    }
    [self setClassButtonEnable:YES];
}

- (void)finishClass {
    if (self.viewerType == PLVRoomUserTypeSCStudent) {
        self.toolbarStatus = PLVHCToolbarViewStatusStudentPreparing;
    } else {
        self.toolbarStatus = PLVHCToolbarViewStatusTeacherPreparing;
    }
    [self setClassButtonEnable:YES];
    [self destroyTimer];
}

- (void)clear {
    [self destroyTimer];
}

- (void)toolbarAreaViewRaiseHand:(BOOL)raiseHand
                          userId:(NSString *)userId
                           count:(NSInteger)count {
    if (self.viewerType == PLVRoomUserTypeSCStudent ||
        [self isLoginUser:userId]) {
        return;
    }
    
    if (count <= 0) {  //全部取消举手
        [self stopRaiseHandCountdown];
        return;
    }
    
    if (!raiseHand) { //取消举手
        self.raiseHandCount = MIN(count, 99);
        self.raiseHandRemindLabel.text = [NSString stringWithFormat:@"%ld",(long)self.raiseHandCount];
        return;
    }

    if (raiseHand && count > 0) {//举手
        self.raiseHandCount = MIN(count, 99);
        [self startRaiseHandCountdown];
    }
}

- (void)clearAllButtonSelected {
    [self clearSelectedBySelectedButton:nil];
}

- (void)toolbarAreaViewReceiveNewMessage {
    if (!self.chatButton.isSelected) {
        self.messageRemindView.hidden = NO;
    }
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    [self addSubview:self.chatButton];
    [self addSubview:self.settingButton];
    [self addSubview:self.raiseHandButton];
    [self addSubview:self.classButton];
    [self addSubview:self.documentButton];
    [self addSubview:self.memberButton];
    [self.raiseHandButton addSubview:self.countdownLabel];
    [self addSubview:self.raiseHandRemindImageView];
    [self.raiseHandRemindImageView addSubview:self.raiseHandRemindLabel];
    [self.chatButton addSubview:self.messageRemindView];
}

- (void)setupModule {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    self.viewerType = roomData.roomUser.viewerType;
    if (self.viewerType == PLVRoomUserTypeSCStudent) {
        if (roomData.lessonInfo.hiClassStatus == PLVHiClassStatusNotInClass) {
            self.toolbarStatus = PLVHCToolbarViewStatusStudentPreparing;
        } else if (roomData.lessonInfo.hiClassStatus == PLVHiClassStatusInClass) {
            self.toolbarStatus = PLVHCToolbarViewStatusStudentInClass;
        } else {
            self.toolbarStatus = PLVHCToolbarViewStatusStudentPreparing;
        }
    } else {
        if (roomData.lessonInfo.hiClassStatus == PLVHiClassStatusInClass) {
            self.toolbarStatus = PLVHCToolbarViewStatusTeacherInClass;
        } else {
            self.toolbarStatus = PLVHCToolbarViewStatusTeacherPreparing;
        }
    }
}

///通过状态更新UI布局
- (void)updateLayoutByStatus:(PLVHCToolbarViewStatus)status {
    self.messageRemindView.center = CGPointMake(CGRectGetWidth(self.chatButton.bounds) - CGRectGetWidth(self.messageRemindView.bounds)/2, CGRectGetHeight(self.messageRemindView.bounds)/2);
    CGFloat itemSpacing = (CGRectGetHeight(self.bounds) - KPLVHCToolButtonSize * 5 - 20 * 2)/4;
    self.chatButton.hidden = YES;
    self.settingButton.hidden = YES;
    self.raiseHandButton.hidden = YES;
    self.classButton.hidden = YES;
    self.documentButton.hidden = YES;
    self.memberButton.hidden = YES;
    switch (status) {
        case PLVHCToolbarViewStatusStudentPreparing: {
            self.chatButton.hidden = NO;
            self.settingButton.hidden = NO;
            self.chatButton.center = CGPointMake(CGRectGetWidth(self.bounds) - KPLVHCToolButtonSize/2, CGRectGetHeight(self.bounds)/2 - 5 - KPLVHCToolButtonSize/2);
            self.settingButton.center = CGPointMake(self.chatButton.center.x, self.chatButton.center.y + KPLVHCToolButtonSize + 8);
        }
            break;
        case PLVHCToolbarViewStatusStudentInClass: {
            self.chatButton.hidden = NO;
            self.settingButton.hidden = NO;
            self.raiseHandButton.hidden = NO;
            self.chatButton.center = CGPointMake(CGRectGetWidth(self.bounds) - KPLVHCToolButtonSize/2, CGRectGetHeight(self.bounds)/2);
            self.raiseHandButton.center = CGPointMake(self.chatButton.center.x, self.chatButton.frame.origin.y - KPLVHCToolButtonSize/2 - 8);
            self.settingButton.center = CGPointMake(self.chatButton.center.x, self.chatButton.center.y + KPLVHCToolButtonSize + 8);
        }
            break;
        case PLVHCToolbarViewStatusTeacherPreparing:
        case PLVHCToolbarViewStatusTeacherInClass: {
            self.chatButton.hidden = NO;
            self.settingButton.hidden = NO;
            self.classButton.hidden = NO;
            self.documentButton.hidden = NO;
            self.memberButton.hidden = NO;
            self.memberButton.center = CGPointMake(CGRectGetWidth(self.bounds) - KPLVHCToolButtonSize/2, CGRectGetHeight(self.bounds)/2);
            //向上偏移
            self.documentButton.center = CGPointMake(self.memberButton.center.x, self.memberButton.center.y - KPLVHCToolButtonSize - itemSpacing);
            self.classButton.center = CGPointMake(self.memberButton.center.x, self.documentButton.center.y - KPLVHCToolButtonSize - itemSpacing);
            //向下偏移
            self.chatButton.center = CGPointMake(self.memberButton.center.x, self.memberButton.center.y + KPLVHCToolButtonSize + itemSpacing);
            self.settingButton.center = CGPointMake(self.memberButton.center.x, self.chatButton.center.y + KPLVHCToolButtonSize + itemSpacing);
            //举手提醒按钮
            self.raiseHandRemindImageView.center = CGPointMake(self.settingButton.center.x - KPLVHCToolButtonSize - 14, self.memberButton.center.y);
        }
            break;
        default:
            break;
    }
}

- (void)setClassButtonEnable:(BOOL)enable {
    self.classButton.enabled = enable;
    self.classButton.alpha = enable ? 1.0 : 0.5;
}

///选中按钮后如果之前有选中的按钮将其选中状态设置为NO并执行delegate
- (void)clearSelectedBySelectedButton:(UIButton *)sender {
   if (sender.selected) return;
    
    for (UIButton *button in self.subviews) {
        if (button &&
            [button isKindOfClass:UIButton.class] &&
            button.isSelected) {
            switch (button.tag) {
                case PLVHCToolbarViewButtonTypeDocument:
                    [self documentAction:button];
                    break;
                case PLVHCToolbarViewButtonTypeMember:
                    [self memberAction:button];
                    break;
                case PLVHCToolbarViewButtonTypeChat:
                    [self chatAction:button];
                    break;
                case PLVHCToolbarViewButtonTypeSetting:
                    [self settingAction:button];
                    break;
                default:
                    break;
            }
        }
    }
}

//设置点击背景是否显示
- (void)setBackgroundViewHiddenWithButton:(UIButton *)sender {
    if (!self.backgroundView.superview) {
        self.backgroundView.frame = self.superview.bounds;
        [self.superview insertSubview:self.backgroundView belowSubview:self];
    }
    self.backgroundView.hidden = !sender.isSelected;
}

- (BOOL)isLoginUser:(NSString *)userId {
    if (!userId || ![userId isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    BOOL isLoginUser = [userId isEqualToString:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId];
    return isLoginUser;
}

#pragma mark - 举手操作
///讲师端提示的举手倒计时动画
- (void)startRaiseHandCountdownTimer {
    dispatch_queue_t quene = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.raiseHandRemindTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, quene);
    dispatch_source_set_timer(self.raiseHandRemindTimer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(self.raiseHandRemindTimer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.raiseHandRemindCountdown <= 0) {
                [self stopRaiseHandCountdown];
            } else {
                self.raiseHandRemindCountdown --;
            }
        });
    });
    dispatch_resume(self.raiseHandRemindTimer);
}

///添加播放动画
- (void)startRaiseHandCountdown {
    self.raiseHandRemindImageView.hidden = NO;
    self.raiseHandRemindLabel.text = [NSString stringWithFormat:@"%ld",(long)self.raiseHandCount];
    if (!self.raiseHandRemindImageView.isAnimating) {
        [self.raiseHandRemindImageView startAnimating];
    }
    self.raiseHandRemindCountdown = KPLVHCTeacherRaiseHandDuration;//重置动画时间
    if (!self.raiseHandRemindTimer) {
        [self startRaiseHandCountdownTimer];
    }
}

- (void)stopRaiseHandCountdown {
    [self.raiseHandRemindImageView stopAnimating];
    self.raiseHandRemindImageView.hidden = YES;
    self.raiseHandCount = 0;
    [self destroyTimer];
}

///销毁倒计时定时器
- (void)destroyTimer {
    if (self.raiseHandRemindTimer) {
        dispatch_cancel(self.raiseHandRemindTimer);
        self.raiseHandRemindTimer = nil;
    }
    if (self.raiseHandTimer) {
        dispatch_cancel(self.raiseHandTimer);
        self.raiseHandTimer = nil;
    }
}

#pragma mark Notify Delegate

- (void)notifyDelegateHandUp {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(toolbarAreaView_handUpButtonSelected:userId:)]) {
        NSString *userId = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerId;
        [self.delegate toolbarAreaView_handUpButtonSelected:self userId:userId];
    }
}

#pragma mark - [ Event ]

#pragma mark Gesture

- (void)tapGestureAction {
    [self clearAllButtonSelected];
    self.backgroundView.hidden = YES;
}

- (void)raiseHandTapAction {
    [self memberAction:self.memberButton];
}

#pragma mark Action

- (void)settingAction:(UIButton *)sender {
    BOOL isSelected = sender.isSelected;
    [self clearSelectedBySelectedButton:sender];
    sender.selected = !isSelected;
    [self setBackgroundViewHiddenWithButton:sender];
    if (self.delegate && [self.delegate respondsToSelector:@selector(toolbarAreaView:settingButtonSelected:)]) {
        [self.delegate toolbarAreaView:self settingButtonSelected:sender.isSelected];
    }
}
- (void)chatAction:(UIButton *)sender {
    BOOL isSelected = sender.isSelected;
    [self clearSelectedBySelectedButton:sender];
    sender.selected = !isSelected;
    [self setBackgroundViewHiddenWithButton:sender];
    if (sender.isSelected) {
        self.messageRemindView.hidden = YES;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(toolbarAreaView:chatroomButtonSelected:)]) {
        [self.delegate toolbarAreaView:self chatroomButtonSelected:sender.isSelected];
    }
}
- (void)raiseHandAction:(UIButton *)sender {
    [self clearSelectedBySelectedButton:sender];
    if (sender.selected) return;
    sender.selected = YES;
    sender.userInteractionEnabled = NO;
    __block NSInteger countdown = KPLVHCStudentRaiseHandDuration;
    dispatch_queue_t quene = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.raiseHandTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, quene);
    dispatch_source_set_timer(self.raiseHandTimer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(self.raiseHandTimer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (countdown <= 0) {
                sender.userInteractionEnabled = YES;
                sender.selected = NO;
                self.countdownLabel.text = @"";
                self.countdownLabel.hidden = YES;
                [self destroyTimer];
            } else {
                self.countdownLabel.hidden = NO;
                self.countdownLabel.text = [NSString stringWithFormat:@"%lds", (long)countdown];
                countdown--;
            }
        });
    });
    dispatch_resume(self.raiseHandTimer);
    [self notifyDelegateHandUp];
}
- (void)classAction:(UIButton *)sender {
    [self clearSelectedBySelectedButton:sender];
    BOOL startClass = _toolbarStatus != PLVHCToolbarViewStatusTeacherInClass;
    if (self.delegate && [self.delegate respondsToSelector:@selector(toolbarAreaView_classButtonSelected:startClass:)]) {
        [self.delegate toolbarAreaView_classButtonSelected:self startClass:startClass];
    }
}
- (void)memberAction:(UIButton *)sender {
    BOOL isSelected = sender.isSelected;
    [self clearSelectedBySelectedButton:sender];
    sender.selected = !isSelected;
    [self setBackgroundViewHiddenWithButton:sender];
    if (self.delegate && [self.delegate respondsToSelector:@selector(toolbarAreaView:memberButtonSelected:)]) {
        [self.delegate toolbarAreaView:self memberButtonSelected:sender.isSelected];
    }
}
- (void)documentAction:(UIButton *)sender {
    BOOL isSelected = sender.isSelected;
    [self clearSelectedBySelectedButton:sender];
    sender.selected = !isSelected;
    [self setBackgroundViewHiddenWithButton:sender];
    if (self.delegate && [self.delegate respondsToSelector:@selector(toolbarAreaView:documentButtonSelected:)]) {
        [self.delegate toolbarAreaView:self documentButtonSelected:sender.isSelected];
    }
}

@end
