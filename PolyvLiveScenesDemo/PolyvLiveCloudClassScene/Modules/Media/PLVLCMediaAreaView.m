//
//  PLVLCMediaAreaView.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/9/15.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCMediaAreaView.h"

// UI
#import "PLVLCMediaPlayerCanvasView.h"
#import "PLVLCMediaMoreView.h"
#import "PLVPlayerLogoView.h"

// 模块
#import "PLVPPTView.h"
#import "PLVDanMu.h"
#import "PLVEmoticonManager.h"
#import "PLVPlayerPresenter.h"
#import "PLVRoomDataManager.h"

// 工具
#import "PLVLCUtils.h"

// 依赖库
#import <PolyvFoundationSDK/PolyvFoundationSDK.h>

static NSString *const PLVLCMediaAreaView_Data_ModeOptionTitle = @"模式";
static NSString *const PLVLCMediaAreaView_Data_QualityOptionTitle = @"视频质量";
static NSString *const PLVLCMediaAreaView_Data_RouteOptionTitle = @"线路";
static NSString *const PLVLCMediaAreaView_Data_SpeedOptionTitle = @"倍速";

@interface PLVLCMediaAreaView () <
PLVLCFloatViewDelegate,
PLVLCMediaMoreViewDelegate,
PLVLCMediaPlayerCanvasViewDelegate,
PLVPPTViewDelegate,
PLVPlayerPresenterDelegate
>

#pragma mark 状态
@property (nonatomic, assign, readonly) BOOL inLinkMic; // 只读，是否正在连麦
@property (nonatomic, assign, readonly) BOOL inRTCRoom; // 只读，是否正在RTC房间中
@property (nonatomic, assign, readonly) PLVChannelType channelType; // 只读，当前 频道类型
@property (nonatomic, assign, readonly) PLVChannelVideoType videoType; // 只读，当前 视频类型
@property (nonatomic, assign, readonly) PLVChannelLiveStreamState liveState; // 只读，当前 直播流状态
@property (nonatomic, assign, readonly) PLVChannelLinkMicSceneType linkMicSceneType; // 只读，当前 连麦场景类型
@property (nonatomic, assign) PLVChannelLinkMicSceneType lastLinkMicSceneType; // 上次 连麦场景类型
@property (nonatomic, assign) PLVLCMediaAreaViewLiveSceneType currentLiveSceneType;
@property (nonatomic, assign, readonly) BOOL pptOnMainSite;     // 只读，PPT当前是否处于主屏 (此属性仅适合判断PPT是否在主屏，不适合判断其他视图所处位置)

#pragma mark 模块
@property (nonatomic, strong) PLVPlayerPresenter * playerPresenter; // 播放器 功能模块
@property (nonatomic, strong) PLVPPTView * pptView;                 // PPT 功能模块
@property (nonatomic, strong) PLVVideoMarquee * videoMarquee;       // 视频跑马灯

#pragma mark UI
/// view hierarchy
///
/// [竖屏] 主屏显示 播放器画面 时:
/// (UIView) superview
/// ├── (PLVLCMediaAreaView) self
/// │   ├── (UIView) contentBackgroudView
/// │   │    └── (PLVLCMediaPlayerCanvasView) canvasView
/// │   └── (PLVLCMediaPlayerSkinView) skinView
/// │
/// ├── (UIView) marqueeView
/// │
/// └── (PLVLCMediaFloatView) floatView
///      └── (UIView) contentBackgroudView
///           └── (PLVPPTView) pptView
///
/// [竖屏] 主屏显示 PPT 时:
/// (UIView) superview
/// ├── (PLVLCMediaAreaView) self
/// │   ├── (UIView) contentBackgroudView
/// │   │    └── (PLVPPTView) pptView
/// │   └── (PLVLCMediaPlayerSkinView) skinView
/// │
/// ├── (UIView) marqueeView
/// │
/// └── (PLVLCMediaFloatView) floatView
///      └── (UIView) contentBackgroudView
///           └── (PLVLCMediaPlayerCanvasView) canvasView
///
/// [横屏] 主屏显示 播放器画面 时:
/// (UIView) superview
/// ├── (PLVLCMediaAreaView) self
/// │   └── (UIView) contentBackgroudView
/// │       └── (PLVLCMediaPlayerCanvasView) canvasView
/// │
/// ├── (PLVLCMediaFloatView) floatView
/// │     └── (UIView) contentBackgroudView
/// │          └── (PLVPPTView) pptView
/// │
/// ├── (PLVLCLiveRoomPlayerSkinView) liveRoomSkinView
/// │
/// └── (UIView) marqueeView
///
/// [横屏] 主屏显示 PPT 时:
/// (UIView) superview
/// ├── (PLVLCMediaAreaView) self
/// │   └── (UIView) contentBackgroudView
/// │       └── (PLVLCMediaPlayerCanvasView) pptView
/// │
/// ├── (PLVLCMediaFloatView) floatView
/// │     └── (UIView) contentBackgroudView
/// │          └── (PLVLCMediaPlayerCanvasView) canvasView
/// │
/// ├── (PLVLCLiveRoomPlayerSkinView) liveRoomSkinView
/// │
/// └── (UIView) marqueeView
@property (nonatomic, strong) UIView * contentBackgroudView; // 内容背景视图 (负责承载 不同类型的内容画面（播放器画面、或PPT画面）；直接决定了’内容画面‘ 在 PLVLCMediaAreaView 中的布局、图层)
@property (nonatomic, strong) PLVLCMediaPlayerCanvasView * canvasView; // 播放器背景视图 (负责承载 播放器画面；可能会被移动添加至外部视图类中；当被移动添加至外部时，仍被 PLVLCMediaAreaView 持有，但subview关系改变；)
@property (nonatomic, strong) PLVLCMediaPlayerSkinView * skinView;     // 竖屏播放器皮肤视图 (负责承载 播放器的控制按钮)
@property (nonatomic, strong) PLVLCMediaFloatView * floatView;
@property (nonatomic, strong) PLVLCMediaMoreView * moreView;
@property (nonatomic, strong) PLVDanMu *danmuView;  // 弹幕 (用于显示 ‘聊天室消息’)
@property (nonatomic, strong) UIView * marqueeView; // 跑马灯 (用于显示 ‘用户昵称’，规避非法录屏)
@property (nonatomic, strong) UIView * logoView; // LOGO视图 （用于显示 '播放器LOGO'）

