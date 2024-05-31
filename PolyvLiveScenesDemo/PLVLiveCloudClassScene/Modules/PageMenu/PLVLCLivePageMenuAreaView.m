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
#import "PLVRoomDataManager.h"
#import "PLVMultiLanguageManager.h"
#import "PLVLCChatroomPlaybackViewModel.h"
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
    }
    return PLVLCLivePageMenuTypeUnknown;
}

@interface PLVLCLivePageMenuAreaView ()<
PLVLCTuwenDelegate,
PLVLCBuyViewControllerDelegate,
PLVLCSectionViewControllerDelegate,
PLVLCChatViewControllerDelegate,
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

- (void)displayProductPageToExternalView:(UIView *)externalView {
    if (self.productVctrl) {
        if (!self.productVctrl.isViewLoaded) {
            [self.productVctrl viewDidLoad];
        }
        [self displaySubview:self.productVctrl.contentBackgroudView toSuperview:externalView];
        [self.productVctrl showInLandscape];
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
        
        if ([PLVRoomDataManager sharedManager].roomData.playbackList) {
            PLVLCPlaybackListViewController *vctrl = [[PLVLCPlaybackListViewController alloc] initWithPlaybackList:[PLVRoomDataManager sharedManager].roomData.playbackList];
            self.playbackListVctrl = vctrl;
            [titleArray addObject:PLVLocalizedString(@"往期")];
            [ctrlArray addObject:vctrl];
        }
        
        if ([PLVRoomDataManager sharedManager].roomData.sectionEnable) {
            PLVLCSectionViewController *vctrl = [[PLVLCSectionViewController alloc] initWithSectionList:[PLVRoomDataManager sharedManager].roomData.sectionList];
            self.sectionVctrl = vctrl;
            self.sectionVctrl.delegate = self;
            [titleArray addObject:PLVLocalizedString(@"章节")];
            [ctrlArray addObject:vctrl];
        }
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

- (void)plvLCClickProductInViewController:(PLVLCBuyViewController *)viewController linkURL:(NSURL *)linkURL commodity:(PLVCommodityModel *)commodity {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLCLivePageMenuAreaView:clickProductLinkURL:commodity:)]) {
        [self.delegate plvLCLivePageMenuAreaView:self clickProductLinkURL:linkURL commodity:commodity];
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

@end
