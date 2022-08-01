//
//  PLVLSLinkMicAreaView.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2021/4/9.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSLinkMicAreaView.h"


@interface PLVLSLinkMicAreaView ()<PLVLSLinkMicWindowsViewDelegate>

#pragma mark 数据
@property (nonatomic, assign) NSInteger currentRTCRoomUserCount;

#pragma mark UI
/// view hierarchy
///
/// (UIView) superview
///  └── (PLVLSLinkMicAreaView) self (lowest)
///       └── (PLVLSLinkMicWindowsView) windowsView
@property (nonatomic, strong) PLVLSLinkMicWindowsView * windowsView;          // 连麦窗口列表视图 (负责展示 多个连麦成员RTC画面窗口，该视图支持左右滑动浏览)

@end

@implementation PLVLSLinkMicAreaView

#pragma mark - [ Life Period ]
- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

- (instancetype)init {
    if (self = [super initWithFrame:CGRectZero]) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.windowsView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
}

#pragma mark - [ Public Methods ]

- (void)reloadLinkMicUserWindows{
    [self.windowsView reloadLinkMicUserWindows];
}

- (void)updateFirstSiteWindowCellWithUserId:(NSString *)linkMicUserId toFirstSite:(BOOL)toFirstSite {
    [self.windowsView updateFirstSiteWindowCellWithUserId:linkMicUserId toFirstSite:toFirstSite];
    
}

- (void)firstSiteWindowCellExchangeWithExternal:(UIView *)externalView {
    [self.windowsView firstSiteWindowCellExchangeWithExternal:externalView];
}

- (void)rollbackFirstSiteWindowCellAndExternalView {
    [self.windowsView rollbackFirstSiteWindowCellAndExternalView];
}

#pragma mark - [ Private Methods ]
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

- (void)plvLSLinkMicWindowsView:(PLVLSLinkMicWindowsView *)windowsView showFirstSiteWindowCellOnExternal:(UIView *)windowCell {
    if ([self.delegate respondsToSelector:@selector(plvLSLinkMicAreaView:showFirstSiteWindowCellOnExternal:)]) {
        [self.delegate plvLSLinkMicAreaView:self showFirstSiteWindowCellOnExternal:windowCell];
    }
}

/// 连麦窗口需要回退外部视图
- (void)plvLSLinkMicWindowsView:(PLVLSLinkMicWindowsView *)windowsView rollbackExternalView:(UIView *)externalView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(plvLSLinkMicAreaView:rollbackExternalView:)]) {
        [self.delegate plvLSLinkMicAreaView:self rollbackExternalView:externalView];
    }
}

@end