@end

@implementation PLVLCMediaAreaView

#pragma mark - [ Life Period ]
- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero]) {
        [self setupUI];
        [self setupModule];
    }
    return self;
}

- (void)layoutSubviews{
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    
    CGFloat superviewWidth = CGRectGetWidth(self.superview.bounds);
    CGFloat superviewHeight = CGRectGetHeight(self.superview.bounds);
    
    // 安全区域计算
    CGFloat toppadding;
    CGFloat leftpadding;
    CGFloat viewSafeWidth;
    CGFloat viewSafeHeight;
    if (@available(iOS 11.0, *)) {
        toppadding = self.safeAreaInsets.top;
        leftpadding = self.safeAreaInsets.left;
        viewSafeWidth = self.safeAreaLayoutGuide.layoutFrame.size.width;
        viewSafeHeight = self.safeAreaLayoutGuide.layoutFrame.size.height;
    } else {
        toppadding = fullScreen ? 0 : self.topPaddingBelowiOS11;
        leftpadding = 0;
        viewSafeWidth = viewWidth;
        viewSafeHeight = viewHeight - toppadding;
    }
    
    if (!fullScreen) {
        // 竖屏
        CGFloat contentBackgroudViewY = self.limitContentViewInSafeArea ? toppadding : 0;
        CGFloat contentBackgroudViewHeight = self.limitContentViewInSafeArea ? viewSafeHeight : viewHeight;
        self.contentBackgroudView.frame = CGRectMake(0, contentBackgroudViewY, viewWidth, contentBackgroudViewHeight);
    } else {
        // 横屏
        CGFloat contentBackgroudViewX = self.limitContentViewInSafeArea ? leftpadding : 0;
        CGFloat contentBackgroudViewWidth = self.limitContentViewInSafeArea ? viewSafeWidth : viewWidth;
        self.contentBackgroudView.frame = CGRectMake(contentBackgroudViewX, 0, contentBackgroudViewWidth, viewHeight);
    }
    
    [self.danmuView resetFrame:self.contentBackgroudView.frame];

    self.skinView.frame = self.bounds;
    
    CGFloat floatViewWidth = 150;
    CGFloat floatViewHeight = floatViewWidth * PPTPlayerViewScale;
    
    /// 将 floatView 添加在父视图上
    /// (注:不可添加在window上，否则页面push时将一并带去)
    if (self.superview && !_floatView.superview) { [self.superview addSubview:self.floatView]; }
    self.floatView.frame = CGRectMake((superviewWidth - floatViewWidth),
                                      (superviewHeight - floatViewHeight) / 2.0 + 50,
                                      floatViewWidth, floatViewHeight);
    
    if (self.superview && !self.marqueeView.superview) { [self.superview addSubview:self.marqueeView]; }
    self.marqueeView.frame = self.contentBackgroudView.frame;
}


#pragma mark - [ Public Methods ]
- (void)refreshUIInfo {
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    [self.skinView setTitleLabelWithText:roomData.menuInfo.name];
    [self.skinView setPlayTimesLabelWithTimes:roomData.menuInfo.pageView.integerValue];
}

