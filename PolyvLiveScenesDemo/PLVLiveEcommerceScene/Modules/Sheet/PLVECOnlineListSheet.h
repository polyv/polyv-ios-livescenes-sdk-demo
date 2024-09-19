//
//  PLVECOnlineListSheet.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/9/6.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVECBottomSheet.h"
#import "PLVChatUser.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVECOnlineListSheetDelegate;

@interface PLVECOnlineListSheet : PLVECBottomSheet

@property (nonatomic, weak) id <PLVECOnlineListSheetDelegate>delegate;

- (void)updateOnlineList:(NSArray <PLVChatUser *>*)onlineList;

@end

@protocol PLVECOnlineListSheetDelegate <NSObject>

- (void)plvECOnlineListSheetWannaShowRule:(PLVECOnlineListSheet *)sheet;

- (void)plvECOnlineListSheetNeedUpdateOnlineList:(PLVECOnlineListSheet *)sheet;

@end

NS_ASSUME_NONNULL_END
