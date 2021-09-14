//
//  PLVInteractAnswer.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/9/10.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVInteractAnswer.h"

#import "PLVInteractBaseApp+General.h"

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVInteractAnswer ()

@property (nonatomic, copy) NSString * quesitonId; /// 问题Id (哪个题目；能判断用户是否回答了题目)
@property (nonatomic, copy) NSString * answerId;   /// 回答Id (用户选择哪个选项)

@end

@implementation PLVInteractAnswer

#pragma mark - [ Father Public Methods ]
- (instancetype)initWithJsBridge:(PLVJSBridge *)jsBridge{
    if (self = [super initWithJsBridge:jsBridge]) {
        [jsBridge addJsFunctionsReceiver:self];
        [jsBridge addObserveJsFunctions:@[@"chooseAnswer"]];
    }
    return self;
}

- (void)processInteractMessageString:(NSString *)msgString jsonDict:(NSDictionary *)jsonDict{
    NSString *subEvent = PLV_SafeStringForDictKey(jsonDict, @"EVENT");
    if ([subEvent isEqualToString:PLVSocketInteraction_onTriviaCard_questionContent]) { /// 打开答题卡
        [self openAnswerSheet:msgString];
    } else if ([subEvent isEqualToString:PLVSocketIOClass_onTriviaCard_stop]) { /// 关闭答题卡
        [self closeAnswerSheet:msgString];
    } else if ([subEvent isEqualToString:PLVSocketInteraction_onTriviaCard_questionResult]) { /// 展示答题卡答案
        [self showAnswerSheetResult:msgString];
    }
}


#pragma mark - [ Private Methods ]
- (void)openAnswerSheet:(NSString *)msgString{
    [self callRequirePortraitScreen];
    self.quesitonId = nil;
    self.answerId = nil;
    [self.jsBridge call:@"updateNewQuestion" params:@[msgString]];
    [self callWebviewShow];
}

- (void)closeAnswerSheet:(NSString *)msgString{
    /// 是否未答题
    /// YES: 无值，未回答题目 (webview需显示‘答题已结束’)
    /// NO: 有值，回答了题目
    BOOL notAnswer = ![PLVFdUtil checkStringUseable:self.quesitonId];
    if (notAnswer) {
        [self.jsBridge call:@"testQuestion" params:@[msgString]];
        [self callWebviewShow];
    }
}

- (void)showAnswerSheetResult:(NSString *)msgString{
    [self callRequirePortraitScreen];
    msgString = [NSString stringWithFormat:@"{\"answerId\":\"%@\",\"data\":%@}", (self.answerId?self.answerId:@""), msgString];
    [self.jsBridge call:@"hasChooseAnswer" params:@[msgString]];
    [self callWebviewShow];
}


#pragma mark - [ Delegate ]
#pragma mark JS Callback
// 接收到js答题卡结果
- (void)chooseAnswer:(NSDictionary *)dict {
    if (![PLVFdUtil checkDictionaryUseable:dict]) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeInteract, @"PLVInteractAnswer - [js call] chooseAnswer param illegal %@",dict);
        return;
    }
        
    self.answerId = [NSString stringWithFormat:@"%@", dict[@"answerId"]];
    self.quesitonId = [NSString stringWithFormat:@"%@", dict[@"questionId"]];
    dict = @{@"option" : self.answerId, @"questionId" : self.quesitonId};
    
    NSString * event = @"ANSWER_TEST_QUESTION";
    
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