- (void)switchAreaViewLiveSceneTypeTo:(PLVLCMediaAreaViewLiveSceneType)toType{
    if (self.currentLiveSceneType == toType) {
        NSLog(@"PLVLCMediaAreaView - switchAreaViewLiveSceneTypeTo failed, type is same");
        return;
    }else if(self.videoType != PLVChannelVideoType_Live){
        NSLog(@"PLVLCMediaAreaView - switchAreaViewLiveSceneTypeTo failed, video type is not 'Live'");
        return;
    }
    
    if (toType == PLVLCMediaAreaViewLiveSceneType_WatchCDN) { /// 观看 ‘CDN’ 场景
        if (self.liveState == PLVChannelLiveStreamState_Live) {
            // 直播中
            if (self.channelType == PLVChannelTypePPT) {
                /// 出现 floatView
                /// 其中 userOperat:YES 表示 ’代表用户去执行’，即强制执行
                [self.floatView showFloatView:YES userOperat:YES];
            } else if(self.channelType == PLVChannelTypeAlone){
                [self contentBackgroundViewDisplaySubview:self.canvasView];
            }
            
            /// 恢复直播播放器
            [self.playerPresenter resumePlay];
            
            if (self.lastLinkMicSceneType == PLVChannelLinkMicSceneType_Alone_PartRtc) {
                /// 直播播放器 解除静音
                [self.playerPresenter cancelMute];
            }
            
            /// 竖屏皮肤视图
            [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_Living_CDN];
        }else{
            // 直播已结束
            if (self.channelType == PLVChannelTypePPT) {
                /// 确保 ‘播放器画面’ 位于主屏
                if (self.pptOnMainSite) { [self.floatView triggerViewExchangeEvent]; }
            } else if(self.channelType == PLVChannelTypeAlone){
                [self contentBackgroundViewDisplaySubview:self.canvasView];
            }
            
            /// 竖屏皮肤视图
            [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_None];
        }
    } else if (toType == PLVLCMediaAreaViewLiveSceneType_WatchNoDelay) {
        if (self.currentLiveSceneType == PLVLCMediaAreaViewLiveSceneType_WatchCDN) {
            /// 播放器 清理
            [self.playerPresenter cleanPlayer];
            
            /// 确保 PPT 位于主屏
            if (!self.pptOnMainSite) {
                [self.floatView triggerViewExchangeEvent];
            }
            
            /// 隐藏 floatView
            /// userOperat:YES 表示代表用户强制执行
            [self.floatView showFloatView:NO userOperat:YES];
            
            /// 竖屏皮肤视图
            [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_Living_NODelay];
        }
    } else if (toType == PLVLCMediaAreaViewLiveSceneType_InLinkMic){ /// 正在 ‘连麦’ 场景
        if (self.currentLiveSceneType != PLVLCMediaAreaViewLiveSceneType_WatchNoDelay) {
            if (self.linkMicSceneType == PLVChannelLinkMicSceneType_Alone_PartRtc) {
                /// 直播播放器 仅作静音
                [self.playerPresenter mute];
                
                /// 竖屏皮肤视图
                [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_InLinkMic_PartRTC];
            } else if (self.linkMicSceneType == PLVChannelLinkMicSceneType_Alone_PureRtc){
                /// 直播播放器 清理
                [self.playerPresenter cleanPlayer];
                
                /// 竖屏皮肤视图
                [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_InLinkMic_PureRTC];
            }else if (self.linkMicSceneType == PLVChannelLinkMicSceneType_PPT_PureRtc){
                /// 确保 PPT 位于主屏
                if (!self.pptOnMainSite) { [self.floatView triggerViewExchangeEvent]; }
                
                /// 直播播放器清理
                [self.playerPresenter cleanPlayer];
                
                /// 隐藏 floatView
                /// userOperat:YES 表示代表用户强制执行
                [self.floatView showFloatView:NO userOperat:YES];
                
                /// 竖屏皮肤视图
                [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_InLinkMic_PureRTC];
            }
        }
        self.lastLinkMicSceneType = self.linkMicSceneType;
    } else {
        NSLog(@"PLVLCMediaAreaView - switchAreaViewLiveSceneTypeTo failed, type%lud not support",(unsigned long)toType);
    }
    
    self.currentLiveSceneType = toType;
}

- (void)displayContentView:(UIView *)contentView{
    if (contentView && [contentView isKindOfClass:UIView.class]) {
        [self contentBackgroundViewDisplaySubview:contentView];
    }else{
        NSLog(@"PLVLCMediaAreaView - displayExternalView failed, view is illegal : %@",contentView);
    }
}

- (UIView *)getContentViewForExchange{
    if (self.currentLiveSceneType == PLVLCMediaAreaViewLiveSceneType_InLinkMic || self.currentLiveSceneType == PLVLCMediaAreaViewLiveSceneType_WatchNoDelay) {
        UIView * currentContentView = self.contentBackgroudView.subviews.firstObject;
        if (currentContentView) {
            return currentContentView;
        }else{
            NSLog(@"PLVLCMediaAreaView - getViewForExchange failed, currentContentView is illegal : %@",currentContentView);
        }
    }else{
        NSLog(@"PLVLCMediaAreaView - getViewForExchange failed, this method should been call in LinkMic or NoDelay, but current liveSceneType is %lu",(unsigned long)self.currentLiveSceneType);
    }
    return nil;
}

#pragma mark Getter
- (BOOL)channelWatchNoDelay{
    return self.playerPresenter.channelWatchNoDelay;
}

- (BOOL)noDelayLiveStart{
    return self.playerPresenter.currentNoDelayLiveStart;
}


#pragma mark - [ Private Methods ]
- (void)setupData{
    self.currentLiveSceneType = PLVLCMediaAreaViewLiveSceneType_WatchCDN;
}

- (void)setupUI{
    /// 添加视图
    [self addSubview:self.contentBackgroudView];
    
    [self contentBackgroundViewDisplaySubview:self.canvasView]; // 无直播时的默认状态，是‘播放器画面’位于主屏
    
    [self addSubview:self.danmuView];
    
    [self addSubview:self.skinView];
}

