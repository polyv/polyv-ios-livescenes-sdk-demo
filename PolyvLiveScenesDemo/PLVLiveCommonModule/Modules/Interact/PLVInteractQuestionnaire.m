//
//  PLVInteractQuestionnaire.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/9/14.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVInteractQuestionnaire.h"

#import "PLVInteractBaseApp+General.h"

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVInteractQuestionnaire ()

@property (nonatomic, copy) NSString * questionnaireJson; /// 问卷内容

@end

@implementation PLVInteractQuestionnaire

#pragma mark - [ Father Public Methods ]
- (instancetype)initWithJsBridge:(PLVJSBridge *)jsBridge{
    if (self = [super initWithJsBridge:jsBridge]) {
        [jsBridge addJsFunctionsReceiver:self];
        [jsBridge addObserveJsFunctions:@[@"endQuestionnaireAnswer"]];
    }
    return self;
}

- (void)processInteractMessageString:(NSString *)msgString jsonDict:(NSDictionary *)jsonDict{
    NSString *subEvent = PLV_SafeStringForDictKey(jsonDict, @"EVENT");
    if ([subEvent isEqualToString:PLVSocketInteraction_onQuestionnaire_start]) { /// 打开问卷
        [self openQuestionnaire:msgString];
    } else if ([subEvent isEqualToString:PLVSocketInteraction_onQuestionnaire_stop]) { /// 关闭问卷
        [self stopQuestionnaire:msgString];
    } else if ([subEvent isEqualToString:PLVSocketInteraction_onQuestionnaire_sendResult]) { /// 收到问卷结果
        [self sendQuestionnaireResult:msgString];
    } else if ([subEvent isEqualToString:PLVSocketInteraction_onQuestionnaire_achievement]) { /// 收到问卷统计相关数据事件
        [self questionnaireAchievement:msgString];
    }
}


#pragma mark - [ Private Methods ]
- (void)openQuestionnaire:(NSString *)json {
    if (self.questionnaireJson == nil || ![self.questionnaireJson isEqualToString:json]) {
        [self callRequirePortraitScreen];
        self.questionnaireJson = json;
        [self.jsBridge call:@"startQuestionNaire" params:@[json]];
        [self callWebviewShow];
    }
}

- (void)stopQuestionnaire:(NSString *)json {
    [self.jsBridge call:@"stopQuestionNaire" params:@[json]];
}

- (void)sendQuestionnaireResult:(NSString *)json {
    [self.jsBridge call:@"sendQuestionNaireResult" params:@[json]];
}

- (void)questionnaireAchievement:(NSString *)json {
    [self callRequirePortraitScreen];
    [self.jsBridge call:@"questionNaireAchievement" params:@[json]];
    [self callWebviewShow];
}


#pragma mark - [ Delegate ]
#pragma mark JS Callback
// 向app发送问卷结果
- (void)endQuestionnaireAnswer:(NSDictionary *)dict {
    if (![PLVFdUtil checkDictionaryUseable:dict]) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeInteract, @"[js call] endQuestionnaireAnswer param illegal %@",dict);
        return;
    }
        
    NSString * questionId = [NSString stringWithFormat:@"%@", dict[@"id"]];
    NSArray * answers = (NSArray *)dict[@"answers"];
    answers = [PLVFdUtil checkArrayUseable:answers] ? answers : @[];
    dict = @{@"answer" : answers, @"questionnaireId" : questionId};
    
    NSString * event = @"ANSWER_QUESTIONNAIRE";
    
    NSDictionary *baseJSON = @{@"EVENT" : event,
                               @"nick" : [NSString stringWithFormat:@"%@",[PLVSocketManager sharedManager].viewerName],
                               @"userId" : [NSString stringWithFormat:@"%@",[PLVSocketManager sharedManager].viewerId],
                               @"roomId" : [NSString stringWithFormat:@"%@", [PLVSocketManager sharedManager].roomId]};
    
    NSMutableDictionary *jsonDict = [[NSMutableDictionary alloc] init];
    [jsonDict addEntriesFromDictionary:baseJSON];
    [jsonDict addEntriesFromDictionary:dict];
    
    [self emitInteractMsg:jsonDict event:event];
}

@end
