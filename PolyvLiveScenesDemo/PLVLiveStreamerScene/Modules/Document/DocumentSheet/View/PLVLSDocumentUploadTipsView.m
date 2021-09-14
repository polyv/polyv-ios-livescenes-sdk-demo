//
//  PLVLSDocumentUploadTipsView.m
//  PLVCloudClassStreamerModul
//
//  Created by MissYasiky on 2020/3/24.
//  Copyright © 2020 easefun. All rights reserved.
//  上传须知

#import "PLVLSDocumentUploadTipsView.h"

#import <PLVFoundationSDK/PLVFoundationSDK.h>

#import "PLVLSUtils.h"

static NSString *const kDocumentUploadTips =
@"1. 18:00-19:00 为上传高峰期，排队时间较长，请错峰上传；\n\
2. 文档最大支持 500M，不超过 1000页；\n\
3. 仅支持未加密且不含音视频的 ppt、pptx、pdf、doc、docx、\n\
xls、xlsx、wps、jpg、jpeg、png 格式；\n\
4. wps 或含特殊字体、付费字体的文档请先转为 pdf 再上传";

@interface PLVLSDocumentUploadTipsView ()

@property (nonatomic, strong) UILabel *tipsLabel;

@property (nonatomic, strong) UIButton *closeButton;

@end

@implementation PLVLSDocumentUploadTipsView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        
        _tipsLabel = [[UILabel alloc] init];
        _tipsLabel.numberOfLines = 5;
        [self addSubview:_tipsLabel];
        [self setTips];
        
        UIImage *image = [PLVLSUtils imageForDocumentResource:@"plvls_ppt_btn_close_brush"];
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeButton.frame = CGRectMake(PLVScreenWidth - 141 - 32, 56, 32, 32);
        [_closeButton setImage:image forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_closeButton];
    }
    return self;
}

#pragma mark - [ Public Method]

- (void)showInView:(UIView *)view {
    self.frame = view.bounds;
    [view addSubview:self];
}

- (void)dismiss {
    [self removeFromSuperview];
}

#pragma mark - Action

- (void)closeButtonAction {
    [self dismiss];
}

#pragma mark - Private

- (void)setTips {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:15.0];
    
    NSDictionary *attribute = @{NSParagraphStyleAttributeName:paragraphStyle,
                                NSFontAttributeName:[UIFont systemFontOfSize:14],
                                NSForegroundColorAttributeName:PLV_UIColorFromRGB(@"#C0C0C0")
                                
    };
    
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:kDocumentUploadTips attributes:attribute];
    self.tipsLabel.attributedText = string;
    self.tipsLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    CGSize size = [kDocumentUploadTips sizeWithAttributes:attribute];
    self.tipsLabel.frame = CGRectMake(0, 0, size.width, size.height);
    self.tipsLabel.center = CGPointMake(PLVScreenWidth / 2.0, PLVScreenHeight / 2.0);
}

@end
