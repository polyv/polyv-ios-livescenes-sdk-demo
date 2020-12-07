//
//  PLVLiveUser.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/7/13.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLiveUser.h"

NSString *const kPLVLiveUserTypeStudent = @"student";
NSString *const kPLVLiveUserTypeSlice = @"slice";
NSString *const kPLVLiveUserTypeViewer = @"viewer";

NSString *const kPLVLiveUserTypeGuest =  @"guest";
NSString *const kPLVLiveUserTypeTeacher = @"teacher";
NSString *const kPLVLiveUserTypeAssistant = @"assistant";
NSString *const kPLVLiveUserTypeManager = @"manager";

NSString *const kPLVLiveUserTypeDummy = @"dummy";

BOOL IsSpecialIdentityOfLiveUserType(PLVLiveUserType userType) {
    switch (userType) {
        case PLVLiveUserTypeGuest:
        case PLVLiveUserTypeTeacher:
        case PLVLiveUserTypeAssistant:
        case PLVLiveUserTypeManager:
            return YES;
        default:
            return NO;
    }
}

PLVLiveUserType PLVLiveUserTypeWithString(NSString *userType) {
    if (![userType isKindOfClass:NSString.class]) {
        return PLVLiveUserTypeUnknown;
    }
    
    if ([userType isEqualToString:@""]
        || [userType isEqualToString:kPLVLiveUserTypeStudent]) {
        return PLVLiveUserTypeStudent;
    }else if ([userType isEqualToString:kPLVLiveUserTypeSlice]) {
        return PLVLiveUserTypeSlice;
    }else if ([userType isEqualToString:kPLVLiveUserTypeViewer]) {
        return PLVLiveUserTypeViewer;
    }else if ([userType isEqualToString:kPLVLiveUserTypeGuest]) {
        return PLVLiveUserTypeGuest;
    }else if ([userType isEqualToString:kPLVLiveUserTypeTeacher]) {
            return PLVLiveUserTypeTeacher;
    }else if ([userType isEqualToString:kPLVLiveUserTypeAssistant]) {
        return PLVLiveUserTypeAssistant;
    }else if ([userType isEqualToString:kPLVLiveUserTypeManager]) {
        return PLVLiveUserTypeManager;
    }else if ([userType isEqualToString:kPLVLiveUserTypeDummy]) {
        return PLVLiveUserTypeDummy;
    }else {
        return PLVLiveUserTypeUnknown;
    }
}

NSString *PLVSStringWithLiveUserType(PLVLiveUserType userType, BOOL english) {
    switch (userType) {
        case PLVLiveUserTypeStudent:
            return english ? kPLVLiveUserTypeStudent : @"普通观众";
        case PLVLiveUserTypeSlice:
            return english ? kPLVLiveUserTypeSlice : @"云课堂学员";
        case PLVLiveUserTypeViewer:
            return english ? kPLVLiveUserTypeViewer : @"客户端的参与者";
        case PLVLiveUserTypeGuest:
            return english ? kPLVLiveUserTypeGuest : @"嘉宾";
        case PLVLiveUserTypeTeacher:
            return english ? kPLVLiveUserTypeTeacher : @"讲师";
        case PLVLiveUserTypeAssistant:
            return english ? kPLVLiveUserTypeAssistant : @"助教";
        case PLVLiveUserTypeManager:
            return english ? kPLVLiveUserTypeManager : @"管理员";
        default:
            return @"";
    }
}

@implementation PLVLiveUser

@end
