//
//  PLVInteractView.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2020/9/10.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVInteractView.h"

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFdUtil.h>

#import "PLVInteractAnswer.h"
#import "PLVInteractSignIn.h"
#import "PLVInteractLottery.h"
#import "PLVInteractBulletin.h"
#import "PLVInteractQuestionnaire.h"

@interface PLVInteractView () <PLVInteractWebviewDelegate, PLVInteractBaseAppDelegate, PLVJSBridgeDelegate>

@property (nonatomic, assign) BOOL forbidRotateNow; // 此时是否不允许转屏

@property (nonatomic, strong) PLVInteractWebview * interactWebview;

@property (nonatomic, strong) NSMutableDictionary * interactDict;

@property (nonatomic, strong, readonly) PLVJSBridge * jsBridge;
@property (nonatomic, strong, readonly) WKWebView * webview;

@property (nonatomic, strong) UIButton * closeBtn;

@end

@implementation PLVInteractView

#pragma mark - [ Life Period ]
- (void)dealloc{
    PLV_LOG_INFO(PLVConsoleLogModuleTypeInteract, @"%s",__FUNCTION__);
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupData];
        [self setupUI];
        [self setupInteractApps];
    }
    return self;
}


#pragma mark - [ Public Methods ]
- (void)loadOnlineInteract{
    [self.jsBridge loadWebView:PLVLiveConstantsInteractTriviaCardURL inView:self];
    [self layoutSelfView];
}

- (void)loadLocalInteractWithHTMLString:(NSString *)htmlString baseURL:(NSURL *)baseURL{
    [self.jsBridge loadHTMLString:htmlString baseURL:baseURL inView:self];
    [self layoutSelfView];
}

- (void)openLastBulletin{
    PLVInteractBulletin * bulletinApp = [self.interactDict objectForKey:PLVSocketIOChatRoom_BULLETIN_EVENT];
    if ([bulletinApp isKindOfClass:PLVInteractBulletin.class]) {
        [bulletinApp openLastBulletin];
    }
}


#pragma mark - [ Private Methods ]
- (void)setupData{
    self.keepInteractViewTop = YES;
}

- (void)setupUI{
    self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3];
    self.hidden = YES;
    
    self.interactWebview = [[PLVInteractWebview alloc]init];
    self.interactWebview.delegate = self;

    self.jsBridge.delegate = self;
    //self.jsBridge.debugMode = YES;
    
    [self.webview addSubview:self.closeBtn];
}

- (void)setupInteractApps{
    [self.jsBridge addJsFunctionsReceiver:self];
    [self.jsBridge addObserveJsFunctions:@[@"initWebview", @"closeWebview", @"linkClick"]];
    
    [self addInteractApp:[PLVInteractSignIn class] eventString:PLVSocketInteraction_onSignIn_about];/// 签到
    [self addInteractApp:[PLVInteractBulletin class] eventString:PLVSocketIOChatRoom_BULLETIN_EVENT];/// 公告
    [self addInteractApp:[PLVInteractLottery class] eventString:PLVSocketInteraction_onLottery_about];/// 抽奖
    [self addInteractApp:[PLVInteractAnswer class] eventString:PLVSocketInteraction_onTriviaCard_about];/// 答题卡
    [self addInteractApp:[PLVInteractQuestionnaire class] eventString:PLVSocketInteraction_onQuestionnaire_about];/// 问卷
}

- (void)addInteractApp:(Class)interactClass eventString:(NSString *)eventString{
    PLVInteractBaseApp * app = [[interactClass alloc] initWithJsBridge:self.jsBridge];
    app.delegate = self;
    [self.interactDict setObject:app forKey:eventString];
}

- (void)layoutSelfView {
    [self layoutWebviewFrame];
    
    float topPadding = [PLVFdUtil isiPhoneXSeries] ? 30.0 : 10.0;
    CGFloat originX = self.webview.frame.size.width - 11.0 - 28.0;
    CGFloat originY = 11.0 + topPadding;
    self.closeBtn.frame = CGRectMake(originX, originY, 28.0, 28.0);
}

- (void)layoutWebviewFrame{
    if (self.jsBridge.webviewLoadFinish) {
        self.webview.frame = self.bounds;
        self.webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    } else if(!self.jsBridge.webviewLoadFaid){
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf layoutWebviewFrame];
        });
    }
}

- (void)hiddenSelfView{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.hidden = YES;
    });
}

