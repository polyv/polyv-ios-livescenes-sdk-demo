//
//  PLVShareLivePosterModel.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2022/9/6.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVShareLivePosterModel.h"
#import "PLVRoomDataManager.h"

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVShareLivePosterModel ()

@property (nonatomic, copy) NSString *posterURLString;

@end

@implementation PLVShareLivePosterModel

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        self.invitePosterTheme = PLV_SafeIntegerForDictKey(dictionary, @"invitePosterTheme");
        self.avatar = PLV_SafeStringForDictKey(dictionary, @"avatar");
        self.nickname = PLV_SafeStringForDictKey(dictionary, @"nickname");
        self.name = PLV_SafeStringForDictKey(dictionary, @"name");
        self.inviteCoverImage = PLV_SafeStringForDictKey(dictionary, @"inviteCoverImage");
        self.publisher = PLV_SafeStringForDictKey(dictionary, @"publisher");
        self.watchDomain = PLV_SafeStringForDictKey(dictionary, @"watchDomain");
        self.channelId = PLV_SafeStringForDictKey(dictionary, @"channelId");
        self.watchUrl = PLV_SafeStringForDictKey(dictionary, @"watchUrl");
        self.customUserType = PLV_SafeStringForDictKey(dictionary, @"customUserType");
        NSString *startTime = PLV_SafeStringForDictKey(dictionary, @"startTime");
        self.startTime = [self startTimeWithTimeStamp:startTime];
        NSDictionary *footerSetting = PLV_SafeDictionaryForDictKey(dictionary, @"footerSetting");
        if ([PLVFdUtil checkDictionaryUseable:footerSetting]) {
            self.footerText = PLV_SafeStringForDictKey(footerSetting, @"footerText");
        }
        
        PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
        self.avatar = roomUser.viewerAvatar;
        self.nickname = roomUser.viewerName;
    }
    return self;
}

- (NSString *)posterURLString {
    if (!_posterURLString) {
        NSInteger invitePosterTheme = (self.invitePosterTheme < 0) ? 3 : self.invitePosterTheme; //目前不支持自定义海报 -1
        _posterURLString = [NSString stringWithFormat:@"%@?type=%ld&avatar=%@&nickname=%@&name=%@&inviteCoverImage=%@&publisher=%@&startTime=%@&watchDomain=%@&channelId=%@&watchUrl=%@&customUserType=%@&footerText=%@",
                            PLVLiveConstantsPosterShareHTML,
                            invitePosterTheme,
                            [self encodingWithString:self.avatar],
                            [self encodingWithString:self.nickname],
                            [self encodingWithString:self.name],
                            [self encodingWithString:self.inviteCoverImage],
                            [self encodingWithString:self.publisher],
                            [self encodingWithString:self.startTime],
                            [self encodingWithString:self.watchDomain],
                            self.channelId,
                            [self encodingWithString:self.watchUrl],
                            [self encodingWithString:self.customUserType],
                            [self encodingWithString:self.footerText]];
    }
    return _posterURLString;
}

- (NSString *)startTimeWithTimeStamp:(NSString *)timeStamp {
    if (![PLVFdUtil checkStringUseable:timeStamp] || PLV_SafeIntegerForValue(timeStamp) == 0) {
        return @"";
    }
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[timeStamp longLongValue]/1000];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateStr = [formatter stringFromDate:date];
    return dateStr;
}

- (NSString *)encodingWithString:(NSString *)string {
    if (![PLVFdUtil checkStringUseable:string]) {
        return @"";
    }
    
    NSMutableCharacterSet *charset = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [charset removeCharactersInString:@"!*'();:@&=+$,/?%#[]"]; // 移除一些需要编码的字符
    NSString *encodedString = [string stringByAddingPercentEncodingWithAllowedCharacters:charset];
    return encodedString;
}

@end
