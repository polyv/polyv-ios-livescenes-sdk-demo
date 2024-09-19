//
//  PLVLCOnlineListSheet.h
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2024/9/9.
//  Copyright © 2024 PLV. All rights reserved.
//

#import "PLVLCBottomSheet.h"
#import "PLVChatUser.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PLVLCOnlineListSheetDelegate;

@interface PLVLCOnlineListSheet : PLVLCBottomSheet

@property (nonatomic, weak) id <PLVLCOnlineListSheetDelegate>delegate;

- (void)updateOnlineList:(NSArray <PLVChatUser *>*)onlineList;

@end

@protocol PLVLCOnlineListSheetDelegate <NSObject>

- (void)plvLCOnlineListSheetWannaShowRule:(PLVLCOnlineListSheet *)sheet;

- (void)plvLCOnlineListSheetNeedUpdateOnlineList:(PLVLCOnlineListSheet *)sheet;

@end

NS_ASSUME_NONNULL_END
