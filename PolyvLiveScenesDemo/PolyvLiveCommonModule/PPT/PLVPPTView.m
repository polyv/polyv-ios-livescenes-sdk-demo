//
//  PLVPPTView.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/9/17.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVPPTView.h"

#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

#define PLVColor_BackgroudImageView_BlueBlack UIColorFromRGB(@"2B3045")

@interface PLVPPTView () <PLVSocketListenerProtocol, PLVPPTWebviewDelegate>

/// view hierarchy
///
/// (PLVPPTView) self
/// ├── (UIImageView) backgroudImageView (lowest)
/// └── (PLVPPTWebview) pptWebview (top)
///       └── (WKWebview) webview
@property (nonatomic, strong) UIImageView * backgroudImageView;
@property (nonatomic, strong) PLVPPTWebview * pptWebview;

@end

@implementation PLVPPTView

#pragma mark - [ Life Period ]
- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setup];
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews{
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    
    CGFloat backgroudImageViewWidth = 180.0 / 375.0 * viewWidth;
    CGFloat backgroudImageViewWHScale = 180.0 / 142.0;
    CGFloat backgroudImageViewHeight = backgroudImageViewWidth / backgroudImageViewWHScale;
    self.backgroudImageView.frame = CGRectMake((viewWidth - backgroudImageViewWidth) / 2.0,
                                               (viewHeight - backgroudImageViewHeight) / 2.0,
                                               backgroudImageViewWidth,
                                               backgroudImageViewHeight);
}


#pragma mark - [ Public Methods ]
- (void)setSEIDataWithNewTimestamp:(long)newTimeStamp{
    NSString *json = [NSString stringWithFormat:@"{\"time\":\"%ld\"}",newTimeStamp];
    [self.pptWebview setSEIData:json];
}

/// 回放场景相关
- (void)pptStart:(NSString *)vid {
    [self.pptWebview pptStart:vid];
}

- (void)pptPlay:(long)currentTime {
    [self.pptWebview pptPlay:currentTime];
}

- (void)pptPause:(long)currentTime {
    [self.pptWebview pptPause:currentTime];
}

- (void)pptSeek:(long)toTime {
    [self.pptWebview pptSeek:toTime];
}


#pragma mark - [ Private Methods ]
- (void)setup{
    /// 添加 socket 事件监听
    [[PLVSocketWrapper sharedSocketWrapper] addListener:self];
}

- (void)setupUI{
    self.backgroundColor = PLVColor_BackgroudImageView_BlueBlack;

    [self addSubview:self.backgroudImageView];

    [self addSubview:self.pptWebview];
    self.pptWebview.frame = self.bounds;
    self.pptWebview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.pptWebview loadOnlinePPT];
}

#pragma mark Getter
- (UIImageView *)backgroudImageView{
    if (!_backgroudImageView) {
        _backgroudImageView = [[UIImageView alloc] init];
        _backgroudImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _backgroudImageView;
}

- (PLVPPTWebview *)pptWebview{
    if (!_pptWebview) {
        _pptWebview = [[PLVPPTWebview alloc] init];
        _pptWebview.delegate = self;
        //_pptWebview.jsDebugMode = YES;
    }
    return _pptWebview;
}


#pragma mark - [ Delegate ]
#pragma mark PLVSocketListenerProtocol
/// socket 接收到 "message" 事件
- (void)socket:(id<PLVSocketIOProtocol>)socket didReceiveMessage:(NSString *)string jsonDict:(NSDictionary *)jsonDict{
    NSString * subEvent = jsonDict[@"EVENT"];
    if ([subEvent isEqualToString:PLVSocketIOPPT_onSliceID_key]
        || [subEvent isEqualToString:PLVSocketIOPPT_onSliceOpen_key]
        || [subEvent isEqualToString:PLVSocketIOPPT_onSliceStart_key]
        || [subEvent isEqualToString:PLVSocketIOPPT_onSliceDraw_key]
        || [subEvent isEqualToString:PLVSocketIOPPT_onSliceControl_key]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(plvPPTViewGetPPTRefreshDelayTime:)]) {
            unsigned int delayTime = [self.delegate plvPPTViewGetPPTRefreshDelayTime:self];
            [self.pptWebview refreshPPT:string delay:delayTime];
        }
    } else if ([subEvent isEqualToString:PLVSocketIOChatRoom_LOGIN_EVENT]){
        self.pptWebview.userInfo = jsonDict;
    }
}

#pragma mark PLVPPTWebviewDelegate
/// [回放场景] PPT视图 需要获取视频播放器的当前播放时间点
- (NSTimeInterval)plvPPTWebviewGetPlayerCurrentTime:(PLVPPTWebview *)pptWebview{
    if ([self.delegate respondsToSelector:@selector(plvPPTViewGetPlayerCurrentTime:)]) {
        return [self.delegate plvPPTViewGetPlayerCurrentTime:self];
    }else{
        return 0;
    }
}

/// [回放场景] PPT视图 讲师发起PPT位置切换
- (void)plvPPTWebview:(PLVPPTWebview *)pptWebview changePPTPosition:(BOOL)status{
    if ([self.delegate respondsToSelector:@selector(plvPPTView:changePPTPosition:)]) {
        [self.delegate plvPPTView:self changePPTPosition:status];
    }
}

@end
