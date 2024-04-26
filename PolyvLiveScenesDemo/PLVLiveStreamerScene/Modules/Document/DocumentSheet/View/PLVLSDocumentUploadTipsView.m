//
//  PLVLSDocumentUploadTipsView.m
//  PLVCloudClassStreamerModul
//
//  Created by MissYasiky on 2020/3/24.
//  Copyright © 2020 PLV. All rights reserved.
//  上传须知

#import "PLVLSDocumentUploadTipsView.h"

#import <PLVFoundationSDK/PLVFoundationSDK.h>

#import "PLVLSUtils.h"
#import "PLVMultiLanguageManager.h"

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
    
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:PLVLocalizedString(@"PLVLSDocumentUploadTips") attributes:attribute];
    self.tipsLabel.attributedText = string;
    self.tipsLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    CGSize size = [PLVLocalizedString(@"PLVLSDocumentUploadTips") sizeWithAttributes:attribute];
    self.tipsLabel.frame = CGRectMake(0, 0, size.width, size.height);
    self.tipsLabel.center = CGPointMake(PLVScreenWidth / 2.0, PLVScreenHeight / 2.0);
}

@end
