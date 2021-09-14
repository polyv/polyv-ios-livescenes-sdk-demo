//
//  PLVLSDocumentListCellMaskView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/4/9.
//  Copyright © 2020 easefun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PLVLSDocumentListCellMaskView : UIView

///  0:上传中；1:上传失败；2:上传成功；3:转码失败
@property (nonatomic, assign) NSInteger status;

@property (nonatomic, strong) UIButton *button;

- (instancetype)initWithAnimateLoss:(BOOL)loss;

- (void)updateProgress:(CGFloat)progrss;

@end

NS_ASSUME_NONNULL_END