- (void)contentBackgroundViewDisplaySubview:(UIView *)subview{
    [self removeSubview:self.contentBackgroudView];
    [self.contentBackgroudView addSubview:subview];
    subview.frame = self.contentBackgroudView.bounds;
    subview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)setupModule{
    /// 注意：懒加载过程中(即Getter)，已增加判断，若场景不匹配，将创建失败并返回nil
    if (self.videoType == PLVChannelVideoType_Live) { // 视频类型为 直播
        /// 直播 模块
        self.playerPresenter = [[PLVPlayerPresenter alloc] initWithVideoType:PLVChannelVideoType_Live];
        self.playerPresenter.delegate = self;
        [self.playerPresenter setupPlayerWithDisplayView:self.canvasView.playerSuperview];
         
        /// PPT模块
        [self.floatView displayExternalView:self.pptView]; /// 无直播时的默认状态，是‘PPT画面’位于副屏(悬浮小窗)
        
    }else if (self.videoType == PLVChannelVideoType_Playback){ // 视频类型为 直播回放
        /// 直播回放 模块
        self.playerPresenter = [[PLVPlayerPresenter alloc] initWithVideoType:PLVChannelVideoType_Playback];
        self.playerPresenter.delegate = self;
        [self.playerPresenter setupPlayerWithDisplayView:self.canvasView.playerSuperview];
        
        /// PPT模块
        [self.floatView displayExternalView:self.pptView]; /// 默认状态，是‘PPT画面’位于副屏(悬浮小窗)
        [self.floatView showFloatView:YES userOperat:NO];
        [self.pptView pptStart:[PLVRoomDataManager sharedManager].roomData.vid];
        
    }
}

- (UIImage *)getImageWithName:(NSString *)imageName{
    return [PLVLCUtils imageForMediaResource:imageName];
}

- (void)removeSubview:(UIView *)superview{
    for (UIView * subview in superview.subviews) { [subview removeFromSuperview]; }
}

- (NSArray *)getMoreViewDefaultDataArray{
    NSArray * returnArray;
    if (self.videoType == PLVChannelVideoType_Live) { // 视频类型为 直播
        PLVLCMediaMoreModel * modeModel = [PLVLCMediaMoreModel modelWithOptionTitle:PLVLCMediaAreaView_Data_ModeOptionTitle optionItemsArray:@[@"播放画面",@"仅听声音"]];
        returnArray = @[modeModel];
    } else if (self.videoType == PLVChannelVideoType_Playback) { // 视频类型为 直播回放
        PLVLCMediaMoreModel * speedModel = [PLVLCMediaMoreModel modelWithOptionTitle:PLVLCMediaAreaView_Data_SpeedOptionTitle optionItemsArray:@[@"0.5x",@"1.0x",@"1.5x",@"2.0x"] selectedIndex:1];
        speedModel.optionSpecifiedWidth = 50.0;
        returnArray = @[speedModel];
    }
    return returnArray;
}

- (void)updateMoreviewWithData {
    // 视频质量选项数据
    PLVLCMediaMoreModel * qualityModel = [PLVLCMediaMoreModel modelWithOptionTitle:PLVLCMediaAreaView_Data_QualityOptionTitle optionItemsArray:self.playerPresenter.codeRateNamesOptions];
    [qualityModel setSelectedIndexWithOptionItemString:self.playerPresenter.currentCodeRate];
    
    // 线路选项数据
    NSMutableArray * routeArray = [[NSMutableArray alloc] init];
    for (int i = 1; i <= self.playerPresenter.lineNum; i++) {
        NSString * route = [NSString stringWithFormat:@"线路%d",i];
        [routeArray addObject:route];
    }
    PLVLCMediaMoreModel * routeModel = [PLVLCMediaMoreModel modelWithOptionTitle:PLVLCMediaAreaView_Data_RouteOptionTitle optionItemsArray:routeArray selectedIndex:self.playerPresenter.currentLineIndex];
    
    // 整合数据
    NSMutableArray * modelArray = [[NSMutableArray alloc] init];
    if (qualityModel) { [modelArray addObject:qualityModel]; }
    if (routeModel) { [modelArray addObject:routeModel]; }

    // 更新 moreView
    [self.moreView updateTableViewWithDataArrayByMatchModel:modelArray];
}
    
#pragma mark Danmu
- (void)showDanmu:(BOOL)show {
    self.danmuView.hidden = !show;
}

- (void)insertDanmu:(NSString *)danmu {
    UIFont *font = [UIFont systemFontOfSize:14];
    NSShadow *shadow = [NSShadow new];
    shadow.shadowOffset = CGSizeMake(1, 1);
    shadow.shadowColor = UIColorFromRGB(@"#333333");
    NSDictionary *dict = @{NSFontAttributeName:font,
                           NSForegroundColorAttributeName:[UIColor whiteColor],
                           NSShadowAttributeName:shadow};
    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:danmu attributes:dict];
    NSMutableAttributedString *muString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:attString font:font];
    [self.danmuView insertDML:muString];
}

#pragma mark Marquee
- (void)setupMarquee:(PLVChannelInfoModel *)channel customNick:(NSString *)customNick  {
    if (self.videoMarquee) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self handleMarquee:channel customNick:customNick completion:^(PLVMarqueeModel *model, NSError *error) {
        if (model) {
            [weakSelf loadVideoMarqueeView:model];
        } else if (error) {
            if (error.code == -10000) {
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(plvLCMediaAreaViewWannaBack:)]) {
                    [weakSelf.delegate plvLCMediaAreaViewWannaBack:weakSelf];
                }
            } else {
                NSLog(@"自定义跑马灯加载失败：%@",error);
            }
        } else {
            NSLog(@"无跑马灯或跑马灯不显示");
        }
    }];
}

