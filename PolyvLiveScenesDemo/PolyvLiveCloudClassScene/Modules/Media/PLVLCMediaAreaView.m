//
//  PLVLCMediaAreaView.m
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/9/15.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCMediaAreaView.h"

#import "PLVLCUtils.h"
#import "PLVLCMediaPlayerCanvasView.h"
#import "PLVLCMediaMoreView.h"

// 模块
#import "PLVPPTView.h"
#import "ZJZDanMu.h"

#import "PLVEmoticonManager.h"

#import <PolyvFoundationSDK/PolyvFoundationSDK.h>

static NSString *const PLVLCMediaAreaView_Data_ModeOptionTitle = @"模式";
static NSString *const PLVLCMediaAreaView_Data_QualityOptionTitle = @"视频质量";
static NSString *const PLVLCMediaAreaView_Data_RouteOptionTitle = @"线路";
static NSString *const PLVLCMediaAreaView_Data_SpeedOptionTitle = @"倍速";

@interface PLVLCMediaAreaView () <PLVLCFloatViewDelegate,PLVPPTViewDelegate,PLVLCMediaMoreViewDelegate,PLVLivePlayerPresenterDelegate,PLVPlaybackPlayerPresenterDelegate, PLVLCMediaPlayerCanvasViewDelegate>

#pragma mark 数据
@property (nonatomic, strong) PLVLiveRoomData * roomData; // 频道信息

#pragma mark 状态
@property (nonatomic, assign, readonly) BOOL inLinkMic;
@property (nonatomic, assign) PLVLCMediaAreaViewPlayerType playerType;
@property (nonatomic, assign, readonly) BOOL pptOnMainSite;     // PPT当前是否处于主屏 (此属性仅适合判断PPT是否在主屏，不适合判断其他视图所处位置)
@property (nonatomic, assign) LivePlayerState currentLiveState; // 当前播放器直播状态

#pragma mark 模块
@property (nonatomic, strong) PLVBasePlayerPresenter * presenter;  // 播放器 功能模块
@property (nonatomic, readonly, nullable) PLVLivePlayerPresenter * livePresenter;             // 直播播放器 功能模块 (只读；是对 presenter 的封装；仅直播场景下不为nil)
@property (nonatomic, readonly, nullable) PLVPlaybackPlayerPresenter * livePlaybackPresenter; // 直播回放播放器 功能模块 (只读；是对 presenter 的封装；仅直播回放场景下不为nil)
@property (nonatomic, strong) PLVPPTView * pptView;               // PPT 功能模块
@property (nonatomic, strong) PLVVideoMarquee * videoMarquee;     // 视频跑马灯

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
@property (nonatomic, strong) ZJZDanMu *danmuView;  // 弹幕 (用于显示 ‘聊天室消息’)
@property (nonatomic, strong) UIView * marqueeView; // 跑马灯 (用于显示 ‘用户昵称’，规避非法录屏)

@end

@implementation PLVLCMediaAreaView

#pragma mark - [ Life Period ]
- (void)dealloc {
    [self.presenter destroy];
    NSLog(@"%s", __FUNCTION__);
}

