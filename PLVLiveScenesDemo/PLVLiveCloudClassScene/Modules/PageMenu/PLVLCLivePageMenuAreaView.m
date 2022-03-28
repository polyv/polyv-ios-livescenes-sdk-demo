//
//  PLVLCMenuAreaView.m
//  PLVLiveScenesDemo
//
//  Created by ftao on 2020/7/23.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCLivePageMenuAreaView.h"
#import "PLVLCPageController.h"
#import "PLVLCDescViewController.h"
#import "PLVLCQuizViewController.h"
#import "PLVLCTuwenViewController.h"
#import "PLVLCTextViewController.h"
#import "PLVLCQAViewController.h"
#import "PLVLCIframeViewController.h"
#import "PLVLCPlaybackListViewController.h"
#import "PLVLCSectionViewController.h"
#import "PLVRoomDataManager.h"
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
    }
    return PLVLCLivePageMenuTypeUnknown;
}

@interface PLVLCLivePageMenuAreaView ()<
PLVLCTuwenDelegate,
PLVLCSectionViewControllerDelegate,
PLVRoomDataManagerProtocol
>

@property (nonatomic, strong) PLVLCPageController *pageController;
/// 直播介绍页，直播状态更改时需改变其 UI 文本
@property (nonatomic, strong) PLVLCDescViewController *descVctrl;
/// 提问咨询页
@property (nonatomic, strong) PLVLCQuizViewController *quizVctrl;
/// 回放列表
@property (nonatomic, strong) PLVLCPlaybackListViewController *playbackListVctrl;
/// 章节列表页
@property (nonatomic, strong) PLVLCSectionViewController *sectionVctrl;

@property (nonatomic, weak) UIViewController *liveRoom;

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
        if (roomData.menuInfo) { [self roomDataManager_didMenuInfoChanged:roomData.menuInfo]; }
    }
    return self;
}

- (void)updateliveStatue:(BOOL)living {
    if (self.descVctrl) {
        [self.descVctrl updateliveStatue:living];
    }
}

#pragma mark - Private Method

- (void)updateChannelMenuInfo {
    PLVLiveVideoChannelMenuInfo *channelMenuInfo = [PLVRoomDataManager sharedManager].roomData.menuInfo;
    
    if (channelMenuInfo.channelMenus == nil ||
        ![channelMenuInfo.channelMenus isKindOfClass:[NSArray class]] ||
        [channelMenuInfo.channelMenus count] == 0 ) {
        return;
    }
    
    NSInteger menuCount = channelMenuInfo.channelMenus.count;
    NSMutableArray *titleArray = [[NSMutableArray alloc] initWithCapacity:menuCount];
    NSMutableArray *ctrlArray = [[NSMutableArray alloc] initWithCapacity:menuCount];
    
    for (int i = 0; i < menuCount; i++) {
        PLVLiveVideoChannelMenu *menu = channelMenuInfo.channelMenus[i];
        UIViewController *vctrl = [self controllerWithMenu:menu];
        if (!vctrl) {
            continue;
        }
        [titleArray addObject:menu.name];
        [ctrlArray addObject:vctrl];
    }
    
    if ([PLVRoomDataManager sharedManager].roomData.playbackList) {
        PLVLCPlaybackListViewController *vctrl = [[PLVLCPlaybackListViewController alloc] initWithPlaybackList:[PLVRoomDataManager sharedManager].roomData.playbackList];
        self.playbackListVctrl = vctrl;
        [titleArray addObject:@"往期"];
        [ctrlArray addObject:vctrl];
    }
    
    if ([PLVRoomDataManager sharedManager].roomData.sectionEnable) {
        PLVLCSectionViewController *vctrl = [[PLVLCSectionViewController alloc] initWithSectionList:[PLVRoomDataManager sharedManager].roomData.sectionList];
        self.sectionVctrl = vctrl;
        self.sectionVctrl.delegate = self;
        [titleArray addObject:@"章节"];
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
        self.chatVctrl = vctrl;
        return vctrl;
    } else if (menuType == PLVLCLivePageMenuTypeQuiz) {
        PLVLCQuizViewController *vctrl = [[PLVLCQuizViewController alloc] init];
        self.quizVctrl = vctrl;
        return vctrl;
    } else if (menuType == PLVLCLivePageMenuTypeTuwen) {
        NSInteger channelIdInt = [[PLVRoomDataManager sharedManager].roomData.channelId integerValue];
        PLVLCTuwenViewController *vctrl = [[PLVLCTuwenViewController alloc] initWithChannelId:@(channelIdInt)];
        vctrl.delegate = self;
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
    }
    
    return nil;
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

@end