- (void)handleMarquee:(PLVChannelInfoModel *)channel customNick:(NSString *)customNick completion:(void (^)(PLVMarqueeModel * model, NSError *error))completion {
    switch (channel.marqueeType) {
        case PLVChannelMarqueeType_Nick:
            if (customNick) {
                channel.marquee = customNick;
            } else {
                channel.marquee = @"自定义昵称";
            }
        case PLVChannelMarqueeType_Fixed: {
            float alpha = channel.marqueeOpacity.floatValue/100.0;
            PLVMarqueeModel *model = [PLVMarqueeModel marqueeModelWithContent:channel.marquee fontSize:channel.marqueeFontSize.unsignedIntegerValue fontColor:channel.marqueeFontColor alpha:alpha autoZoom:channel.marqueeAutoZoomEnabled];
            completion(model, nil);
        } break;
        case PLVChannelMarqueeType_URL: {
            if (channel.marquee) {
                [PLVLiveVideoAPI loadCustomMarquee:[NSURL URLWithString:channel.marquee] withChannelId:channel.channelId.integerValue userId:channel.accountUserId completion:^(BOOL valid, NSDictionary *marqueeDict) {
                    if (valid) {
                        completion([PLVMarqueeModel marqueeModelWithMarqueeDict:marqueeDict], nil);
                    } else {
                        NSError *error = [NSError errorWithDomain:@"net.polyv.cloudClassBaseMediaError" code:-10000 userInfo:@{NSLocalizedDescriptionKey:marqueeDict[@"msg"]}];
                        completion(nil, error);
                    }
                } failure:^(NSError *error) {
                    completion(nil, error);
                }];
            }
        } break;
        default:
            completion(nil, nil);
            break;
    }
}

- (void)loadVideoMarqueeView:(PLVMarqueeModel *)model {
    for (CALayer * subLayer in self.marqueeView.layer.sublayers) {
        [subLayer removeFromSuperlayer];
    }
    
    self.videoMarquee = [PLVVideoMarquee videoMarqueeWithMarqueeModel:model];
    [self.videoMarquee showVideoMarqueeInView:self.marqueeView];
}

#pragma mark Getter
- (CGFloat)topPaddingBelowiOS11{
    /// 仅在 [limitContentViewInSafeArea] 为YES，会使用此值，否则均返回 0
    return self.limitContentViewInSafeArea ? _topPaddingBelowiOS11 : 0;
}

- (UIView *)contentBackgroudView{
    if (!_contentBackgroudView) {
        _contentBackgroudView = [[UIView alloc]init];
    }
    return _contentBackgroudView;
}

- (PLVLCMediaPlayerCanvasView *)canvasView{
    if (!_canvasView) {
        _canvasView = [[PLVLCMediaPlayerCanvasView alloc] init];
        _canvasView.delegate = self;
    }
    return _canvasView;
}

- (UIView *)marqueeView{
    if (!_marqueeView) {
        _marqueeView = [[UIView alloc] init];
        _marqueeView.backgroundColor = [UIColor clearColor];
        _marqueeView.userInteractionEnabled = NO;
    }
    return _marqueeView;
}

- (PLVDanMu *)danmuView {
    if (!_danmuView) {
        _danmuView = [[PLVDanMu alloc] init];
        _danmuView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _danmuView.hidden = YES;
        _danmuView.userInteractionEnabled = NO;
    }
    return _danmuView;
}

- (PLVLCMediaPlayerSkinView *)skinView{
    if (!_skinView) {
        _skinView = [[PLVLCMediaPlayerSkinView alloc] init];
        _skinView.baseDelegate = self;
    }
    return _skinView;
}

- (PLVLCMediaFloatView *)floatView{
    if (!_floatView && self.channelType != PLVChannelTypeAlone) {
        _floatView = [[PLVLCMediaFloatView alloc] init];
        _floatView.delegate = self;
    }
    return _floatView;
}

- (PLVLCMediaMoreView *)moreView{
    if (!_moreView) {
        _moreView = [[PLVLCMediaMoreView alloc] init];
        _moreView.delegate = self;
        _moreView.topPaddingBelowiOS11 = 20.0;
        [_moreView refreshTableViewWithDataArray:[self getMoreViewDefaultDataArray]]; // 本地可决定的选项数据，则创建时一并设置
    }
    return _moreView;
}

- (PLVPPTView *)pptView{
    if (!_pptView && self.channelType != PLVChannelTypeAlone) {
        _pptView = [[PLVPPTView alloc] init];
        _pptView.delegate = self;
        _pptView.backgroudImageView.image = [self getImageWithName:@"plvlc_media_ppt_placeholder"];
    }
    return _pptView;
}

- (BOOL)inLinkMic{
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCMediaAreaViewGetInLinkMic:)]) {
        return [self.delegate plvLCMediaAreaViewGetInLinkMic:self];
    }else{
        NSLog(@"PLVLCMediaViewController - delegate not implement method:[plvLCMediaAreaViewGetInLinkMic:]");
        return NO;
    }
}

- (BOOL)inRTCRoom{
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCMediaAreaViewGetInLinkMic:)]) {
        return [self.delegate plvLCMediaAreaViewGetInRTCRoom:self];
    }else{
        NSLog(@"PLVLCMediaViewController - delegate not implement method:[plvLCMediaAreaViewGetInRTCRoom:]");
        return NO;
    }
}

- (PLVChannelType)channelType{
    return [PLVRoomDataManager sharedManager].roomData.channelType;
}

