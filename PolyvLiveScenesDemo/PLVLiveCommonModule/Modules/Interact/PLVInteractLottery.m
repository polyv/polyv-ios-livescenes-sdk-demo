//
//  PLVInteractLottery.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/9/14.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVInteractLottery.h"

#import "PLVRoomDataManager.h"
#import "PLVInteractBaseApp+General.h"

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVInteractLottery ()

@property (nonatomic, copy) NSString * lotteryId; /// 本次抽奖Id
@property (nonatomic, copy) NSString * sessionId; /// 本场直播的场次Id

@property (nonatomic, copy) NSString * prize;     /// 中奖奖品
@property (nonatomic, copy) NSString * viewerId;  /// 用户userId (若本地用户(自己)是中奖者，则需记录该用户的聊天室userId)
@property (nonatomic, copy) NSString * winnerCode;/// 中奖码
@property (nonatomic, assign) BOOL winner; /// 当前本地用户(自己)，是否属于‘中奖者’

@end

@implementation PLVInteractLottery

#pragma mark - [ Father Public Methods ]
- (instancetype)initWithJsBridge:(PLVJSBridge *)jsBridge{
    if (self = [super initWithJsBridge:jsBridge]) {
        [jsBridge addJsFunctionsReceiver:self];
        [jsBridge addObserveJsFunctions:@[@"sendWinData",@"abandonLottery"]];
    }
    return self;
}

- (void)processInteractMessageString:(NSString *)msgString jsonDict:(NSDictionary *)jsonDict{
    NSString *subEvent = PLV_SafeStringForDictKey(jsonDict, @"EVENT");
    if ([subEvent isEqualToString:PLVSocketInteraction_onLottery_start]) { /// 开始抽奖
        [self startLottery: msgString];
    } else if ([subEvent isEqualToString:PLVSocketInteraction_onLottery_stop]) { /// 停止抽奖
        [self stopLottery:msgString];
    } else if ([subEvent isEqualToString:PLVSocketInteraction_onLottery]) { /// 抽奖状态
        [self startLottery: msgString];
    } else if ([subEvent isEqualToString:PLVSocketInteraction_onLottery_winner]) { /// 未领奖的中奖人信息
        [self stopLottery:msgString];
    }
}


#pragma mark - [ Private Methods ]
- (void)startLottery:(NSString *)json {
    self.winner = NO;
    NSData * jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSError * jsonError;
    NSDictionary * jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&jsonError];
    if (jsonError == nil && jsonDict != nil) {
        if ([jsonDict[@"EVENT"] isEqualToString:PLVSocketInteraction_onLottery_start]) {
            self.lotteryId = jsonDict[@"lotteryId"];
            self.sessionId = jsonDict[@"sessionId"];
        } else {
            self.lotteryId = jsonDict[@"data"];
        }
        [self.jsBridge call:@"startLottery" params:nil];
        [self callWebviewShow];
    }else{
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeInteract, @"PLVInteractLottery - startLottery failed, error:%@ jsonDict:%@",jsonError,jsonDict);
    }
}

- (void)stopLottery:(NSString *)json {
    self.winner = NO;
    NSData *jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSError *jsonError = nil;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&jsonError];
    if (jsonError == nil && jsonDict != nil) {
        if ([jsonDict[@"EVENT"] isEqualToString:PLVSocketInteraction_onLottery_stop]) {
            NSArray * dataArray = jsonDict[@"data"];
            NSDictionary * me = dataArray.firstObject;
            if (!me) {
                [self.jsBridge call:@"stopLottery" params:@[json]];
            } else {
                self.winner = YES;
                self.viewerId = me[@"userId"];
                self.winnerCode = me[@"winnerCode"];
                self.prize = jsonDict[@"prize"];
                [self.jsBridge call:@"stopLottery" params:@[json]];
            }
            [self callWebviewShow];
        }else{
            PLV_LOG_ERROR(PLVConsoleLogModuleTypeInteract, @"PLVInteractLottery - stopLottery failed, EVENT illegal, jsonDict:%@",jsonDict);
        }
    }else{
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeInteract, @"PLVInteractLottery - stopLottery failed, error:%@ jsonDict:%@",jsonError,jsonDict);
    }
    
    if (self.winner) {
        [self callRequirePortraitScreen];
    }
}

- (NSString *)generateLotteryCollectString:(NSArray *)array {
    if (![PLVFdUtil checkArrayUseable:array]) {
        return @"";
    }
    NSString * receiveInfo = @"";
    NSError * error;
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:&error];
    if (jsonData && error == nil) {
        receiveInfo = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }else{
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeInteract, @"PLVInteractLottery - generateLotteryCollectString failed, error:%@ jsonData:%@",error,jsonData);
    }
    return receiveInfo;
}


#pragma mark - [ Delegate ]
#pragma mark JS Callback
// 接收到js中奖信息
- (void)sendWinData:(NSDictionary *)dict {
    if (![PLVFdUtil checkDictionaryUseable:dict]) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeInteract, @"PLVInteractLottery - [js call] sendWinData param illegal %@",dict);
        return;
    }
        
    NSMutableDictionary * muDict = [[NSMutableDictionary alloc] init];
    muDict[@"lotteryId"] = [NSString stringWithFormat:@"%@",self.lotteryId];
    muDict[@"viewerId"] = [NSString stringWithFormat:@"%@",self.viewerId];
    muDict[@"winnerCode"] = [NSString stringWithFormat:@"%@",self.winnerCode];
    muDict[@"sessionId"] = [NSString stringWithFormat:@"%@",self.sessionId];
    muDict[@"receiveInfo"] = [self generateLotteryCollectString:dict[@"receiveInfo"]];
    
    NSMutableDictionary * jsonDict = [[NSMutableDictionary alloc] init];
    [jsonDict addEntriesFromDictionary:@{@"channelId" : [NSString stringWithFormat:@"%@", [PLVSocketManager sharedManager].roomId]}];
    [jsonDict addEntriesFromDictionary:[muDict copy]];
    
    __weak typeof(self) weakSelf = self;
    [PLVLiveVideoAPI newPostLotteryWithData:jsonDict completion:^{
        [weakSelf triviaCardAckHandleNoRetry:@[@"{\"code\":200}"] event:@"LOTTERY"];
    } failure:^(NSError *error) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeInteract, @"PLVInteractLottery - newPostLotteryWithData failed, error:%@", error.description);
        [weakSelf triviaCardAckHandleNoRetry:@[@"{\"code\":400}"] event:@"LOTTERY"];
    }];
}

// 接收到js放弃中奖消息
- (void)abandonLottery:(id)placeholder {
    [PLVLiveVideoAPI giveUpReceiveWithChannelId:[PLVRoomDataManager sharedManager].roomData.channelId userId:self.viewerId completion:^(NSString *str) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeInteract, @"PLVInteractLottery - abandonLottery success, str:%@", str);
    } failure:^(NSError *error) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeInteract, @"PLVInteractLottery - abandonLottery failed, error:%@", error.description);
    }];
}

@end