#pragma mark Setter
- (void)setForbidRotateNow:(BOOL)forbidRotateNow{
    if ([PLVLiveVideoConfig sharedInstance].triviaCardUnableRotate == NO) { // 若原本是‘允许转屏’
        if (forbidRotateNow == YES) {
            // 收到需要 ‘禁止转屏’ 时，将检查当前设备方向，若不是竖屏，则强制转为竖屏
            if ([UIDevice currentDevice].orientation != UIDeviceOrientationPortrait){
                [PLVFdUtil changeDeviceOrientationToPortrait];
            }
        }
        
        // 更新 triviaCardUnableRotate 值
        [PLVLiveVideoConfig sharedInstance].triviaCardUnableRotate = forbidRotateNow;
    }
    // 注: 若原本是‘不可转屏’，则直到 [closeWebview] 被调用，都将保持不可转屏，避免部分交互页面不支持转屏
}

#pragma mark Getter
- (PLVJSBridge *)jsBridge{
    return self.interactWebview.jsBridge;
}

- (WKWebView *)webview{
    return self.interactWebview.webview;
}

- (UIButton *)closeBtn{
    if (!_closeBtn) {
        _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeBtn addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

- (NSMutableDictionary *)interactDict{
    if (!_interactDict) {
        _interactDict = [[NSMutableDictionary alloc] init];
    }
    return _interactDict;
}


#pragma mark - [ Event ]
#pragma mark Action
- (void)closeButtonAction:(UIButton *)button{
    [self closeWebview:nil];
}


#pragma mark - [ Delegate ]
#pragma mark PLVInteractWebviewDelegate
- (void)plvInteractWebview:(PLVInteractWebview *)interactWebview
didReceiveInteractMessageString:(NSString *)msgString
                  jsonDict:(NSDictionary *)jsonDict{
    NSString * subEvent = PLV_SafeStringForDictKey(jsonDict, @"EVENT");
    
    PLVInteractBaseApp * interactApp ;
    NSString * key;
    if ([subEvent containsString:PLVSocketIOChatRoom_BULLETIN_EVENT]){ /// 公告
        key = PLVSocketIOChatRoom_BULLETIN_EVENT;
    } else if ([subEvent containsString:PLVSocketInteraction_onLottery_about] ||
               [subEvent isEqualToString:PLVSocketInteraction_onLottery]) { /// 抽奖
        key = PLVSocketInteraction_onLottery_about;
    } else if ([subEvent containsString:PLVSocketInteraction_onSignIn_about]) { /// 签到
        key = PLVSocketInteraction_onSignIn_about;
    } else if ([subEvent containsString:PLVSocketInteraction_onTriviaCard_about]) { /// 答题卡
        key = PLVSocketInteraction_onTriviaCard_about;
    } else if ([subEvent containsString:PLVSocketInteraction_onQuestionnaire_about]) { /// 问卷
        key = PLVSocketInteraction_onQuestionnaire_about;
    }
    if ([PLVFdUtil checkStringUseable:key]) { interactApp = [self.interactDict objectForKey:key]; }
    [interactApp processInteractMessageString:msgString jsonDict:jsonDict];
}

#pragma mark PLVInteractBaseAppDelegate
- (void)plvInteractAppRequirePortraitScreen:(PLVInteractBaseApp *)interactApp{
    self.forbidRotateNow = YES;
}

- (void)plvInteractApp:(PLVInteractBaseApp *)interactApp webviewShow:(BOOL)show{
    if (show) {
        self.hidden = NO; /// 出现互动视图
        if (self.keepInteractViewTop) { [self.superview bringSubviewToFront:self]; } /// 移至最顶层
    }
}

#pragma mark PLVJSBridgeDelegate
- (void)plvJSBridge:(PLVJSBridge *)jsBridge showConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    UIViewController * vc = [PLVFdUtil getCurrentViewController];
    if ([vc isKindOfClass:UIViewController.class]) {
        [PLVFdUtil showAlertWithTitle:nil message:message viewController:vc cancelActionTitle:@"取消" cancelActionStyle:UIAlertActionStyleCancel cancelActionBlock:^(UIAlertAction * _Nonnull action) {
            completionHandler(NO);
        } confirmActionTitle:@"好" confirmActionStyle:UIAlertActionStyleDefault confirmActionBlock:^(UIAlertAction * _Nonnull action) {
            completionHandler(YES);
        }];
    }
}

#pragma mark JS Callback
// 接收到js加载完成消息，可隐藏关闭按钮
- (void)initWebview:(id)placeholder {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.closeBtn.hidden = YES;
    });
}

// 接收到js关闭webview请求
- (void)closeWebview:(id)placeholder {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.forbidRotateNow = NO;
        [PLVLiveVideoConfig sharedInstance].triviaCardUnableRotate = NO;
        [self hiddenSelfView];
    });
}

// 接收到js打开链接请求
- (void)linkClick:(NSString *)linkString {
    if (![PLVFdUtil checkStringUseable:linkString]) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypeInteract, @"PLVInteractView - [js call] linkClick param illegal %@",linkString);
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:linkString]];
    });
}

@end
