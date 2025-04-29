//
//  PLVVirtualBackgroudSheet.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/4/10.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLVVirtualBackgroudBaseSheet.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVVirtualBackgroudMatType) {
    PLVVirtualBackgroudMatTypeNone = 1,
    PLVVirtualBackgroudMatTypeBlur,
    PLVVirtualBackgroudMatTypeCustomImage
};

@class PLVVirtualBackgroudSheet;

@protocol PLVVirtualBackgroudSheetDelegate <NSObject>

- (void)virtualBackgroudSheet:(PLVVirtualBackgroudSheet *)sheet
                      matType:(PLVVirtualBackgroudMatType)matType
                        image:(nullable UIImage *)matBgImage;

@end

@interface PLVVirtualBackgroudSheet : PLVVirtualBackgroudBaseSheet

@property (nonatomic, weak) id<PLVVirtualBackgroudSheetDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
