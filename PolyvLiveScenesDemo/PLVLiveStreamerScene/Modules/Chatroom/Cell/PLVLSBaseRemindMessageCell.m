//
//  PLVLSRemindBaseMessageCell.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/2/14.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSRemindBaseMessageCell.h"

// 模块
#import "PLVRoomDataManager.h"
#import "PLVChatModel.h"

@implementation PLVLSRemindBaseMessageCell

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
            colorHexString = @"#4399FF";
            break;
        case PLVRoomUserTypeTeacher:
            colorHexString = @"#FFC161";
            break;
        case PLVRoomUserTypeAssistant:
            colorHexString = @"#33BBC5";
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
    label.layer.cornerRadius = 2;
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

@end
