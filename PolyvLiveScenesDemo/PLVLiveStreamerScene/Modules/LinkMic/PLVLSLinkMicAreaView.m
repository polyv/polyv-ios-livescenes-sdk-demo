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
    self.windowsView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
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
- (NSArray *)plvLSLinkMicWindowsViewGetCurrentUserModelArray:(PLVLSLinkMicWindowsView *)windowsView{
    if ([self.delegate respondsToSelector:@selector(plvLSLinkMicAreaViewGetCurrentUserModelArray:)]) {
        return [self.delegate plvLSLinkMicAreaViewGetCurrentUserModelArray:self];
    }else{
        return nil;
    }
}

/// 连麦窗口列表视图 需要查询某个条件用户的下标值
- (NSInteger)plvLSLinkMicWindowsView:(PLVLSLinkMicWindowsView *)windowsView findUserModelIndexWithFiltrateBlock:(BOOL(^)(PLVLinkMicOnlineUser * enumerateUser))filtrateBlockBlock{
    if ([self.delegate respondsToSelector:@selector(plvLSLinkMicAreaView:findUserModelIndexWithFiltrateBlock:)]) {
        return [self.delegate plvLSLinkMicAreaView:self findUserModelIndexWithFiltrateBlock:filtrateBlockBlock];
    }else{
        return -1;
    }
}

/// 连麦窗口列表视图 需要根据下标值获取对应用户
- (PLVLinkMicOnlineUser *)plvLSLinkMicWindowsView:(PLVLSLinkMicWindowsView *)windowsView getUserModelFromOnlineUserArrayWithIndex:(NSInteger)targetIndex{
    if ([self.delegate respondsToSelector:@selector(plvLSLinkMicAreaView:getUserModelFromOnlineUserArrayWithIndex:)]) {
        return [self.delegate plvLSLinkMicAreaView:self getUserModelFromOnlineUserArrayWithIndex:targetIndex];
    }else{
        return nil;
    }
}


@end
