//
//  PLVSAMemberPopup.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/8.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVSAMemberPopup.h"
// 工具
#import "PLVSAUtils.h"
#import "PLVMultiLanguageManager.h"
// 模块
#import "PLVRoomDataManager.h"
#import "PLVChatUser.h"

static NSInteger kButtonTagConst = 100;

typedef NS_ENUM(NSInteger, PLVSAMemberPopupButton) {
    PLVSAMemberPopupButtonCamera = 0,
    PLVSAMemberPopupButtonMicrophone,
    PLVSAMemberPopupButtonAuthSpeaker,
    PLVSAMemberPopupButtonKick,
    PLVSAMemberPopupButtonBanned
};

typedef NS_ENUM(NSInteger, PLVSAMemberPopupDirection) {
    PLVSAMemberPopupDirectionTop = 0,
    PLVSAMemberPopupDirectionBottom,
    PLVSAMemberPopupDirectionLeft
};

@interface PLVSAMemberPopup ()

/// UI
@property (nonatomic, strong) UIBezierPath *bezierPath;

/// 数据
@property (nonatomic, strong) PLVChatUser *chatUser;
@property (nonatomic, assign) CGFloat centerY;
@property (nonatomic, strong) NSArray *buttonTypeArray;
@property (nonatomic, assign) PLVSAMemberPopupDirection popupDirection; //popup弹出的方向

@end

@implementation PLVSAMemberPopup

#pragma mark - [ Life Cycle ]

- (instancetype)initWithChatUser:(PLVChatUser *)chatUser centerYPoint:(CGFloat)centerY {
    self = [super init];
    if (self) {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#212121"];
        self.layer.masksToBounds = YES;
        
        _chatUser = chatUser;
        _centerY = centerY;
        
        [self configData];
        [self updateUI];
    }
    return self;
}

#pragma mark - [ Override ]

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *touchView = [super hitTest:point withEvent:event];
    if (touchView != self &&
        touchView.superview != self) {
        [self dismiss];
    }
    return touchView;
}

#pragma mark - [ Public Method ]

- (void)showAtView:(UIView *)superView {
    [superView addSubview:self];
}

#pragma mark - [ Private Method ]

- (void)dismiss {
    [self removeFromSuperview];
    [self performSelector:@selector(callDidDismissBlock) withObject:nil afterDelay:0.5];
}

- (void)callDidDismissBlock {
    if (self.didDismissBlock) {
        self.didDismissBlock();
    }
}

#pragma mark Initialize

