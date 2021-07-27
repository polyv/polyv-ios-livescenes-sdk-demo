//
//  PLVLSLinkMicAreaView.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2021/4/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSLinkMicAreaView.h"

#import "PLVLSLinkMicWindowsView.h"

@interface PLVLSLinkMicAreaView ()<PLVLSLinkMicWindowsViewDelegate>

#pragma mark 数据
@property (nonatomic, assign) BOOL currentLandscape; // 当前是否横屏 (YES:当前横屏 NO:当前竖屏)
@property (nonatomic, assign) NSInteger currentRTCRoomUserCount;

#pragma mark UI
/// view hierarchy
///
/// (UIView) superview
///  └── (PLVLCLinkMicAreaView) self (lowest)
///       └── (PLVLCLinkMicWindowsView) windowsView
@property (nonatomic, strong) PLVLSLinkMicWindowsView * windowsView;          // 连麦窗口列表视图 (负责展示 多个连麦成员RTC画面窗口，该视图支持左右滑动浏览)

@end

@implementation PLVLSLinkMicAreaView

#pragma mark - [ Life Period ]
- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero]) {
        [self setup];
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    BOOL fullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    BOOL fullScreenDifferent = (self.currentLandscape != fullScreen);
    self.currentLandscape = fullScreen;
    
    self.windowsView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    
    if (!fullScreen) {
        // 竖屏
    } else {
        // 横屏
    }

}

- (void)reloadLinkMicUserWindows{
    [self.windowsView reloadLinkMicUserWindows];
}

#pragma mark - [ Private Methods ]
- (void)setup{

}

- (void)setupUI{
    // 添加 连麦窗口列表视图
    [self addSubview:self.windowsView];
}


#pragma mark Getter
- (PLVLSLinkMicWindowsView *)windowsView{
    if (!_windowsView) {
        _windowsView = [[PLVLSLinkMicWindowsView alloc] init];
        _windowsView.delegate = self;
    }
    return _windowsView;
}

#pragma mark - [ Delegate ]
#pragma mark PLVLSLinkMicWindowsViewDelegate
/// 连麦窗口列表视图 需要获取当前用户数组
- (NSArray *)plvLCLinkMicWindowsViewGetCurrentUserModelArray:(PLVLSLinkMicWindowsView *)windowsView{
    if ([self.delegate respondsToSelector:@selector(plvLCLinkMicWindowsViewGetCurrentUserModelArray:)]) {
        return [self.delegate plvLCLinkMicWindowsViewGetCurrentUserModelArray:self];
    }else{
        return nil;
    }
}

/// 连麦窗口列表视图 需要查询某个条件用户的下标值
- (NSInteger)plvLCLinkMicWindowsView:(PLVLSLinkMicWindowsView *)windowsView findUserModelIndexWithFiltrateBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filtrateBlockBlock{
    if ([self.delegate respondsToSelector:@selector(plvLCLinkMicWindowsView:findUserModelIndexWithFiltrateBlock:)]) {
        return [self.delegate plvLCLinkMicWindowsView:self findUserModelIndexWithFiltrateBlock:filtrateBlockBlock];
    }else{
        return -1;
    }
}

/// 连麦窗口列表视图 需要根据下标值获取对应用户
- (PLVLinkMicOnlineUser *)plvLCLinkMicWindowsView:(PLVLSLinkMicWindowsView *)windowsView getUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex{
    if ([self.delegate respondsToSelector:@selector(plvLCLinkMicWindowsView:getUserModelFromOnlineUserArrayWithIndex:)]) {
        return [self.delegate plvLCLinkMicWindowsView:self getUserModelFromOnlineUserArrayWithIndex:targetIndex];
    }else{
        return nil;
    }
}


@end
