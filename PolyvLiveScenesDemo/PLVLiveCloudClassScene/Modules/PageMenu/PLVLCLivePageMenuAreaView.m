//
//  PLVLCMenuAreaView.m
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/7/23.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCLivePageMenuAreaView.h"
#import "PLVLCPageController.h"
#import "PLVLCQuizViewController.h"
#import "PLVLCTuwenViewController.h"
#import "PLVLCTextViewController.h"
#import "PLVLCQAViewController.h"
#import "PLVLCIframeViewController.h"
#import "PLVLCPlaybackListViewController.h"
#import "PLVLCSectionViewController.h"
#import "PLVLCBuyViewController.h"
#import "PLVLCNoNetworkDescViewController.h"
#import "PLVLCOnlineListViewController.h"
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"
#import "PLVLCChatroomPlaybackViewModel.h"
#import "PLVLCMultiMeetingViewController.h"
#import <PLVLiveScenesSDK/PLVLiveVideoChannelMenuInfo.h>

PLVLCLivePageMenuType PLVLCMenuTypeWithMenuTypeString(NSString *menuString) {
    if (!menuString || ![menuString isKindOfClass:[NSString class]] || menuString.length == 0) {
        return PLVLCLivePageMenuTypeUnknown;
    }
    
    if ([menuString isEqualToString:@"desc"]) {
        return PLVLCLivePageMenuTypeDesc;
    } else if ([menuString isEqualToString:@"chat"]) {
        return PLVLCLivePageMenuTypeChat;
    } else if ([menuString isEqualToString:@"quiz"]) {
        return PLVLCLivePageMenuTypeQuiz;
    } else if ([menuString isEqualToString:@"tuwen"]) {
        return PLVLCLivePageMenuTypeTuwen;
    } else if ([menuString isEqualToString:@"text"]) {
        return PLVLCLivePageMenuTypeText;
    } else if ([menuString isEqualToString:@"qa"]) {
        return PLVLCLivePageMenuTypeQA;
    } else if ([menuString isEqualToString:@"iframe"]) {
        return PLVLCLivePageMenuTypeIframe;
    } else if ([menuString isEqualToString:@"buy"]) {
        return PLVLCLivePageMenuTypeBuy;
    } else if ([menuString isEqualToString:@"members"]) {
        return PLVLCLivePageMenuTypeMembers;
    }
    return PLVLCLivePageMenuTypeUnknown;
}

@interface PLVLCLivePageMenuAreaView ()<
PLVLCTuwenDelegate,
PLVLCBuyViewControllerDelegate,
PLVLCSectionViewControllerDelegate,
PLVLCChatViewControllerDelegate,
PLVLCOnlineListViewControllerDelegate,
PLVRoomDataManagerProtocol
>

@property (nonatomic, strong) PLVLCPageController *pageController;
/// 直播介绍页，直播状态更改时需改变其 UI 文本
@property (nonatomic, strong) PLVLCDescViewController *descVctrl;
/// 无网络播放离线缓存视频时的直播介绍页
@property (nonatomic, strong) PLVLCNoNetworkDescViewController *noNetworkDescVctrl;
/// 提问咨询页
@property (nonatomic, strong) PLVLCQuizViewController *quizVctrl;
/// 回放列表
@property (nonatomic, strong) PLVLCPlaybackListViewController *playbackListVctrl;
/// 章节列表页
@property (nonatomic, strong) PLVLCSectionViewController *sectionVctrl;
/// 商品列表页
@property (nonatomic, strong) PLVLCBuyViewController *productVctrl;
/// 图文直播页
@property (nonatomic, strong) PLVLCTuwenViewController *tuwenVctrl;
/// 问答直播页
@property (nonatomic ,strong) PLVLCQAViewController *qaVctrl;

/// 成员列表页
@property (nonatomic, strong) PLVLCOnlineListViewController *onlineListVctrl;

@property (nonatomic, weak) UIViewController *liveRoom;

@property (nonatomic, weak) PLVLCChatroomPlaybackViewModel *playbackViewModel;

@property (nonatomic, assign) BOOL showCommodityMenu;

@end

@implementation PLVLCLivePageMenuAreaView

#pragma mark - Life Cycle

- (void)layoutSubviews {
    [super layoutSubviews];
    self.pageController.view.frame = self.bounds;
}

#pragma mark - Public Method