- (void)configData {
    BOOL linkMicing = self.chatUser.onlineUser ? YES : NO;
    BOOL specialType = [PLVRoomUser isSpecialIdentityWithUserType:self.chatUser.userType];
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    
    // 配置需要显示的按钮类型
    NSMutableArray *muArray = [[NSMutableArray alloc] initWithCapacity:4];
    if (linkMicing) {
        BOOL isOnlyAudio = [PLVRoomDataManager sharedManager].roomData.isOnlyAudio;
        if ((self.chatUser.userType == PLVRoomUserTypeGuest && !isOnlyAudio) ||
            [PLVRoomDataManager sharedManager].roomData.channelLinkMicMediaType == PLVChannelLinkMicMediaType_Video) {
            [muArray addObjectsFromArray:@[@(PLVSAMemberPopupButtonCamera), @(PLVSAMemberPopupButtonMicrophone)]];
        } else {
            [muArray addObjectsFromArray:@[@(PLVSAMemberPopupButtonMicrophone)]];
        }
    }
    
    if (self.chatUser.userType == PLVRoomUserTypeGuest) {
        [muArray addObject:@(PLVSAMemberPopupButtonAuthSpeaker)];
    }
    
    if (!specialType) {
        [muArray addObjectsFromArray:@[@(PLVSAMemberPopupButtonKick), @(PLVSAMemberPopupButtonBanned)]];
    }
    self.buttonTypeArray = [muArray copy];
    
    // 根据需要显示的按钮，获取气泡宽高
    CGFloat width = 112;
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:16.0]}; // 文本属性
    if ([self.buttonTypeArray containsObject:@(PLVSAMemberPopupButtonAuthSpeaker)]) {
        NSString *text = [self labelTextWithType:PLVSAMemberPopupButtonAuthSpeaker];
        CGSize textSize = [text sizeWithAttributes:attributes];
        width = MAX(textSize.width + 90, width);
    }
    
    if (self.chatUser.banned) {
        NSString *text = [self labelTextWithType:PLVSAMemberPopupButtonBanned];
        CGSize textSize = [text sizeWithAttributes:attributes];
        width = MAX(textSize.width + 90, width);
    }
    
    if ([self.buttonTypeArray containsObject:@(PLVSAMemberPopupButtonKick)]) {
        NSString *text = [self labelTextWithType:PLVSAMemberPopupButtonKick];
        CGSize textSize = [text sizeWithAttributes:attributes];
        width = MAX(textSize.width + 90, width);
    }
    
    if ([self.buttonTypeArray containsObject:@(PLVSAMemberPopupButtonCamera)] ||
               [self.buttonTypeArray containsObject:@(PLVSAMemberPopupButtonMicrophone)]) {
        NSString *text = [self labelTextWithType:PLVSAMemberPopupButtonMicrophone];
        CGSize textSize = [text sizeWithAttributes:attributes];
        width = MAX(textSize.width + 90, width);
    }
    
    if (isPad) {
        width += 30;
    }
    CGFloat height = [self.buttonTypeArray count] * 44 + 10 * 2; // 44为每个按钮的高度，10为按钮与气泡的内部间隔

    // 配置popup的frame和气泡形状的贝塞尔曲线
    CGFloat screenWidth = PLVScreenWidth;
    CGFloat screenHeight = PLVScreenHeight;
    CGFloat bottom = [PLVSAUtils sharedUtils].areaInsets.bottom;
    CGFloat top = [PLVSAUtils sharedUtils].areaInsets.top;
    // 屏幕centerY以下位置不足以显示气泡，则气泡在centerY顶部，顶部不足以显示则在左侧显示
    // 25是centerY到气泡的Y轴距离，9是防止气泡底部贴着设备屏幕下沿
    if ((height < (screenHeight - self.centerY - bottom - 9 - 25))) {
        height += 9;
        self.popupDirection = PLVSAMemberPopupDirectionBottom;
    } else if ((height < (self.centerY - top - 9 - 25))) {
        height += 9;
        self.popupDirection = PLVSAMemberPopupDirectionTop;
    } else {
        width += 9;
        self.popupDirection = PLVSAMemberPopupDirectionLeft;
    }
    
    CGFloat originY = 0;
    CGFloat leftMargin = isPad ? 32 : 9;
    if (self.popupDirection == PLVSAMemberPopupDirectionTop) {
        originY = self.centerY - 25 - height;
        self.bezierPath = [[self class] aboveBezierPathWithSize:CGSizeMake(width, height)];
    } else if (self.popupDirection == PLVSAMemberPopupDirectionBottom) {
        originY = self.centerY + 25;
        self.bezierPath = [[self class] belowBezierPathWithSize:CGSizeMake(width, height)];
    } else {
        originY = self.centerY - height/2;
        leftMargin = 32 + 36;
        self.bezierPath = [[self class] leftBezierPathWithSize:CGSizeMake(width, height)];
    }
    self.frame = CGRectMake(screenWidth - leftMargin - width, originY, width, height);
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = self.bezierPath.CGPath;
    self.layer.mask = shapeLayer;
}

- (void)updateUI {
    CGFloat originX = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 25.0 : 10.0;
    CGFloat originY = 10.0 + (self.popupDirection == PLVSAMemberPopupDirectionBottom ? 9 : 0);
    for (NSNumber *typeNumber in self.buttonTypeArray) {
        PLVSAMemberPopupButton buttonType = [typeNumber integerValue];
        
        // 配置 icon、文本的容器
        UIView *view = [[UIView alloc] init];
        view.frame = CGRectMake(originX, originY, self.bounds.size.width - 12 * 2, 44);
        [self addSubview:view];
        
        // 配置 icon
        UIImageView *icon = [[UIImageView alloc] init];
        icon.image = [self iconImageWithType:buttonType];
        icon.frame = CGRectMake(15, 10, 24, 24);
        [view addSubview:icon];
        
        // 配置文本
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:14];
        label.textColor = [PLVColorUtil colorFromHexString:@"#F0F1F5"];
        label.frame = CGRectMake(15 + 24 + 9, 12, CGRectGetWidth(view.frame) - (15 + 24 + 9), 20);
        label.text = [self labelTextWithType:buttonType];
        [view addSubview:label];
        
        // 配置按钮
        UIButton *button = [self buttonWithType:buttonType];
        button.frame = view.frame;
        [self addSubview:button];
        
        originY += 44;
    }
}

#pragma mark Utils

