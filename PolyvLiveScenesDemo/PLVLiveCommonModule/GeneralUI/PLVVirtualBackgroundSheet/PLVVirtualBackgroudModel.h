//
//  PLVVirtualBackgroudModel.h
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/4/10.
//  Copyright © 2025 PLV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PLVVirtualBackgroudCellType) {
    PLVVirtualBackgroudCellDefault = 1,
    PLVVirtualBackgroudCellUpload ,
    PLVVirtualBackgroudCellBlur,
    PLVVirtualBackgroudCellCustomPicture,
    PLVVirtualBackgroudCellInnerPicture
};

@interface PLVVirtualBackgroudModel : NSObject

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSString *imageSourceName;
@property (nonatomic, copy) NSString *landscapeImageSourceName;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) PLVVirtualBackgroudCellType type;

@end

NS_ASSUME_NONNULL_END
