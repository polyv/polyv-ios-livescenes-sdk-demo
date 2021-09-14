//
//  PLVSAChatroomGiftView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/4.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 直播间送礼物
@interface PLVSAChatroomGiftView : UIView


/// 展示收到礼物动画
/// @param userName 赠送人昵称
/// @param giftImageUrl 礼物图片地址
/// @param giftNum 礼物数量
/// @param giftContent 礼物内容
- (void)showGiftAnimation:(NSString *)userName giftImageUrl:(NSString *)giftImageUrl giftNum:(NSInteger )giftNum giftContent:(NSString *)giftContent;

/// 展示收到现金打赏动画
/// @param userName 赠送人昵称
/// @param cashGiftContent 打赏金额
- (void)showGiftAnimation:(NSString *)userName cashGiftContent:(NSString *)cashGiftContent;

@end

NS_ASSUME_NONNULL_END