- (PLVChannelVideoType)videoType{
    return [PLVRoomDataManager sharedManager].roomData.videoType;
}

- (PLVChannelLiveStreamState)liveState{
    return [PLVRoomDataManager sharedManager].roomData.liveState;
}

- (PLVChannelLinkMicSceneType)linkMicSceneType{
    return [PLVRoomDataManager sharedManager].roomData.linkMicSceneType;
}

- (BOOL)pptOnMainSite{
    if (self.pptView.superview == self.contentBackgroudView) {
        return YES;
    }else{
        return NO;
    }
}


#pragma mark - [ Delegate ]
#pragma mark PLVLCBasePlayerSkinViewDelegate
- (void)plvLCBasePlayerSkinViewBackButtonClicked:(PLVLCBasePlayerSkinView *)skinView currentFullScreen:(BOOL)currentFullScreen{
    if (currentFullScreen) {
        [PLVFdUtil changeDeviceOrientationToPortrait];
    }else{
        __weak typeof(self) weakSelf = self;
        [PLVFdUtil showAlertWithTitle:@"确认退出直播间？" message:nil viewController:[PLVFdUtil getCurrentViewController] cancelActionTitle:@"按错了" cancelActionStyle:UIAlertActionStyleDefault cancelActionBlock:nil confirmActionTitle:@"退出" confirmActionStyle:UIAlertActionStyleDestructive confirmActionBlock:^(UIAlertAction * _Nonnull action) {
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(plvLCMediaAreaViewWannaBack:)]) {
                [weakSelf.delegate plvLCMediaAreaViewWannaBack:weakSelf];
            }
        }];
    }
}

- (void)plvLCBasePlayerSkinViewMoreButtonClicked:(PLVLCBasePlayerSkinView *)skinView{
    [self.moreView showMoreViewOnSuperview:skinView.superview];
}

- (void)plvLCBasePlayerSkinViewPlayButtonClicked:(PLVLCBasePlayerSkinView *)skinView wannaPlay:(BOOL)wannaPlay{
    if (wannaPlay) {
        [self.playerPresenter resumePlay];
    }else{
        [self.playerPresenter pausePlay];
    }
}

- (void)plvLCBasePlayerSkinViewRefreshButtonClicked:(PLVLCBasePlayerSkinView *)skinView{
    [self.playerPresenter resumePlay];
}

- (void)plvLCBasePlayerSkinViewFloatViewShowButtonClicked:(PLVLCBasePlayerSkinView *)skinView userWannaShowFloatView:(BOOL)wannaShow{
    if (!self.inRTCRoom) {
        [self.floatView showFloatView:wannaShow userOperat:YES];
    }else{
        if ([self.delegate respondsToSelector:@selector(plvLCMediaAreaView:userWannaLinkMicAreaViewShow:onSkinView:)]) {
            [self.delegate plvLCMediaAreaView:self userWannaLinkMicAreaViewShow:wannaShow onSkinView:skinView];
        }
    }
}

- (void)plvLCBasePlayerSkinViewFullScreenOpenButtonClicked:(PLVLCBasePlayerSkinView *)skinView{
    [PLVFdUtil changeDeviceOrientation:UIDeviceOrientationLandscapeLeft];
}

/// 询问是否有其他视图处理此次触摸事件
- (BOOL)plvLCBasePlayerSkinView:(PLVLCBasePlayerSkinView *)skinView askHandlerForTouchPointOnSkinView:(CGPoint)point{
    if ([PLVLCBasePlayerSkinView checkView:self.canvasView.playCanvasButton canBeHandlerForTouchPoint:point onSkinView:skinView]){
        /// 判断触摸事件是否应由 ‘音频模式按钮’ 处理
        return YES;
    }else{
        BOOL externalViewHandle = NO;
        /// 询问外部视图
        if ([self.delegate respondsToSelector:@selector(plvLCMediaAreaView:askHandlerForTouchPoint:onSkinView:)]) {
            externalViewHandle = [self.delegate plvLCMediaAreaView:self askHandlerForTouchPoint:point onSkinView:skinView];
        }
        return externalViewHandle;
    }
}

- (void)plvLCBasePlayerSkinView:(PLVLCBasePlayerSkinView *)skinView didChangedSkinShowStatus:(BOOL)skinShow{
    if ([self.delegate respondsToSelector:@selector(plvLCMediaAreaView:didChangedSkinShowStatus:forSkinView:)]) {
        [self.delegate plvLCMediaAreaView:self didChangedSkinShowStatus:skinShow forSkinView:skinView];
    }
}

- (void)plvLCBasePlayerSkinView:(PLVLCBasePlayerSkinView *)skinView sliderDragEnd:(CGFloat)currentSliderProgress{
    NSTimeInterval currentTime = self.playerPresenter.duration * currentSliderProgress;
    
    // 拖动进度条后，同步当前进度时间
    [self playerPresenter:self.playerPresenter downloadProgress:0 playedProgress:currentSliderProgress playedTimeString:[PLVFdUtil secondsToString:currentTime] durationTimeString:[PLVFdUtil secondsToString:self.playerPresenter.duration]];
    [self.playerPresenter seekLivePlaybackToTime:currentTime];
}

