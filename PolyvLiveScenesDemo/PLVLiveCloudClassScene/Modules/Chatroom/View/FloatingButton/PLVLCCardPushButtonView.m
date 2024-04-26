//
//  PLVLCCardPushButtonView.m
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2022/7/6.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCCardPushButtonView.h"
#import "PLVLCUtils.h"
#import "PLVMultiLanguageManager.h"
#import "PLVLCCardPushPopupView.h"
#import <SDWebImage/UIButton+WebCache.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

@interface PLVLCCardPushButtonView ()

/// UI
@property (nonatomic, strong) UIButton *cardPushButton;
@property (nonatomic, strong) UILabel *countdownLabel; // 倒计时文本
@property (nonatomic, strong) PLVLCCardPushPopupView *popupView;

/// 数据
@property (nonatomic, copy) NSString *channelId;
@property (nonatomic, copy) NSString *cardId;
@property (nonatomic, copy, readonly) NSString *localWatchTimeKey; //本地保存观看时长的 key
@property (nonatomic, strong) dispatch_source_t countdownTimer; // 观看时长计时器
@property (nonatomic, strong) NSDictionary *cardDict; // 卡片推送的socket消息
@property (nonatomic, assign) NSInteger conditionTime; // 达到奖励的时间限制
@property (nonatomic, assign) NSInteger watchTime; // 已经观看直播的时间（包含本地已经保存的时长）
@property (nonatomic, assign) BOOL enterEnabled; // 是否隐藏卡片入口
@property (nonatomic, assign) BOOL canOpenCard; // 是否能开启卡片弹窗

@end

@implementation PLVLCCardPushButtonView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hidden = YES;
        
        [self addSubview:self.cardPushButton];
        [self addSubview:self.countdownLabel];
        [self addSubview:self.popupView];
    }
    return self;
}

- (void)layoutSubviews {
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    CGSize popupViewSize = [self.popupView.titleLabel sizeThatFits:CGSizeMake(MAXFLOAT, 16)];
    CGFloat popupViewWidth = popupViewSize.width + 16 + (fullScreen ? 0 : 10);
    CGFloat popupViewHeight = 34;
    if (!fullScreen) { // 竖屏
        self.cardPushButton.frame = CGRectMake(0, self.countdownLabel.isHidden ? 12 : 0, PLVLCCardPushButtonViewWidth, PLVLCCardPushButtonViewWidth);
        self.popupView.frame = CGRectMake(- popupViewWidth - 7, CGRectGetMinY(self.cardPushButton.frame), popupViewWidth, popupViewHeight);
    }else{ // 横屏
        CGFloat viewWidth = CGRectGetWidth(self.bounds);
        self.cardPushButton.frame = CGRectMake(0, 0, viewWidth, viewWidth);
        self.popupView.frame = CGRectMake((CGRectGetWidth(self.frame) - popupViewWidth)/2, - popupViewHeight - 3, popupViewWidth, popupViewHeight);
    }
    [self.popupView setPopupViewDirection:fullScreen ? PLVLCCardPushPopupDirectionTop : PLVLCCardPushPopupDirectionLeft];
    self.countdownLabel.frame = CGRectMake(-3, CGRectGetMaxY(self.cardPushButton.frame) + 2, PLVLCCardPushButtonViewWidth + 6, 12);
}

#pragma mark - [ Public Method ]

- (void)startCardPush:(BOOL)start cardPushInfo:(NSDictionary *)dict callback:(void (^)(BOOL show))callback {
    if (start) {
        if (![PLVFdUtil checkDictionaryUseable:dict]) {
            return;
        }
        
        self.cardDict = dict;
        self.channelId = PLV_SafeStringForDictKey(dict, @"roomId");
        self.cardId = PLV_SafeStringForDictKey(dict, @"id");
        __weak typeof(self) weakSelf = self;
        [self loadCardPushWithRoomId:self.channelId cardId:self.cardId completion:^(NSDictionary *cardDict) {
            if ([PLVFdUtil checkDictionaryUseable:cardDict]) {
                [weakSelf setCardPushButtonViewWithCardInfo:cardDict callback:callback];
            } else {
                callback ? callback(!weakSelf.hidden) : nil;
            }
        }];
    } else {
        self.hidden = YES;
        callback ? callback(!self.hidden) : nil;
        [self saveLocalWatchTime];
        [self cancelDispatchTimer];
    }
}

