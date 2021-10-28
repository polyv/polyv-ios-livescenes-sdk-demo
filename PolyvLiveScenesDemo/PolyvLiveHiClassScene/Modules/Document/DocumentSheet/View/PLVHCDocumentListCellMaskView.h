//
//  PLVHCDocumentListCellMaskView.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/30.
//  Copyright © 2021 polyv. All rights reserved.
// PLVHCDocumentListCell 蒙层视图

#import <UIKit/UIKit.h>
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVHCDocumentListCellMaskView : UIView

@property (nonatomic, strong) UIButton *button;

///  0:上传中；1:上传失败；2:上传成功；3:转码失败
@property (nonatomic, assign) PLVDocumentUploadStatus status;

- (instancetype)initWithAnimateLoss:(BOOL)loss;

- (void)updateProgress:(CGFloat)progrss;

@end

NS_ASSUME_NONNULL_END
