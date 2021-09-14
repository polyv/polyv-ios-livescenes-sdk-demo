//
//  PLVLSDocumentListUploadCell.m
//  PLVLiveScenesDemo
//
//  Created by Hank on 2021/3/8.
//  Copyright © 2021 PLV. All rights reserved.
//  上传文档Cell

#import "PLVLSDocumentListUploadCell.h"

#import <PLVFoundationSDK/PLVFoundationSDK.h>

#import "PLVLSUtils.h"

@interface PLVLSDocumentListUploadCell ()

@property (nonatomic, strong) UIButton *btnUpload;  // 上传按钮
@property (nonatomic, strong) UIButton *btnTip;     // 上传须知

@end

@implementation PLVLSDocumentListUploadCell

#pragma mark - [ Life Period ]

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    
    return self;
}


- (void)uploadTarget:(nullable id)target action:(SEL)action {
    if (self.btnUpload.allTargets.count == 0) {
        [self.btnUpload addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)tipTarget:(nullable id)target action:(SEL)action {
    if (self.btnTip.allTargets.count == 0) {
        [self.btnTip addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    }
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    [self.contentView addSubview:self.btnUpload];
    [self.contentView addSubview:self.btnTip];
    
    CGSize selfSize = self.bounds.size;
    self.btnUpload.frame = CGRectMake(0, 0, selfSize.width, selfSize.height - 28);
    self.btnTip.frame = CGRectMake(0, selfSize.height - 20, selfSize.width, 20);
}

// 加载图片
- (UIImage *)getImageWithName:(NSString *)name {
    if (! [PLVFdUtil checkStringUseable:name]) {
        return nil;
    }
    return [PLVLSUtils imageForDocumentResource:name];
}

#pragma mark - [ Getter ]

- (UIButton *)btnUpload {
    if (! _btnUpload) {
        _btnUpload = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnUpload setImage:[self getImageWithName:@"plvls_doc_upload"] forState:UIControlStateNormal];
    }
    
    return _btnUpload;
}

- (UIButton *)btnTip {
    if (! _btnTip) {
        _btnTip = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnTip setImage:[self getImageWithName:@"plvls_doc_upload_tip"] forState:UIControlStateNormal];
        _btnTip.titleLabel.font = [UIFont systemFontOfSize:14];
        [_btnTip setTitleColor:PLV_UIColorFromRGB(@"#CFD1D6") forState:UIControlStateNormal];
        [_btnTip setTitle:@"上传须知" forState:UIControlStateNormal];
        _btnTip.titleEdgeInsets = UIEdgeInsetsMake(0, 2, 0, 0);
    }
    
    return _btnTip;
}

@end
