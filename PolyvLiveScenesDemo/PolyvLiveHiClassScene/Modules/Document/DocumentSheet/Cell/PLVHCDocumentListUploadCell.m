//
//  PLVHCDocumentListUploadCell.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/30.
//  Copyright © 2021 polyv. All rights reserved.
// 上传文档Cell

#import "PLVHCDocumentListUploadCell.h"

// 工具
#import "PLVHCUtils.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVHCDocumentListUploadCell ()

@property (nonatomic, strong) UIButton *uploadButton;  // 上传按钮
@property (nonatomic, strong) UIButton *tipButton;     // 上传须知

@end

@implementation PLVHCDocumentListUploadCell


#pragma mark - [ Life Cycle ]

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    
    return self;
}

#pragma mark - [ Public Method ]

- (void)uploadTarget:(nullable id)target action:(SEL)action {
    if (self.uploadButton.allTargets.count == 0) {
        [self.uploadButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)tipTarget:(nullable id)target action:(SEL)action {
    if (self.tipButton.allTargets.count == 0) {
        [self.tipButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    }
}

#pragma mark - [ Private Methods ]
#pragma mark Getter

- (UIButton *)uploadButton {
    if (! _uploadButton) {
        _uploadButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_uploadButton setImage:[self getImageWithName:@"plvhc_doc_upload"] forState:UIControlStateNormal];
    }
    
    return _uploadButton;
}

- (UIButton *)tipButton {
    if (! _tipButton) {
        _tipButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_tipButton setImage:[self getImageWithName:@"plvhc_doc_upload_tip"] forState:UIControlStateNormal];
        _tipButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_tipButton setTitleColor:PLV_UIColorFromRGB(@"#CFD1D6") forState:UIControlStateNormal];
        [_tipButton setTitle:@"上传须知" forState:UIControlStateNormal];
        _tipButton.titleEdgeInsets = UIEdgeInsetsMake(0, 2, 0, 0);
    }
    
    return _tipButton;
}

- (UIImage *)getImageWithName:(NSString *)name {
    if (! [PLVFdUtil checkStringUseable:name]) {
        return nil;
    }
    return [PLVHCUtils imageForDocumentResource:name];
}

#pragma mark setupUI

- (void)setupUI {
    [self.contentView addSubview:self.uploadButton];
    [self.contentView addSubview:self.tipButton];
    
    CGSize selfSize = self.bounds.size;
    self.uploadButton.frame = CGRectMake(0, 0, selfSize.width, selfSize.height - 28);
    self.tipButton.frame = CGRectMake(0, selfSize.height - 20, selfSize.width, 20);
}

@end