- (UIButton *)buttonWithType:(PLVSAMemberPopupButton)type {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.font = [UIFont systemFontOfSize:14];
    [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    button.tag = type + kButtonTagConst;
    switch (type) {
        case PLVSAMemberPopupButtonCamera:
            button.selected = !self.chatUser.onlineUser.currentCameraOpen;
            break;
        case PLVSAMemberPopupButtonMicrophone:
            button.selected = !self.chatUser.onlineUser.currentMicOpen;
            break;
        case PLVSAMemberPopupButtonAuthSpeaker:
            button.selected = self.chatUser.onlineUser.isRealMainSpeaker;
            break;
        case PLVSAMemberPopupButtonBanned:
            button.selected = self.chatUser.banned;
            break;
        default:
            break;
    }
    
    return button;
}

- (UIImage *)iconImageWithType:(PLVSAMemberPopupButton)type {
    NSString *imageName = nil;
    switch (type) {
        case PLVSAMemberPopupButtonCamera: {
            if (self.chatUser.onlineUser && self.chatUser.onlineUser.currentCameraOpen) {
                imageName = @"plvsa_member_popup_camera_icon";
            } else {
                imageName = @"plvsa_member_popup_camera_icon_selected";
            }
        } break;
        case PLVSAMemberPopupButtonMicrophone: {
            if (self.chatUser.onlineUser && self.chatUser.onlineUser.currentMicOpen) {
                imageName = @"plvsa_member_popup_mic_icon";
            } else {
                imageName = @"plvsa_member_popup_mic_icon_selected";
            }
        } break;
        case PLVSAMemberPopupButtonAuthSpeaker: {
            imageName = @"plvsa_member_popup_speaker_icon";
        } break;
        case PLVSAMemberPopupButtonKick: {
            imageName = @"plvsa_member_popup_kick_icon";
        } break;
        case PLVSAMemberPopupButtonBanned: {
            imageName = @"plvsa_member_popup_ban_icon";
        } break;
        default:
            break;
    }
    if (imageName) {
        UIImage *image = [PLVSAUtils imageForMemberResource:imageName];
        return image;
    } else {
        return nil;
    }
}

- (NSString *)labelTextWithType:(PLVSAMemberPopupButton)type {
    NSString *buttonTitle = @"";
    switch (type) {
        case PLVSAMemberPopupButtonCamera: {
            buttonTitle = PLVLocalizedString(@"摄像头");
        } break;
        case PLVSAMemberPopupButtonMicrophone: {
            buttonTitle = PLVLocalizedString(@"麦克风");
        } break;
        case PLVSAMemberPopupButtonAuthSpeaker: {
            if (self.chatUser.onlineUser && self.chatUser.onlineUser.isRealMainSpeaker) {
                buttonTitle = PLVLocalizedString(@"移除主讲权限");
            } else {
                buttonTitle = PLVLocalizedString(@"授予主讲权限");
            }
        } break;
        case PLVSAMemberPopupButtonKick: {
            buttonTitle = PLVLocalizedString(@"踢出");
        } break;
        case PLVSAMemberPopupButtonBanned: {
            buttonTitle = self.chatUser.banned ? PLVLocalizedString(@"取消禁言") : PLVLocalizedString(@"禁言");
        } break;
        default:
            break;
    }
    return buttonTitle;
}

+ (UIBezierPath *)aboveBezierPathWithSize:(CGSize)size {
    CGFloat conner = 8.0; // 圆角大小
    CGFloat trangleHeight = 9.0; // 箭头高度
    CGFloat trangleWidthForHalf = 5.0; // 箭头宽度的一半

    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    
    // 从左上角开始，顺时针绘制气泡
    [bezierPath moveToPoint:CGPointMake(conner, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width-conner, 0)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width, conner) controlPoint:CGPointMake(size.width, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width, size.height- conner - trangleHeight)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width - conner, size.height - trangleHeight) controlPoint:CGPointMake(size.width, size.height - trangleHeight)];
    
    // 从右往左绘制箭头
    [bezierPath addLineToPoint:CGPointMake(size.width - 39 + trangleWidthForHalf, size.height - trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(size.width - 39, size.height)];
    [bezierPath addLineToPoint:CGPointMake(size.width - 39 - trangleWidthForHalf, size.height - trangleHeight)];
    
    // 继续顺时针绘制气泡
    [bezierPath addLineToPoint:CGPointMake(conner, size.height - trangleHeight)];
    [bezierPath addQuadCurveToPoint:CGPointMake(0, size.height - conner - trangleHeight) controlPoint:CGPointMake(0, size.height - trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(0, conner)];
    [bezierPath addQuadCurveToPoint:CGPointMake(conner, 0) controlPoint:CGPointMake(0, 0)];
    
    // 气泡绘制完毕，关闭贝塞尔曲线
    [bezierPath closePath];
    return bezierPath;
}

+ (UIBezierPath *)belowBezierPathWithSize:(CGSize)size {
    CGFloat conner = 8.0; // 圆角大小
    CGFloat trangleHeight = 9.0; // 箭头高度
    CGFloat trangleWidthForHalf = 5.0; // 箭头宽度的一半

    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    
    // 从左上角开始，顺时针绘制气泡
    [bezierPath moveToPoint:CGPointMake(conner, trangleHeight)];
    
    // 从左往右绘制箭头
    [bezierPath addLineToPoint:CGPointMake(size.width - 39 - trangleWidthForHalf, trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(size.width - 39, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width - 39 + trangleWidthForHalf, trangleHeight)];
    
    // 继续顺时针绘制气泡
    [bezierPath addLineToPoint:CGPointMake(size.width-conner, trangleHeight)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width, conner + trangleHeight) controlPoint:CGPointMake(size.width, trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(size.width, size.height-conner)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width-conner, size.height) controlPoint:CGPointMake(size.width, size.height)];
    [bezierPath addLineToPoint:CGPointMake(conner, size.height)];
    [bezierPath addQuadCurveToPoint:CGPointMake(0, size.height-conner) controlPoint:CGPointMake(0, size.height)];
    [bezierPath addLineToPoint:CGPointMake(0, conner + trangleHeight)];
    [bezierPath addQuadCurveToPoint:CGPointMake(conner, trangleHeight) controlPoint:CGPointMake(0, trangleHeight)];
    
    // 气泡绘制完毕，关闭贝塞尔曲线
    [bezierPath closePath];
    return bezierPath;
}

+ (UIBezierPath *)leftBezierPathWithSize:(CGSize)size {
    CGFloat conner = 8.0; // 圆角大小
    CGFloat trangleHeight = 9.0; // 箭头高度
    CGFloat trangleWidthForHalf = 5.0; // 箭头宽度的一半

    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    
    // 从左上角开始，顺时针绘制气泡
    [bezierPath moveToPoint:CGPointMake(conner, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width-trangleHeight-conner, 0)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width-trangleHeight, conner) controlPoint:CGPointMake(size.width-trangleHeight, 0)];
    [bezierPath addLineToPoint:CGPointMake(size.width-trangleHeight, size.height/2 - trangleWidthForHalf)];
    
    // 从上向下绘制箭头
    [bezierPath addLineToPoint:CGPointMake(size.width, size.height/2)];
    [bezierPath addLineToPoint:CGPointMake(size.width - trangleHeight, size.height/2 + trangleWidthForHalf)];
    
    // 继续顺时针绘制气泡
    [bezierPath addLineToPoint:CGPointMake(size.width-trangleHeight, size.height- conner - trangleHeight)];
    [bezierPath addQuadCurveToPoint:CGPointMake(size.width - conner-trangleHeight, size.height - trangleHeight) controlPoint:CGPointMake(size.width-trangleHeight, size.height - trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(conner, size.height - trangleHeight)];
    [bezierPath addQuadCurveToPoint:CGPointMake(0, size.height - conner - trangleHeight) controlPoint:CGPointMake(0, size.height - trangleHeight)];
    [bezierPath addLineToPoint:CGPointMake(0, conner)];
    [bezierPath addQuadCurveToPoint:CGPointMake(conner, 0) controlPoint:CGPointMake(0, 0)];
    
    // 气泡绘制完毕，关闭贝塞尔曲线
    [bezierPath closePath];
    return bezierPath;
}

#pragma mark - [ Event ]

#pragma mark Action

- (void)buttonAction:(id)sender {
    UIButton *button = (UIButton *)sender;
    
    PLVSAMemberPopupButton type = button.tag - kButtonTagConst;
    switch (type) {
        case PLVSAMemberPopupButtonCamera: {
            [self.chatUser.onlineUser wantOpenUserCamera:button.selected];
            button.selected = !button.selected;
            NSString *tips = button.selected ? PLVLocalizedString(@"已关闭摄像头") : PLVLocalizedString(@"已开启摄像头");
            [PLVSAUtils showToastInHomeVCWithMessage:tips];
        } break;
        case PLVSAMemberPopupButtonMicrophone: {
            [self.chatUser.onlineUser wantOpenUserMic:button.selected];
            button.selected = !button.selected;
            NSString *tips = button.selected ? PLVLocalizedString(@"已关闭麦克风") : PLVLocalizedString(@"已开启麦克风");
            [PLVSAUtils showToastInHomeVCWithMessage:tips];
        } break;
        case PLVSAMemberPopupButtonAuthSpeaker: {
            if (self.authUserBlock) {
                self.authUserBlock(self.chatUser, !button.selected);
            }
        } break;
        case PLVSAMemberPopupButtonKick: {
            if (self.kickUserBlock) {
                self.kickUserBlock(self.chatUser.userId, self.chatUser.userName);
            }
        } break;
        case PLVSAMemberPopupButtonBanned: {
            if (self.bandUserBlock) {
                self.bandUserBlock(self.chatUser.userId, self.chatUser.userName, !self.chatUser.banned);
            }
        } break;
        default:
            break;
    }
    [self dismiss];
}

@end
