//
//  PLVShareLiveSheet.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2022/8/1.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 直播场景
typedef NS_ENUM(NSUInteger, PLVShareLiveSheetSceneType) {
    /// 手机开播三分屏场景
    PLVShareLiveSheetSceneTypeLS = 0,
    /// 手机开播纯视频场景
    PLVShareLiveSheetSceneTypeSA = 1
};

@protocol PLVShareLiveSheetDelegate <NSObject>

- (void)shareLiveSheetCopyLinkFinished;

/// 保存图片结束的回调
/// @param succeed 保存图片是否成功 YES 成功 NO 失败
- (void)shareLiveSheetFinishSavingPictureWithSucceed:(BOOL)succeed;

@end

@interface PLVShareLiveSheet : UIView

@property (nonatomic, weak) id<PLVShareLiveSheetDelegate> delegate;

- (instancetype)initWithType:(PLVShareLiveSheetSceneType)type;

- (void)showInView:(UIView *)parentView;
/// 收起弹层
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