#pragma mark PLVLCFloatViewDelegate
/// 悬浮视图被点击
- (UIView *)plvLCFloatViewDidTap:(PLVLCMediaFloatView *)floatView externalView:(nonnull UIView *)externalView{
    UIView * willMoveView = self.contentBackgroudView.subviews.firstObject;
    if (externalView) {
        [self.contentBackgroudView addSubview:externalView];
        externalView.frame = self.contentBackgroudView.bounds;
        externalView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return willMoveView;
}

- (void)plvLCFloatViewCloseButtonClicked:(PLVLCMediaFloatView *)floatView{
    [self.skinView showFloatViewShowButtonTipsLabelAnimation:YES];
}

- (void)plvLCFloatView:(PLVLCMediaFloatView *)floatView floatViewSwitchToShow:(BOOL)show{
    [self.skinView setFloatViewButtonWithShowStatus:show];
    if ([self.delegate respondsToSelector:@selector(plvLCMediaAreaView:floatViewSwitchToShow:)]) {
        [self.delegate plvLCMediaAreaView:self floatViewSwitchToShow:show];
    }
}

#pragma mark PLVLCMediaMoreViewDelegate
- (void)plvLCMediaMoreView:(PLVLCMediaMoreView *)moreView optionItemSelected:(PLVLCMediaMoreModel *)model{
    if ([model.optionTitle isEqualToString:PLVLCMediaAreaView_Data_ModeOptionTitle]) {
        // 用户点选了”模式“中的选项
        self.logoView.hidden = model.selectedIndex != 0;
        [self.canvasView switchTypeTo:(model.selectedIndex == 0 ? PLVLCMediaPlayerCanvasViewType_Video : PLVLCMediaPlayerCanvasViewType_Audio)];
        [self.playerPresenter switchLiveToAudioMode:(model.selectedIndex == 0 ? NO : YES)];
    } else if ([model.optionTitle isEqualToString:PLVLCMediaAreaView_Data_QualityOptionTitle]) {
        // 用户点选了”视频质量“中的选项
        [self.playerPresenter switchLiveToCodeRate:model.currentSelectedItemString];
    } else if ([model.optionTitle isEqualToString:PLVLCMediaAreaView_Data_RouteOptionTitle]) {
        // 用户点选了”线路“中的选项
        [self.playerPresenter switchLiveToLineIndex:model.selectedIndex];
    } else if ([model.optionTitle isEqualToString:PLVLCMediaAreaView_Data_SpeedOptionTitle]) {
        // 用户点选了”倍速“中的选项
        CGFloat speed = [[model.currentSelectedItemString substringToIndex:model.currentSelectedItemString.length - 1] floatValue];
        [self.playerPresenter switchLivePlaybackSpeedRate:speed];
    }
}

#pragma mark PLVLCMediaPlayerCanvasViewDelegate
/// ‘播放画面’按钮被点击
- (void)plvLCMediaPlayerCanvasViewPlayCanvasButtonClicked:(PLVLCMediaPlayerCanvasView *)playerCanvasView{
    // 更新数据
    PLVLCMediaMoreModel * modeModel = [self.moreView getMoreModelAtIndex:0];
    modeModel.selectedIndex = 0;
    [self.moreView refreshTableView];
    
    // 切换为视频模式
    [self.playerPresenter switchLiveToAudioMode:NO];
}

#pragma mark PLVPPTViewDelegate
/// PPT获取刷新的延迟时间
- (unsigned int)plvPPTViewGetPPTRefreshDelayTime:(PLVPPTView *)pptView{
    return self.inRTCRoom ? 0 : 5000;
}

/// PPT视图 PPT位置需切换
- (void)plvPPTView:(PLVPPTView *)pptView changePPTPosition:(BOOL)pptToMain{
    if (self.videoType == PLVChannelVideoType_Live){ // 视频类型为 直播
        /// 仅在 非观看RTC场景下 执行 (观看RTC场景下，由 PLVLCLinkMicAreaView 自行处理)
        if (self.inRTCRoom == NO) {
            if (pptToMain != self.pptOnMainSite) {
                [self.floatView triggerViewExchangeEvent];
            }
        }
    } else if (self.videoType == PLVChannelVideoType_Playback) { // 视频类型为 直播回放
        if (pptToMain != self.pptOnMainSite) {
            [self.floatView triggerViewExchangeEvent];
        }
    }
}

/// [回放场景] PPT视图 需要获取视频播放器的当前播放时间点
- (NSTimeInterval)plvPPTViewGetPlayerCurrentTime:(PLVPPTView *)pptView{
    return self.playerPresenter.currentPlaybackTime * 1000;
}

#pragma mark PLVPlayerPresenterDelegate
// 通用
/// 播放器 ‘正在播放状态’ 发生改变
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter playerPlayingStateDidChanged:(BOOL)playing{
    [self.skinView setPlayButtonWithPlaying:playing];
    if ([self.delegate respondsToSelector:@selector(plvLCMediaAreaView:playerPlayingDidChange:)]) {
        [self.delegate plvLCMediaAreaView:self playerPlayingDidChange:playing];
    }
}

/// 播放器 发生错误
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter loadPlayerFailureWithMessage:(NSString *)errorMessage{
    [PLVLCUtils showHUDWithTitle:@"" detail:errorMessage view:[PLVFdUtil getCurrentViewController].view];
}

/// 播放器 ‘视频大小’ 发生改变
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter videoSizeChange:(CGSize)videoSize{
    self.canvasView.videoSize = videoSize;
}

/// 播放器 ‘SEI信息’ 发生改变
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter seiDidChange:(long)timeStamp newTimeStamp:(long)newTimeStamp{
    [self.pptView setSEIDataWithNewTimestamp:newTimeStamp];
}

/// 播放器 ‘频道信息’ 发生改变
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter channelInfoDidUpdated:(PLVChannelInfoModel *)channelInfo{
    /// 设置 跑马灯
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    [self setupMarquee:roomData.channelInfo customNick:roomData.roomUser.viewerName];
}

// 直播相关
/// 直播 ‘流状态’ 更新
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter streamStateUpdate:(PLVChannelLiveStreamState)newestStreamState streamStateDidChanged:(BOOL)streamStateDidChanged{
    /// 根据直播流状态，刷新 ‘画布视图’
    [self.canvasView refreshCanvasViewWithStreamState:newestStreamState];
    
    if (newestStreamState == PLVChannelLiveStreamState_Live) {
        if (!self.channelWatchNoDelay && self.inLinkMic == NO) {
            [self.floatView showFloatView:YES userOperat:NO];
            [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_Living_CDN];
            
            /// 确保 直播状态变更为‘直播中’时，PPT 位于主屏
            if (streamStateDidChanged && (self.pptView.mainSpeakerPPTOnMain != self.pptOnMainSite)) {
                [self.floatView triggerViewExchangeEvent];
            }
        }
        /// 设置播放器logo
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        [self setupPlayerLogoImage:roomData.channelInfo];
    }else if (newestStreamState == PLVChannelLiveStreamState_Stop ||
              newestStreamState == PLVChannelLiveStreamState_End){
        /// 确保 直播状态变更为‘直播暂停’、‘直播结束’时，播放器画面 位于主屏
        if (self.pptOnMainSite) {
            [self.floatView triggerViewExchangeEvent];
        }
        [self.logoView removeFromSuperview];
        [self.floatView forceShowFloatView:NO];
        [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_None];
    } else if(newestStreamState == PLVChannelLiveStreamState_Unknown){
        /// ’未知‘状态下，保持原样
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCMediaAreaView:livePlayerStateDidChange:)]) {
        [self.delegate plvLCMediaAreaView:self livePlayerStateDidChange:newestStreamState];
    }
}