- (void)hidePopupView {
    self.popupView.hidden = YES;
}

- (void)leaveLiveRoom {
    [self saveLocalWatchTime];
    [self cancelDispatchTimer];
}

#pragma mark - [ Private Method ]

- (void)loadCardPushWithRoomId:(NSString *)roomId cardId:(NSString *)cardId completion:(void (^)(NSDictionary *cardDict))completion {
    [PLVLiveVideoAPI requestCardPushInfoWithChannelId:roomId cardPushId:cardId completion:completion failure:^(NSError * _Nonnull error) {}];
}

- (void)setCardPushButtonViewWithCardInfo:(NSDictionary *)cardDict callback:(void (^)(BOOL show))callback {
    self.canOpenCard = YES;
    self.countdownLabel.hidden = YES;
    // 是否隐藏挂件
    self.enterEnabled = PLV_SafeBoolForDictKey(cardDict, @"enterEnabled");
    self.hidden = !self.enterEnabled;
    callback ? callback(!self.hidden) : nil;
    
    NSString *imageType = PLV_SafeStringForDictKey(cardDict, @"imageType");
    // 设置 button 图片
    if ([imageType isEqualToString:@"redpack"] || [imageType isEqualToString:@"giftbox"]) {
        NSString *imageName = [imageType isEqualToString:@"redpack"] ? PLVLocalizedString(@"plvlc_chatroom_redpack") : PLVLocalizedString(@"plvlc_chatroom_giftbox");
        UIImage *image = [PLVLCUtils imageForChatroomResource:imageName];
        [self.cardPushButton setImage:image forState:UIControlStateNormal];
    } else if ([imageType isEqualToString:@"custom"]) {
        NSString *imageURLString = PLV_SafeStringForDictKey(cardDict, @"enterImage");
        if ([PLVFdUtil checkStringUseable:imageURLString]) {
            NSURL *imageURL = [NSURL URLWithString:imageURLString];
            if (imageURL && !imageURL.scheme) {
                imageURL = [NSURL URLWithString:[@"https:" stringByAppendingString:imageURL.absoluteString]];
            }
            [self.cardPushButton sd_setImageWithURL:imageURL forState:UIControlStateNormal];
        }
    }
    
    // 观看条件
    NSString *showCondition = PLV_SafeStringForDictKey(cardDict, @"showCondition");
    if ([showCondition isEqualToString:@"WATCH"]) { // 需要观看
        // 观看时长(ms)
        NSInteger watchConditionTime = PLV_SafeIntegerForDictKey(cardDict, @"conditionValue")/1000;
        self.conditionTime = watchConditionTime;

        // 开始观看倒计时
        NSInteger localWatchTime = self.localWatchTime;
        if (watchConditionTime > 0 && watchConditionTime > localWatchTime) {
            self.hidden = NO;
            self.canOpenCard = NO;
            self.countdownLabel.hidden = NO;
            __weak typeof(self) weakSelf = self;
            [self startCountdownWithLocalWatchTime:localWatchTime endCallback:^{
                [weakSelf countdownEndCallback];
            }];
        } else if (watchConditionTime == 0 && localWatchTime == 0){
            // 设置观看时间，记录本地观看记录
            self.watchTime = 1;
            [self saveLocalWatchTime];
            [self callbackForNeedOpenInteract];
        }
        
        // 提示弹窗
        NSString *countdownMsg = PLV_SafeStringForDictKey(cardDict, @"countdownMsg");
        [self.popupView setPopupViewTitle:countdownMsg];
        [self showPopupTitleView];
        
        [self setNeedsLayout];
    }
}

