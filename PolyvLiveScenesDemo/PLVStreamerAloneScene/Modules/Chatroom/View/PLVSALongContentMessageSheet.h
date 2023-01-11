//
//  PLVSALongContentMessageSheet.h
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2022/11/22.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVSABottomSheet.h"
#import "PLVChatModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface PLVSALongContentMessageSheet : PLVSABottomSheet

- (instancetype)initWithChatModel:(PLVChatModel *)model;

@end

NS_ASSUME_NONNULL_END