/// 直播播放器 ‘码率可选项、当前码率、线路可选数、当前线路‘ 发生改变
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter codeRateOptions:(NSArray <NSString *> *)codeRateOptions currentCodeRate:(NSString *)currentCodeRate lineNum:(NSInteger)lineNum currentLineIndex:(NSInteger)currentLineIndex{
    // 更新 ‘更多视图’
    [self updateMoreviewWithData];
}

/// 直播播放器 需获知外部 ‘当前是否正在连麦’
- (BOOL)playerPresenterGetInLinkMic:(PLVPlayerPresenter *)playerPresenter{
    return self.inLinkMic;
}

/// [无延迟直播] 无延迟直播 ‘开始结束状态’ 发生改变
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter noDelayLiveStartUpdate:(BOOL)noDelayLiveStart noDelayLiveStartDidChanged:(BOOL)noDelayLiveStartDidChanged{
    if (noDelayLiveStartDidChanged) {
        if ([self.delegate respondsToSelector:@selector(plvLCMediaAreaView:noDelayLiveStartUpdate:)]) {
            [self.delegate plvLCMediaAreaView:self noDelayLiveStartUpdate:noDelayLiveStart];
        }
    }
}

// 非直播相关
- (void)playerPresenter:(PLVPlayerPresenter *)playerPresenter downloadProgress:(CGFloat)downloadProgress playedProgress:(CGFloat)playedProgress playedTimeString:(NSString *)playedTimeString durationTimeString:(NSString *)durationTimeString{
    [self.skinView setProgressWithCachedProgress:downloadProgress playedProgress:playedProgress durationTime:playerPresenter.duration currentTimeString:playedTimeString durationString:durationTimeString];
    
    if ([self.delegate respondsToSelector:@selector(plvLCMediaAreaView:progressUpdateWithCachedProgress:playedProgress:durationTime:currentTimeString:durationString:)]) {
        [self.delegate plvLCMediaAreaView:self progressUpdateWithCachedProgress:downloadProgress playedProgress:playedProgress durationTime:playerPresenter.duration currentTimeString:playedTimeString durationString:durationTimeString];
    }
}

#pragma mark - 播放器LOGO
- (void)setupPlayerLogoImage:(PLVChannelInfoModel *)channel {
    if ([PLVFdUtil checkStringUseable:channel.logoImageUrl]) {
        PLVPlayerLogoParam *logoParam = [[PLVPlayerLogoParam alloc] init];
        logoParam.logoUrl = channel.logoImageUrl;
        logoParam.position = channel.logoPosition;
        logoParam.logoAlpha = channel.logoOpacity;
        logoParam.logoWidthScale = 0.14;
        logoParam.logoHeightScale = 0.25;

        PLVPlayerLogoView *playerLogo = [[PLVPlayerLogoView alloc] init];
        [playerLogo insertLogoWithParam:logoParam];
        [self addPlayerLogo:playerLogo];
    }
}

- (void)addPlayerLogo:(PLVPlayerLogoView *)logo {
    if (self.canvasView) {
        self.logoView = logo;
        [logo addAtView:self.canvasView];
    }
}

@end