- (instancetype)initWithLiveRoom:(UIViewController *)liveRoom {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0x20/255.0 green:0x21/255.0 blue:0x27/255.0 alpha:1];
        
        [[PLVRoomDataManager sharedManager] addDelegate:self delegateQueue:dispatch_get_main_queue()];
        self.liveRoom = liveRoom;
        
        self.pageController = [[PLVLCPageController alloc] init];
        [self addSubview:self.pageController.view];
        [self.liveRoom addChildViewController:self.pageController];
        
        PLVRoomData * roomData = [PLVRoomDataManager sharedManager].roomData;
        if (roomData.menuInfo || roomData.noNetWorkOfflineIntroductionEnabled) {
            [self roomDataManager_didMenuInfoChanged:roomData.menuInfo];
        }
    }
    return self;
}

- (void)updateLiveStatus:(PLVLCLiveStatus)liveStatus {
    if (self.descVctrl) {
        [self.descVctrl updateLiveStatus:liveStatus];
    }
    if (self.tuwenVctrl) {
        [self.tuwenVctrl updateLiveStatusIsLive:(liveStatus == PLVLCLiveStatusLiving || liveStatus == PLVLCLiveStatusStop)];
    }
}

- (void)updateLiveUserInfo {
    if (self.productVctrl) {
        [self.productVctrl updateUserInfo];
    }
    if (self.tuwenVctrl) {
        [self.tuwenVctrl updateUserInfo];
    }
}

- (void)updateQAUserInfo {
    if (self.qaVctrl) {
        [self.qaVctrl updateUserInfo];
    }
}

- (void)updatePlaybackViewModel:(PLVLCChatroomPlaybackViewModel *)playbackViewModel {
    self.playbackViewModel = playbackViewModel;
    [self.chatVctrl updatePlaybackViewModel:self.playbackViewModel];
}

- (void)startCardPush:(BOOL)start cardPushInfo:(NSDictionary *)dict callback:(void (^)(BOOL show))callback {
    [self.chatVctrl startCardPush:start cardPushInfo:dict callback:callback];
}

- (void)updateProductMenuTab:(NSDictionary *)dict {
    PLVLiveVideoChannelMenu *menu = [[PLVLiveVideoChannelMenu alloc] initWithDictionary:dict];
    if (![PLVFdUtil checkDictionaryUseable:dict] || ![PLVFdUtil checkStringUseable:menu.name]) {
        return;
    }
    
    NSMutableArray *titleArray = [NSMutableArray arrayWithArray:self.pageController.titles];
    NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.pageController.controllers];
    BOOL enabled = PLV_SafeBoolForDictKey(dict, @"enabled");
    if (enabled) {
        if (![controllers containsObject:self.productVctrl]) {
            UIViewController *viewController = [self controllerWithMenu:menu];
            [titleArray addObject:PLVLocalizedString(menu.name)];
            [controllers addObject:viewController];
        }
    } else {
        if ([controllers containsObject:self.productVctrl]) {
            [titleArray removeObject:PLVLocalizedString(menu.name)];
            [controllers removeObject:self.productVctrl];
            self.productVctrl = nil;
        }
    }

    [self.pageController setTitles:titleArray.copy controllers:controllers.copy];
}

- (void)updateSectionMenuTab {
    NSMutableArray *titleArray = [NSMutableArray arrayWithArray:self.pageController.titles];
    NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.pageController.controllers];
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (roomData.sectionEnable) {
        if (![controllers containsObject:self.sectionVctrl]) {
            PLVLCSectionViewController *vctrl = [[PLVLCSectionViewController alloc] init];
            self.sectionVctrl = vctrl;
            self.sectionVctrl.delegate = self;
            [titleArray addObject:PLVLocalizedString(@"章节")];
            [controllers addObject:vctrl];
        }
        if (!roomData.sectionList) {
            [self.sectionVctrl requestData];
        }
    } else {
        if ([controllers containsObject:self.sectionVctrl]) {
            [titleArray removeObject:PLVLocalizedString(@"章节")];
            [controllers removeObject:self.sectionVctrl];
            self.sectionVctrl = nil;
        }
    }
    
    [self.pageController setTitles:titleArray.copy controllers:controllers.copy];
}