- (instancetype)initWithRoomData:(id)roomData{
    if (self = [super initWithFrame:CGRectZero]) {
        self.roomData = roomData;

        [self setupData];
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
- (void)refreshUIInfo{
    [self.skinView setTitleLabelWithText:self.roomData.channelMenuInfo.name];
    [self.skinView setPlayTimesLabelWithTimes:self.roomData.channelMenuInfo.pageView.integerValue];
}

- (void)switchPlayerTypeTo:(PLVLCMediaAreaViewPlayerType)toType{
    if (self.playerType == toType) {
        NSLog(@"PLVLCMediaAreaView - switchPlayerTypeTo failed, type is same");
        return;
    }
    
    if (toType == PLVLCMediaAreaViewPlayerType_RTCPlayer) {
        /// 确保 PPT 位于主屏
        if (!self.pptOnMainSite) { [self.floatView triggerViewExchangeEvent]; }
        
        /// 直播播放器清理
        self.livePresenter.linkMic = YES;
        [self.livePresenter cleanAllPlayers];
        
        /// 隐藏 floatView
        /// userOperat:YES 表示代表用户强制执行
        [self.floatView showFloatView:NO userOperat:YES];
        
        /// 竖屏皮肤视图
        [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_InLinkMic];
    }else{
        if (self.roomData.liveState == PLVLiveStreamStateLive) {
            // 直播中
            /// 出现 floatView
            /// 其中 userOperat:YES 表示 ’代表用户去执行’，即强制执行
            [self.floatView showFloatView:YES userOperat:YES];
            
            /// 恢复直播播放器
            self.livePresenter.linkMic = NO;
            [self.livePresenter reloadLive:^(NSError *error) {
                
            }];
            
            /// 竖屏皮肤视图
            [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_Living];
        }else{
            // 非直播中
            /// 确保 ‘播放器画面’ 位于主屏
            if (self.pptOnMainSite) { [self.floatView triggerViewExchangeEvent]; }
            
            /// 竖屏皮肤视图
            [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_None];
        }
    }
    
    self.playerType = toType;
}

- (void)displayContentView:(UIView *)contentView{
    if (contentView && [contentView isKindOfClass:UIView.class]) {
        [self contentBackgroundViewDisplaySubview:contentView];
    }else{
        NSLog(@"PLVLCMediaAreaView - displayExternalView failed, view is illegal : %@",contentView);
    }
}

- (UIView *)getContentViewForExchange{
    if (self.playerType == PLVLCMediaAreaViewPlayerType_RTCPlayer) {
        UIView * currentContentView = self.contentBackgroudView.subviews.firstObject;
        if (currentContentView) {
            return currentContentView;
        }else{
            NSLog(@"PLVLCMediaAreaView - getViewForExchange failed, currentContentView is illegal : %@",currentContentView);
        }
    }else{
        NSLog(@"PLVLCMediaAreaView - getViewForExchange failed, this method should been call in LinkMic, but current playerType is %lu",(unsigned long)self.playerType);
    }
    return nil;
}


#pragma mark - [ Private Methods ]
- (void)setupData{
    self.playerType = PLVLCMediaAreaViewPlayerType_CDNPlayer;
}

- (void)setupUI{
    self.backgroundColor = UIColorFromRGB(@"2B3045");
    
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
    if (self.roomData.videoType == PLVWatchRoomVideoType_Live) { // 视频类型为 直播
        /// 直播 模块
        self.presenter = [[PLVLivePlayerPresenter alloc] initWithRoomData:self.roomData];
        self.livePresenter.view = self;
        [self.livePresenter setupPlayerWithDisplayView:self.canvasView.playerSuperview]; /// TODO 改外部添加
        
        /// PPT模块
        [self.floatView displayExternalView:self.pptView]; /// 无直播时的默认状态，是‘PPT画面’位于副屏(悬浮小窗)
        
    }else if (self.roomData.videoType == PLVWatchRoomVideoType_LivePlayback){ // 视频类型为 直播回放
        /// 直播回放 模块
        self.presenter = [[PLVPlaybackPlayerPresenter alloc] initWithRoomData:self.roomData];
        self.livePlaybackPresenter.view = self;
        [self.livePlaybackPresenter setupPlayerWithDisplayView:self.canvasView.playerSuperview]; /// TODO 改外部添加
        
        /// PPT模块
        [self.floatView displayExternalView:self.pptView]; /// 默认状态，是‘PPT画面’位于副屏(悬浮小窗)
        [self.floatView showFloatView:YES userOperat:NO];
        [self.pptView pptStart:self.roomData.vid];
        
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
    if (self.roomData.videoType == PLVWatchRoomVideoType_Live) { // 视频类型为 直播
        PLVLCMediaMoreModel * modeModel = [PLVLCMediaMoreModel modelWithOptionTitle:PLVLCMediaAreaView_Data_ModeOptionTitle optionItemsArray:@[@"播放画面",@"仅听声音"]];
        returnArray = @[modeModel];
    }else if (self.roomData.videoType == PLVWatchRoomVideoType_LivePlayback){ // 视频类型为 直播回放
        PLVLCMediaMoreModel * speedModel = [PLVLCMediaMoreModel modelWithOptionTitle:PLVLCMediaAreaView_Data_SpeedOptionTitle optionItemsArray:@[@"0.5x",@"1.0x",@"1.5x",@"2.0x"] selectedIndex:1];
        speedModel.optionSpecifiedWidth = 50.0;
        returnArray = @[speedModel];
    }
    return returnArray;
}

- (void)updateMoreviewWithData{
    // 视频质量选项数据
    PLVLCMediaMoreModel * qualityModel = [PLVLCMediaMoreModel modelWithOptionTitle:PLVLCMediaAreaView_Data_QualityOptionTitle optionItemsArray:self.roomData.codeRateItems];
    [qualityModel setSelectedIndexWithOptionItemString:self.roomData.curCodeRate];
    
    // 线路选项数据
    NSMutableArray * routeArray = [[NSMutableArray alloc] init];
    for (int i = 1; i <= self.roomData.lines; i++) {
        NSString * route = [NSString stringWithFormat:@"线路%d",i];
        [routeArray addObject:route];
    }
    PLVLCMediaMoreModel * routeModel = [PLVLCMediaMoreModel modelWithOptionTitle:PLVLCMediaAreaView_Data_RouteOptionTitle optionItemsArray:routeArray selectedIndex:self.roomData.curLine];
    
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
- (void)setupMarquee:(PLVLiveVideoChannel *)channel customNick:(NSString *)customNick  {
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

- (void)handleMarquee:(PLVLiveVideoChannel *)channel customNick:(NSString *)customNick completion:(void (^)(PLVMarqueeModel *model, NSError *error))completion {
    switch (channel.marqueeType) {
        case PLVLiveMarqueeTypeNick:
            if (customNick) {
                channel.marquee = customNick;
            } else {
                channel.marquee = @"自定义昵称";
            }
        case PLVLiveMarqueeTypeFixed: {
            float alpha = channel.marqueeOpacity.floatValue/100.0;
            PLVMarqueeModel *model = [PLVMarqueeModel marqueeModelWithContent:channel.marquee fontSize:channel.marqueeFontSize.unsignedIntegerValue fontColor:channel.marqueeFontColor alpha:alpha autoZoom:channel.marqueeAutoZoomEnabled];
            completion(model, nil);
        } break;
        case PLVLiveMarqueeTypeURL: {
            if (channel.marquee) {
                [PLVLiveVideoAPI loadCustomMarquee:[NSURL URLWithString:channel.marquee] withChannelId:channel.channelId.unsignedIntegerValue userId:channel.userId completion:^(BOOL valid, NSDictionary *marqueeDict) {
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
- (PLVLivePlayerPresenter *)livePresenter{
    return (PLVLivePlayerPresenter *)_presenter;
}

- (PLVPlaybackPlayerPresenter *)livePlaybackPresenter{
    return (PLVPlaybackPlayerPresenter *)_presenter;
}

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

- (ZJZDanMu *)danmuView {
    if (!_danmuView) {
        _danmuView = [[ZJZDanMu alloc] init];
        _danmuView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _danmuView.hidden = YES;
        _danmuView.userInteractionEnabled = NO;
    }
    return _danmuView;
}

- (PLVLCMediaPlayerSkinView *)skinView{
    if (!_skinView) {
        PLVLCBasePlayerSkinViewType type = (self.roomData.videoType == PLVWatchRoomVideoType_Live ? PLVLCBasePlayerSkinViewType_Live : PLVLCBasePlayerSkinViewType_Playback);
        _skinView = [[PLVLCMediaPlayerSkinView alloc] initWithType:type];
        _skinView.baseDelegate = self;
    }
    return _skinView;
}

- (PLVLCMediaFloatView *)floatView{
    if (!_floatView) {
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
    if (!_pptView) {
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
        [PLVFdUtil showAlertWithTitle:@"确认退出直播间？" message:nil viewController:[PLVLiveUtil getCurrentViewController] cancelActionTitle:@"按错了" cancelActionStyle:UIAlertActionStyleDefault cancelActionBlock:nil confirmActionTitle:@"退出" confirmActionStyle:UIAlertActionStyleDestructive confirmActionBlock:^(UIAlertAction * _Nonnull action) {
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
        if (self.roomData.videoType == PLVWatchRoomVideoType_Live) { // 视频类型为 直播
            [self.livePresenter playLive];
        }else if (self.roomData.videoType == PLVWatchRoomVideoType_LivePlayback){ // 视频类型为 直播回放
            [self.livePlaybackPresenter play];
        }
    }else{
        if (self.roomData.videoType == PLVWatchRoomVideoType_Live) { // 视频类型为 直播
            [self.livePresenter pauseLive];
        }else if (self.roomData.videoType == PLVWatchRoomVideoType_LivePlayback){ // 视频类型为 直播回放
            [self.livePlaybackPresenter pause];
        }
    }
}

- (void)plvLCBasePlayerSkinViewRefreshButtonClicked:(PLVLCBasePlayerSkinView *)skinView{
    [self.livePresenter reloadLive:^(NSError *error) {
        
    }];
}

- (void)plvLCBasePlayerSkinViewFloatViewShowButtonClicked:(PLVLCBasePlayerSkinView *)skinView userWannaShowFloatView:(BOOL)wannaShow{
    if (!self.inLinkMic) {
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
    NSTimeInterval currentTime = self.roomData.duration * currentSliderProgress;
    
    // 拖动进度条后，同步当前进度时间
    [self updateDowloadProgress:0 playedProgress:currentSliderProgress
            currentPlaybackTime:[PLVFdUtil secondsToString:currentTime]
                       duration:[PLVFdUtil secondsToString:self.roomData.duration]];
    [self.livePlaybackPresenter seek:currentTime];
}

#pragma mark PLVLCFloatViewDelegate
/// 悬浮视图被点击
- (UIView *)plvLCFloatViewDidTap:(PLVLCMediaFloatView *)floatView externalView:(nonnull UIView *)externalView{
    UIView * willMoveView;
    if (!self.inLinkMic) {
        // 不处于 ‘连麦中’ 状态
        willMoveView = self.contentBackgroudView.subviews.firstObject;
        if (externalView) {
            [self.contentBackgroudView addSubview:externalView];
            externalView.frame = self.contentBackgroudView.bounds;
            externalView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        }
        return willMoveView;
    }else{
        // 处于 ‘连麦中’ 状态
        NSLog(@"PLVLCMediaAreaView - is not in linkmic, view exchange should not be executed");
        return nil;
    }
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
        [self.canvasView switchTypeTo:(model.selectedIndex == 0 ? PLVLCMediaPlayerCanvasViewType_Video : PLVLCMediaPlayerCanvasViewType_Audio)];
        [self.livePresenter switchAudioMode:(model.selectedIndex == 0 ? NO : YES)];
    } else if ([model.optionTitle isEqualToString:PLVLCMediaAreaView_Data_QualityOptionTitle]) {
        // 用户点选了”视频质量“中的选项
        [self.livePresenter switchPlayCodeRate:model.currentSelectedItemString completion:^(NSError *error) {
            
        }];
    } else if ([model.optionTitle isEqualToString:PLVLCMediaAreaView_Data_RouteOptionTitle]) {
        // 用户点选了”线路“中的选项
        [self.livePresenter switchPlayLine:model.selectedIndex completion:^(NSError *error) {
            
        }];
    } else if ([model.optionTitle isEqualToString:PLVLCMediaAreaView_Data_SpeedOptionTitle]) {
        // 用户点选了”倍速“中的选项
        CGFloat speed = [[model.currentSelectedItemString substringToIndex:model.currentSelectedItemString.length - 1] floatValue];
        [self.livePlaybackPresenter speedRate:speed];
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
    [self.livePresenter switchAudioMode:NO];
}

#pragma mark PLVPPTViewDelegate
/// PPT获取刷新的延迟时间
- (unsigned int)plvPPTViewGetPPTRefreshDelayTime:(PLVPPTView *)pptView{
    return self.inLinkMic ? 0 : 5000;
}

/// [回放场景] PPT视图 需要获取视频播放器的当前播放时间点
- (NSTimeInterval)plvPPTViewGetPlayerCurrentTime:(PLVPPTView *)pptView{
    return self.roomData.currentTime * 1000;
}

/// [回放场景] PPT视图 讲师发起PPT位置切换
- (void)plvPPTView:(PLVPPTView *)pptView changePPTPosition:(BOOL)status{
    // @param status PPT是否需要切换至主窗口 (YES:PPT需要切至主窗口 NO:PPT需要切至小窗，视频需要切至主窗口)
    if (status != self.pptOnMainSite) {
        [self.floatView triggerViewExchangeEvent];
    }
}

#pragma mark PLVPlayerPresenterDelegate
- (void)presenter:(PLVBasePlayerPresenter *)presenter mainPlayerSeiDidChange:(long)timeStamp newTimeStamp:(long)newTimeStamp{
    [self.pptView setSEIDataWithNewTimestamp:newTimeStamp];
}

- (void)presenter:(PLVBasePlayerPresenter *)presenter videoSizeChange:(CGSize)videoSize{
    self.canvasView.videoSize = videoSize;
}

/// 频道信息更新
- (void)presenterChannelInfoChanged:(PLVBasePlayerPresenter *)presenter{
    // 设置 跑马灯
    [self setupMarquee:self.roomData.channelInfo customNick:self.roomData.channel.watchUser.viewerName];
}

#pragma mark PLVLivePlayerPresenterDelegate
- (void)presenter:(PLVLivePlayerPresenter *)presenter livePlayerStateDidChange:(LivePlayerState)livePlayerState{
    BOOL stateChange = (self.currentLiveState != livePlayerState);
    
    // 设置休息一会视图显示/隐藏
    self.canvasView.restImageView.hidden = livePlayerState != LivePlayerStatePause;
    
    if (livePlayerState == LivePlayerStateLiving) {
        if (self.inLinkMic == NO) {
            [self.floatView showFloatView:YES userOperat:NO];
            [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_Living];
            
            /// 确保 直播状态变更为‘直播中’时，PPT 位于主屏
            if (stateChange && !self.pptOnMainSite) { [self.floatView triggerViewExchangeEvent]; }
        }
    }else if (livePlayerState == LivePlayerStatePause || livePlayerState == LivePlayerStateUnknown || livePlayerState == LivePlayerStateEnd){
        /// 确保 直播状态变更为‘未知’、‘直播暂停’、‘直播结束’时，播放器画面 位于主屏
        if (self.pptOnMainSite) {
            [self.floatView triggerViewExchangeEvent];
        }
        [self.floatView forceShowFloatView:NO];
        [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_None];
    }else{
        [self.floatView forceShowFloatView:NO];
        [self.skinView switchSkinViewLiveStatusTo:PLVLCBasePlayerSkinViewLiveStatus_None];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCMediaAreaView:livePlayerStateDidChange:)]) {
        [self.delegate plvLCMediaAreaView:self livePlayerStateDidChange:livePlayerState];
    }
    self.currentLiveState = livePlayerState;
}

- (void)presenterPlayingChanged:(PLVLivePlayerPresenter *)presenter{
    [self.skinView setPlayButtonWithPlaying:self.roomData.playing];
    if ([self.delegate respondsToSelector:@selector(plvLCMediaAreaView:livePlayerPlayingDidChange:)]) {
        [self.delegate plvLCMediaAreaView:self livePlayerPlayingDidChange:self.roomData.playing];
    }
}

- (void)presenter:(PLVLivePlayerPresenter *)presenter cdnPlayerPPTSiteExchange:(BOOL)wannaCDNPlayerOnMainSite{
    // 仅在 非连麦场景下 执行
    if (self.inLinkMic == NO) {
        BOOL shouldExchange = (wannaCDNPlayerOnMainSite == self.pptOnMainSite);
        if (shouldExchange) {
            [self.floatView triggerViewExchangeEvent];
        }
    }
}

/// 频道播放选项信息更新
- (void)presenterChannelPlayOptionInfoDidUpdate:(PLVLivePlayerPresenter *)presenter{
    // 更新 ‘更多视图’
    [self updateMoreviewWithData];
}

#pragma mark PLVPlaybackPlayerPresenterDelegate
/// 更新回放进度
- (void)updateDowloadProgress:(CGFloat)dowloadProgress playedProgress:(CGFloat)playedProgress currentPlaybackTime:(NSString *)currentPlaybackTime duration:(NSString *)duration{
    [self.skinView setProgressWithCachedProgress:dowloadProgress playedProgress:playedProgress durationTime:self.roomData.duration currentTimeString:currentPlaybackTime durationString:duration];
    
    if ([self.delegate respondsToSelector:@selector(plvLCMediaAreaView:progressUpdateWithCachedProgress:playedProgress:durationTime:currentTimeString:durationString:)]) {
        [self.delegate plvLCMediaAreaView:self progressUpdateWithCachedProgress:dowloadProgress playedProgress:playedProgress durationTime:self.roomData.duration currentTimeString:currentPlaybackTime durationString:duration];
    }
}

- (void)presenter:(PLVPlaybackPlayerPresenter *)presenter playing:(BOOL)playing{
    [self.skinView setPlayButtonWithPlaying:playing];
    if ([self.delegate respondsToSelector:@selector(plvLCMediaAreaView:playbackPlayerPlayingDidChange:)]) {
        [self.delegate plvLCMediaAreaView:self playbackPlayerPlayingDidChange:playing];
    }
}

- (void)presenter:(PLVBasePlayerPresenter *)presenter mainPlayerPlaybackDidFinish:(NSDictionary *)dataInfo {
    // 播放完成
    [self updateDowloadProgress:0 playedProgress:1
            currentPlaybackTime:[PLVFdUtil secondsToString:self.roomData.duration]
                       duration:[PLVFdUtil secondsToString:self.roomData.duration]];
}

@end
