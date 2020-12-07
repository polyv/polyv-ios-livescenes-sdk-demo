//
//  PLVLCMenuAreaView.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/7/23.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVLCLivePageMenuAreaView.h"
#import "PLVPageController.h"
#import "PLVLCDescViewController.h"
#import "PLVLCQuizViewController.h"
#import "PLVLCTuwenViewController.h"
#import "PLVLCTextViewController.h"
#import "PLVLCIframeViewController.h"
#import "PLVLCLivePageMenuViewModel.h"
#import "PLVLiveRoomData.h"
#import <PLVLiveScenesSDK/PLVLiveVideoChannelMenuInfo.h>

@interface PLVLCLivePageMenuAreaView ()<
PLVLCTuwenDelegate
>

@property (nonatomic, strong) PLVLCLivePageMenuViewModel *viewModel;

@property (nonatomic, strong) PLVPageController *pageController;

@property (nonatomic, strong) PLVLiveVideoChannelMenuInfo *channelInfo;

@property (nonatomic, assign) NSInteger channelId;
/// 直播介绍页，直播状态更改时需改变其 UI 文本
@property (nonatomic, strong) PLVLCDescViewController *descVctrl;
/// 提问咨询页
@property (nonatomic, strong) PLVLCQuizViewController *quizVctrl;

@property (nonatomic, weak) UIViewController *liveRoom;

@property (nonatomic, strong) PLVLiveRoomData *roomData;

@end

@implementation PLVLCLivePageMenuAreaView

#pragma mark - Life Cycle

- (void)layoutSubviews {
    [super layoutSubviews];
    self.pageController.view.frame = self.bounds;
}

#pragma mark - KVO

- (void)observeRoomData {
    PLVLiveRoomData *roomData = self.roomData;
    [roomData addObserver:self forKeyPath:KEYPATH_LIVEROOM_CHANNEL options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObserveRoomData {
    PLVLiveRoomData *roomData = self.roomData;
    [roomData removeObserver:self forKeyPath:KEYPATH_LIVEROOM_CHANNEL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (![object isKindOfClass:PLVLiveRoomData.class]) {
        return;
    }
    
    PLVLiveRoomData *roomData = object;
    if ([keyPath isEqualToString:KEYPATH_LIVEROOM_CHANNEL]) { // 频道信息
        if (!roomData.channelMenuInfo) {
            return;
        }
        [self setChannelMenuInfo:roomData.channelMenuInfo channelId:[[roomData channelId] integerValue]];
    }
}

#pragma mark - Public Method

- (instancetype)initWithLiveRoom:(UIViewController *)liveRoom roomData:(PLVLiveRoomData *)roomData{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0x20/255.0 green:0x21/255.0 blue:0x27/255.0 alpha:1];
        
        self.viewModel = [[PLVLCLivePageMenuViewModel alloc] init];
        self.liveRoom = liveRoom;
        self.roomData = roomData;
        
        self.pageController = [[PLVPageController alloc] init];
        [self addSubview:self.pageController.view];
        // 监听房间数据
        [self observeRoomData];
    }
    return self;
}

- (void)liveStatueChange:(BOOL)living {
    self.inPlaybackScene = NO;
    if (self.descVctrl) {
        [self.descVctrl liveStatueChange:living];
    }
}

- (void)clearResource {
    [self removeObserveRoomData];
    [self.chatVctrl clearResource];
    [self.quizVctrl clearResource];
}

#pragma mark - Private Method

- (void)setChannelMenuInfo:(PLVLiveVideoChannelMenuInfo *)channelMenuInfo channelId:(NSInteger)channelId {
    if (channelMenuInfo.channelMenus == nil ||
        ![channelMenuInfo.channelMenus isKindOfClass:[NSArray class]] ||
        [channelMenuInfo.channelMenus count] == 0 ) {
        return;
    }
    
    self.channelInfo = channelMenuInfo;
    self.channelId = channelId;
    
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
    
    [self.pageController setTitles:[titleArray copy] controllers:[ctrlArray copy]];
}

/// 通过 menu 实例获得对应控制器
- (UIViewController *)controllerWithMenu:(PLVLiveVideoChannelMenu *)menu {
    PLVLCLivePageMenuType menuType = [self.viewModel menuTypeWithMenu:menu.menuType];
    
    if (menuType == PLVLCLivePageMenuTypeDesc) {
        PLVLCDescViewController *vctrl = [[PLVLCDescViewController alloc] initWithChannelInfo:self.channelInfo content:menu.content];
        vctrl.inPlaybackScene = self.inPlaybackScene;
        self.descVctrl = vctrl;
        return vctrl;
    } else if (menuType == PLVLCLivePageMenuTypeChat) {
        PLVLCChatViewController *vctrl = [[PLVLCChatViewController alloc] initWithRoomData:self.roomData liveRoom:self.liveRoom];
        self.chatVctrl = vctrl;
        return vctrl;
    } else if (menuType == PLVLCLivePageMenuTypeQuiz) {
        PLVLCQuizViewController *vctrl = [[PLVLCQuizViewController alloc] initWithRoomData:self.roomData];
        self.quizVctrl = vctrl;
        return vctrl;
    } else if (menuType == PLVLCLivePageMenuTypeTuwen) {
        PLVLCTuwenViewController *vctrl = [[PLVLCTuwenViewController alloc] initWithChannelId:@(self.channelId)];
        vctrl.delegate = self;
        return vctrl;
    } else if (menuType == PLVLCLivePageMenuTypeText) {
        PLVLCTextViewController *vctrl = [[PLVLCTextViewController alloc] init];
        [vctrl loadHtmlWithContent:menu.content];
        return vctrl;
    } else if (menuType == PLVLCLivePageMenuTypeIframe) {
        PLVLCIframeViewController *vctrl = [[PLVLCIframeViewController alloc] init];
        [vctrl loadURLString:menu.content];
        return vctrl;
    }
    
    return nil;
}

#pragma mark - PLVWebViewTuwen Protocol

- (void)clickTuwenImage:(BOOL)showImage {
    [self.pageController scrollEnable:!showImage];
}

@end
