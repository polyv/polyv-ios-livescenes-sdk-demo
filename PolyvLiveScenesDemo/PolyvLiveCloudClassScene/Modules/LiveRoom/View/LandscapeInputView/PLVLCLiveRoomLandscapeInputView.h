//
//  PLVLCLiveRoomLandscapeInputView.h
//  PolyvLiveScenesDemo
//
//  Created by Lincal on 2020/10/16.
//  Copyright © 2020 polyv. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLCLiveRoomLandscapeInputViewDelegate;

/// 直播间横屏输入视图
@interface PLVLCLiveRoomLandscapeInputView : UIView

/// delegate
@property (nonatomic, weak) id <PLVLCLiveRoomLandscapeInputViewDelegate> delegate;

- (void)showInputView:(BOOL)show;

@end

@protocol PLVLCLiveRoomLandscapeInputViewDelegate <NSObject>

- (void)plvLCLiveRoomLandscapeInputView:(PLVLCLiveRoomLandscapeInputView *)inputView SendButtonClickedWithSendContent:(NSString *)sendContent;

@end


NS_ASSUME_NONNULL_END