- (void)startCountdownWithLocalWatchTime:(NSInteger)watchTime endCallback:(void (^)(void))callback {
    self.watchTime = watchTime;
    dispatch_queue_t quene = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.countdownTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, quene);
    dispatch_source_set_timer(self.countdownTimer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0);
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(self.countdownTimer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.watchTime >= weakSelf.conditionTime) {
                callback ? callback() : nil;
            } else {
                NSInteger remainingTime = weakSelf.conditionTime - weakSelf.watchTime;
                NSString *watchTimeText = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",lround(floor(remainingTime / 60 / 60)), lround(floor(remainingTime / 60)) % 60, lround(floor(remainingTime)) % 60];
                self.countdownLabel.text = [NSString stringWithFormat:@"%@", watchTimeText];
                weakSelf.watchTime ++;
            }
        });
    });
    dispatch_resume(self.countdownTimer);
}

- (void)countdownEndCallback {
    self.countdownLabel.hidden = YES;
    self.canOpenCard = YES;
    self.hidden = !self.enterEnabled;
    [self setNeedsLayout];

    [self saveLocalWatchTime];
    [self cancelDispatchTimer];
    [self callbackForNeedOpenInteract];
}

- (void)saveLocalWatchTime {
    if (self.countdownTimer && self.watchTime > self.localWatchTime) {
        [[NSUserDefaults standardUserDefaults] setInteger:self.watchTime forKey:self.localWatchTimeKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)cancelDispatchTimer {
    if (self.countdownTimer) {
        dispatch_cancel(self.countdownTimer);
        self.countdownTimer = nil;
    }
}

- (void)showPopupTitleView {
    if (self.popupView.hidden) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(cardPushButtonViewPopupViewDidShow:)]) {
            [self.delegate cardPushButtonViewPopupViewDidShow:self];
        }
        self.popupView.hidden = NO;
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            weakSelf.popupView.hidden = YES;
        });
    }
}

#pragma mark - Getter & Setter

- (UIButton *)cardPushButton {
    if (!_cardPushButton) {
        _cardPushButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cardPushButton addTarget:self action:@selector(cardPushAction:) forControlEvents:UIControlEventTouchUpInside];
        UIImage *image = [PLVLCUtils imageForChatroomResource:PLVLocalizedString(@"plvlc_chatroom_giftbox")];
        [_cardPushButton setImage:image forState:UIControlStateNormal];
    }
    return _cardPushButton;
}

- (UILabel *)countdownLabel {
    if (!_countdownLabel) {
        _countdownLabel = [[UILabel alloc] init];
        _countdownLabel.textAlignment = NSTextAlignmentCenter;
        _countdownLabel.textColor = [UIColor whiteColor];
        _countdownLabel.font = [UIFont systemFontOfSize:10];
        _countdownLabel.backgroundColor = [UIColor clearColor];
    }
    return _countdownLabel;
}

- (PLVLCCardPushPopupView *)popupView {
    if (!_popupView) {
        _popupView = [[PLVLCCardPushPopupView alloc] init];
        _popupView.hidden = YES;
    }
    return _popupView;
}

- (NSString *)localWatchTimeKey {
    return [NSString stringWithFormat:@"PLVLiveWatchTimeKey%@-%@", self.channelId, self.cardId];
}

- (NSInteger)localWatchTime {
    NSInteger localWatchTime = [[NSUserDefaults standardUserDefaults] integerForKey:self.localWatchTimeKey];
    return localWatchTime;
}

#pragma mark - Callback

- (void)callbackForNeedOpenInteract {
    plv_dispatch_main_async_safe(^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(cardPushButtonView:needOpenInteract:)]) {
            [self.delegate cardPushButtonView:self needOpenInteract:self.cardDict];
        }
    })
}

#pragma mark - Action

- (void)cardPushAction:(UIButton *)sender {
    if (self.canOpenCard) {
        [self callbackForNeedOpenInteract];
    } else {
        [self showPopupTitleView];
    }
}

@end