- (void)updatePlaybackListMenuTab {
    NSMutableArray *titleArray = [NSMutableArray arrayWithArray:self.pageController.titles];
    NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.pageController.controllers];
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    if (roomData.playbackListEnable) {
        if (![controllers containsObject:self.playbackListVctrl]) {
            PLVLCPlaybackListViewController *vctrl = [[PLVLCPlaybackListViewController alloc] init];
            self.playbackListVctrl = vctrl;
            [titleArray addObject:PLVLocalizedString(@"往期")];
            [controllers addObject:vctrl];
        }
        if (!roomData.playbackList) {
            [self.sectionVctrl requestData];
        }
    } else {
        if ([controllers containsObject:self.sectionVctrl]) {
            [titleArray removeObject:PLVLocalizedString(@"章节")];
            [controllers removeObject:self.sectionVctrl];
            self.sectionVctrl = nil;
        }
    }
    
    [self.pageController setTitles:titleArray.copy controllers:controllers.copy];
}

- (void)updateOnlineList:(NSArray<PLVChatUser *> *)list total:(NSInteger)total {
    [self.onlineListVctrl updateOnlineList:list];
}

- (void)displayProductPageToExternalView:(UIView *)externalView {
    if (self.productVctrl) {
        if (!self.productVctrl.isViewLoaded) {
            [self.productVctrl viewDidLoad];
        }
        [self displaySubview:self.productVctrl.contentBackgroudView toSuperview:externalView];
        [self.productVctrl showInLandscape];
        
        // 保证商品库视图 低于PopoverView视图之下
        for (UIView *subview in externalView.subviews) {
            if ([subview isKindOfClass:NSClassFromString(@"PLVPopoverView")]) {
                [externalView insertSubview:self.productVctrl.contentBackgroudView belowSubview:subview];
                return;
            }
        }
    }
}

- (void)rollbackProductPageContentView {
    [self.productVctrl rollbackProductPageContentView];
}

- (void)leaveLiveRoom {
    if (self.chatVctrl) {
        [self.chatVctrl leaveLiveRoom];
    }
}

- (BOOL)showCommodityMenu {
    PLVLiveVideoChannelMenuInfo *channelMenuInfo = [PLVRoomDataManager sharedManager].roomData.menuInfo;
    if (![PLVFdUtil checkArrayUseable:channelMenuInfo.channelMenus]) {
        return NO;
    }
    
    __block BOOL commodityMenu = NO;
    [channelMenuInfo.channelMenus enumerateObjectsUsingBlock:^(PLVLiveVideoChannelMenu * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        PLVLCLivePageMenuType menuType = PLVLCMenuTypeWithMenuTypeString(obj.menuType);
        if (menuType == PLVLCLivePageMenuTypeBuy) {
            commodityMenu = obj.displayEnabled;
            *stop = YES;
        }
    }];
    
    return commodityMenu;
}

- (CGFloat)getKeyboardToolViewHeight {
    if (self.chatVctrl) {
        return [self.chatVctrl getKeyboardToolViewHeight];
    } else {
        return 56.0;
    }
}

#pragma mark - Private Method

