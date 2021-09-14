//
//  PLVLSDocumentNumView.h
//  PLVLiveStreamerDemo
//
//  Created by MissYasiky on 2021/3/24.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSDocumentNumView : UIView

/// 记录嘉宾登录时的直播结束状态 YES:隐藏视图；NO:显示视图
@property (nonatomic, assign) BOOL guestFinishClass;

- (void)setCurrentPage:(NSUInteger)pageId totalPage:(NSUInteger)totalPage;

@end

NS_ASSUME_NONNULL_END
