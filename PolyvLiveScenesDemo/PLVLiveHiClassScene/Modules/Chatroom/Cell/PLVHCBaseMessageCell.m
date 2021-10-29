//
//  PLVHCBaseMessageCell.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/25.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCBaseMessageCell.h"

// 工具类
#import "PLVHCUtils.h"

// UI
#import "PLVHCChatroomMenuPopup.h"

// 模块
#import "PLVRoomDataManager.h"

// model
#import "PLVChatModel.h"

@interface PLVHCBaseMessageCell()

@property (nonatomic, strong) PLVHCChatroomMenuPopup *menuPopup; // 复制、回复菜单弹层

@end

@implementation PLVHCBaseMessageCell

#pragma mark - [ Life Cycle ]

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

#pragma mark - [ Public Method ]

#pragma mark 判断model是否为有效类型

/// 判断model是否为有效类型，子类需覆写，默认返回NO
/// @param model 数据模型
+ (BOOL)isModelValid:(PLVChatModel *)model{
    return NO;
}

#pragma mark reuseIdentifier
/// 根据身份类型返回不同ID，由子类覆盖实现处理业务。
+ (NSString *)reuseIdentifierWithUser:(PLVChatUser *)user {
    return nil;
}

#pragma mark 设置身份标签

+ (NSString *)actorBgColorHexStringWithUserType:(PLVRoomUserType)userType {
    NSString *colorHexString = nil;
    switch (userType) {
        case PLVRoomUserTypeGuest:
            colorHexString = @"#EB6165";
            break;
        case PLVRoomUserTypeTeacher:
            colorHexString = @"#F09343";
            break;
        case PLVRoomUserTypeAssistant:
            colorHexString = @"#598FE5";
            break;
        case PLVRoomUserTypeManager:
            colorHexString = @"#33BBC5";
            break;
        default:
            break;
    }
    return colorHexString;
}

+ (BOOL)showActorLabelWithUser:(PLVChatUser *)user {
    return (user.userType == PLVRoomUserTypeGuest ||
            user.userType == PLVRoomUserTypeTeacher ||
            user.userType == PLVRoomUserTypeAssistant ||
            user.userType == PLVRoomUserTypeManager);
}

+ (UIImage*) actorImageWithUser:(PLVChatUser *)user; {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:10];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.layer.cornerRadius = 7;
    label.layer.masksToBounds = YES;
    label.text = user.actor;
    
    NSString *backgroundColor = [self actorBgColorHexStringWithUserType:user.userType];
    if (backgroundColor) {
        label.backgroundColor = [PLVColorUtil colorFromHexString:backgroundColor];
    }
    NSString *actor = user.actor;
    CGSize size;
    if (actor &&
        [actor isKindOfClass:[NSString class]] &&
        actor.length >0) {
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:actor attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:10]}];
        size = [attr boundingRectWithSize:CGSizeMake(100, 14) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil].size;
        size.width += 10;
    }
    label.frame = CGRectMake(0, 0, size.width, 14);
    UIGraphicsBeginImageContextWithOptions(label.frame.size, NO, [UIScreen mainScreen].scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [label.layer renderInContext:ctx];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
   
    return image;
}

#pragma mark Utils

+ (BOOL)isLoginUser:(NSString *)userId {
    if (!userId || ![userId isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    BOOL isLoginUser = [userId isEqualToString:[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId];
    return isLoginUser;
}

- (void)showMenuPopup {
    if (!self.allowCopy &&
        !self.allowReply) {
        return;
    }
    
    // 违禁消息、不是讲师身份关闭回复功能
    if (self.model.isProhibitMsg ||
        [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType != PLVRoomUserTypeTeacher) {
        self.allowReply = NO;
    }
    
    if (!self.menuSuperView) {
        NSLog(@"menuSuperView is nil");
        return;
    }
    
    if (_menuPopup) {
        [self.menuPopup dismiss];
        _menuPopup = nil;
    }
    
    [self.menuPopup showInView:[PLVHCUtils sharedUtils].homeVC.view];
}

#pragma mark - [ Private Method ]

#pragma mark Getter
- (PLVHCChatroomMenuPopup *)menuPopup {
    if (!_menuPopup) {
        //在self.menuSuperView顶部并居中
        CGFloat menuHeight = 38;
        CGFloat centerX = self.menuSuperView.center.x;
        CGFloat originY = self.menuSuperView.frame.origin.y - menuHeight;
        CGFloat menuWidth = self.allowReply ? 59: 0;
        menuWidth += self.allowCopy ? 59: 0;
        CGRect rect = CGRectMake(centerX - menuWidth / 2.0, originY, menuWidth, menuHeight);
        // 将rect坐标从self.menuSuperView.superview的坐标 转成[PLVHCUtils sharedUtils].homeVC.view的坐标
        rect = [self.menuSuperView.superview convertRect:rect toView:[PLVHCUtils sharedUtils].homeVC.view];
        
        CGRect buttonRect = [self convertRect:rect toView:self.superview];
        _menuPopup = [[PLVHCChatroomMenuPopup alloc] initWithMenuFrame:rect buttonFrame:buttonRect];
        _menuPopup.allowReply = self.allowReply;
        _menuPopup.allowCopy = self.allowCopy;
        
        __weak typeof(self) weakSelf = self;
        _menuPopup.dismissHandler = ^{
            weakSelf.menuPopup = nil;
        };
        
        _menuPopup.copyButtonHandler = ^{
            [weakSelf copyAction];
        };
        
        _menuPopup.replyButtonHandler = ^{
            [weakSelf replyAction];
        };
    }
    return _menuPopup;
}

#pragma mark Setter

- (void)setMenuSuperView:(UIView *)menuSuperView {
    _menuSuperView = menuSuperView;
    if (menuSuperView) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
        [menuSuperView addGestureRecognizer:longPress];
    }
}

#pragma mark - Event
#pragma mark Action

- (void)copyAction {
}

- (void)replyAction {
    if (self.replyHandler) {
        self.replyHandler(self.model);
    }
}

#pragma mark Gesture

- (void)longPressAction:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self showMenuPopup];
    }
}

@end