- (void)updateChannelMenuInfo {
    PLVLiveVideoChannelMenuInfo *channelMenuInfo = [PLVRoomDataManager sharedManager].roomData.menuInfo;
    
    NSMutableArray *titleArray = [[NSMutableArray alloc] init];
    NSMutableArray *ctrlArray = [[NSMutableArray alloc] init];
    
    if ([PLVRoomDataManager sharedManager].roomData.noNetWorkOfflineIntroductionEnabled) {
        // 即没有网络，又播放离线缓存视频的情况，展示无网络直播介绍
        PLVLCNoNetworkDescViewController *vctrl = [[PLVLCNoNetworkDescViewController alloc]init];
        self.noNetworkDescVctrl = vctrl;
        [titleArray addObject:PLVLocalizedString(@"直播介绍")];
        [ctrlArray addObject:vctrl];
    }
    else {
        if (channelMenuInfo.channelMenus == nil ||
            ![channelMenuInfo.channelMenus isKindOfClass:[NSArray class]] ||
            [channelMenuInfo.channelMenus count] == 0 ) {
            return;
        }
        
        NSInteger menuCount = channelMenuInfo.channelMenus.count;
        
        for (int i = 0; i < menuCount; i++) {
            PLVLiveVideoChannelMenu *menu = channelMenuInfo.channelMenus[i];
            if (!menu.displayEnabled) {
                continue;
            }
            UIViewController *vctrl = [self controllerWithMenu:menu];
            if (!vctrl) {
                continue;
            }
            [titleArray addObject:PLVLocalizedString(menu.name)];
            [ctrlArray addObject:vctrl];
        }
        
        if ([PLVRoomDataManager sharedManager].roomData.menuInfo.portraitOnlineListEnabled && [PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Live &&!self.onlineListVctrl) {
            PLVLCOnlineListViewController *vctrl = [[PLVLCOnlineListViewController alloc] init];
            self.onlineListVctrl = vctrl;
            self.onlineListVctrl.delegate = self;
            [titleArray addObject:PLVLocalizedString(@"成员")];
            [ctrlArray addObject:vctrl];
        }
    }
    
    if ([PLVRoomDataManager sharedManager].roomData.menuInfo.multiMeetingEnabled) {
        PLVLCMultiMeetingViewController *vctrl = [[PLVLCMultiMeetingViewController alloc] init];
        [titleArray addObject:PLVLocalizedString(@"多会场")];
        [ctrlArray addObject:vctrl];
    }

    [self.pageController setTitles:[titleArray copy] controllers:[ctrlArray copy]];
}

/// 通过 menu 实例获得对应控制器
- (UIViewController *)controllerWithMenu:(PLVLiveVideoChannelMenu *)menu {
    PLVLCLivePageMenuType menuType = PLVLCMenuTypeWithMenuTypeString(menu.menuType);
    
    if (menuType == PLVLCLivePageMenuTypeDesc) {
        PLVLCDescViewController *vctrl = [[PLVLCDescViewController alloc] initWithChannelInfo:[PLVRoomDataManager sharedManager].roomData.menuInfo content:menu.content];
        self.descVctrl = vctrl;
        return vctrl;
    } else if (menuType == PLVLCLivePageMenuTypeChat) {
        PLVLCChatViewController *vctrl = [[PLVLCChatViewController alloc] initWithLiveRoom:self.liveRoom];
        vctrl.delegate = self;
        self.chatVctrl = vctrl;
        [self.chatVctrl updatePlaybackViewModel:self.playbackViewModel];
        return vctrl;
    } else if (menuType == PLVLCLivePageMenuTypeQuiz) {
        PLVLCQuizViewController *vctrl = [[PLVLCQuizViewController alloc] init];
        self.quizVctrl = vctrl;
        return vctrl;
    } else if (menuType == PLVLCLivePageMenuTypeTuwen) {
        PLVLCTuwenViewController *vctrl = [[PLVLCTuwenViewController alloc] init];
        vctrl.delegate = self;
        self.tuwenVctrl = vctrl;
        return vctrl;
    } else if (menuType == PLVLCLivePageMenuTypeText) {
        PLVLCTextViewController *vctrl = [[PLVLCTextViewController alloc] init];
        [vctrl loadHtmlWithContent:menu.content];
        return vctrl;
    } else if (menuType == PLVLCLivePageMenuTypeQA) {
        PLVLCQAViewController *vctrl = [[PLVLCQAViewController alloc] initWithRoomData:[PLVRoomDataManager sharedManager].roomData theme:@"black"];
        self.qaVctrl = vctrl;
        return vctrl;
    } else if (menuType == PLVLCLivePageMenuTypeIframe) {
        PLVLCIframeViewController *vctrl = [[PLVLCIframeViewController alloc] init];
        [vctrl loadURLString:menu.content];
        return vctrl;
    } else if (menuType == PLVLCLivePageMenuTypeBuy) {
        PLVLCBuyViewController *vctrl = [[PLVLCBuyViewController alloc] init];
        vctrl.delegate = self;
        self.productVctrl = vctrl;
        return vctrl;
    } else if (menuType == PLVLCLivePageMenuTypeMembers && [PLVRoomDataManager sharedManager].roomData.videoType == PLVChannelVideoType_Live) {
        PLVLCOnlineListViewController *vctrl = [[PLVLCOnlineListViewController alloc] init];
        vctrl.delegate = self;
        self.onlineListVctrl = vctrl;
        return vctrl;
    }
    
    return nil;
}

- (void)displaySubview:(UIView *)subview toSuperview:(UIView *)superview {
    if (subview.superview != superview) {
        [superview addSubview:subview];
        subview.frame = superview.bounds;
        subview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
}

#pragma mark - PLVRoomDataManagerProtocol

- (void)roomDataManager_didMenuInfoChanged:(PLVLiveVideoChannelMenuInfo *)menuInfo {
    [self updateChannelMenuInfo];
}

- (void)roomDataManager_didSectionEnableChanged:(BOOL)sectionEnable {
    [self updateSectionMenuTab];
}

- (void)roomDataManager_didPlaybackListEnableChanged:(BOOL)playbackListEnable {
    [self updatePlaybackListMenuTab];
}

#pragma mark - PLVWebViewTuwen Protocol

- (void)clickTuwenImage:(BOOL)showImage {
    [self.pageController scrollEnable:!showImage];
}

#pragma mark - PLVLCSectionViewControllerDelegate

- (NSTimeInterval)plvLCSectionViewGetPlayerCurrentTime:(PLVLCSectionViewController *)PLVLCSectionViewController {
    if ([self.delegate respondsToSelector:@selector(plvLCLivePageMenuAreaViewGetPlayerCurrentTime:)]) {
        return [self.delegate plvLCLivePageMenuAreaViewGetPlayerCurrentTime:self];
    } else {
        return 0;
    }
}

- (void)plvLCSectionView:(PLVLCSectionViewController *)PLVLCSectionViewController seekTime:(NSTimeInterval)time {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLivePageMenuAreaView:seekTime:)]) {
        [self.delegate plvLCLivePageMenuAreaView:self seekTime:time];
    }
}

#pragma mark - PLVLCBuyViewControllerDelegate

- (void)plvLCClickProductInViewController:(PLVLCBuyViewController *)viewController commodityModel:(PLVCommodityModel *)commodity {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLivePageMenuAreaView:clickProductCommodityModel:)]) {
        [self.delegate plvLCLivePageMenuAreaView:self clickProductCommodityModel:commodity];
    }
}

- (void)plvLCBuyViewController:(PLVLCBuyViewController *)viewController didShowJobDetail:(NSDictionary *)data {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLivePageMenuAreaView:didShowJobDetail:)]) {
        [self.delegate plvLCLivePageMenuAreaView:self didShowJobDetail:data];
    }
}

- (void)plvLCCloseProductViewInViewController:(PLVLCBuyViewController *)viewController {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLivePageMenuAreaViewCloseProductView:)]) {
        [self.delegate plvLCLivePageMenuAreaViewCloseProductView:self];
    }
}

#pragma mark - PLVLCChatViewControllerDelegate

- (void)plvLCChatViewController:(PLVLCChatViewController *)chatVC needOpenInteract:(NSDictionary *)dict {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLivePageMenuAreaView:needOpenInteract:)]) {
        [self.delegate plvLCLivePageMenuAreaView:self needOpenInteract:dict];
    }
}

- (void)plvLCChatViewController:(PLVLCChatViewController *)chatVC alertLongContentMessage:(PLVChatModel *)model {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(plvLCLivePageMenuAreaView:alertLongContentMessage:)]) {
        [self.delegate plvLCLivePageMenuAreaView:self alertLongContentMessage:model];
    }
}

- (void)plvLCChatViewController:(PLVLCChatViewController *)chatVC emitInteractEvent:(NSString *)event {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(plvLCLivePageMenuAreaView:emitInteractEvent:)]) {
        [self.delegate plvLCLivePageMenuAreaView:self emitInteractEvent:event];
    }
}

- (void)plvLCChatViewController:(PLVLCChatViewController *)chatVC lotteryWidgetShowStatusChanged:(BOOL)show {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(plvLCLivePageMenuAreaView:lotteryWidgetShowStatusChanged:)]) {
        [self.delegate plvLCLivePageMenuAreaView:self lotteryWidgetShowStatusChanged:show];
    }
}

- (void)plvLCChatViewControllerWannaShowWelfareLottery:(PLVLCChatViewController *)chatVC {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(plvLCLivePageMenuAreaViewWannaShowWelfareLottery:)]) {
        [self.delegate plvLCLivePageMenuAreaViewWannaShowWelfareLottery:self];
    }
}

- (void)plvLCChatViewController:(PLVLCChatViewController *)chatVC welfareLotteryWidgetShowStatusChanged:(BOOL)show {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(plvLCLivePageMenuAreaView:welfareLotteryWidgetShowStatusChanged:)]) {
        [self.delegate plvLCLivePageMenuAreaView:self welfareLotteryWidgetShowStatusChanged:show];
    }
}

#pragma mark - PLVLCOnlineListViewControllerDelegate

- (void)plvLCOnlineListViewControllerWannaShowRule:(PLVLCOnlineListViewController *)viewController {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(plvLCLivePageMenuAreaViewWannaShowOnlineListRule:)]) {
        [self.delegate plvLCLivePageMenuAreaViewWannaShowOnlineListRule:self];
    }
}

- (void)plvLCOnlineListViewControllerNeedUpdateOnlineList:(PLVLCOnlineListViewController *)viewController {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(plvLCLivePageMenuAreaViewNeedUpdateOnlineList:)]) {
        [self.delegate plvLCLivePageMenuAreaViewNeedUpdateOnlineList:self];
    }
}

@end
