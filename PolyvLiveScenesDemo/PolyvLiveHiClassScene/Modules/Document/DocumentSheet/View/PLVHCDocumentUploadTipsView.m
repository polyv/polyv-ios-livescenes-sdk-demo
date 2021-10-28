//
//  PLVHCDocumentUploadTipsView.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/6/30.
//  Copyright © 2021 polyv. All rights reserved.
//

#import "PLVHCDocumentUploadTipsView.h"

// 工具
#import "PLVHCUtils.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>

static NSString *const kDocumentUploadTips =
@"1. 18:00-19:00 为上传高峰期，排队时间较长，请错峰上传；\n\
2. 文档最大支持 500M，不超过 1000页；\n\
3. 仅支持未加密且不含音视频的 ppt、pptx、pdf、doc、docx、\n\
xls、xlsx、wps、jpg、jpeg、png 格式；\n\
4. wps 或含特殊字体、付费字体的文档请先转为 pdf 再上传";

@interface PLVHCDocumentUploadTipsView ()

#pragma mark UI

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end

@implementation PLVHCDocumentUploadTipsView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.75];
        
        _contentView = [[UIView alloc] init];
        _contentView.layer.cornerRadius = 8;
        _contentView.layer.masksToBounds = YES;
        [_contentView.layer addSublayer:self.gradientLayer];
        [self addSubview:_contentView];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"上传须知";
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:18];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        [_contentView addSubview:_titleLabel];
        
        _tipsLabel = [[UILabel alloc] init];
        _tipsLabel.numberOfLines = 5;
        [_contentView addSubview:_tipsLabel];
        [self setTips];
        
        UIImage *image = [PLVHCUtils imageForDocumentResource:@"plvhc_doc_btn_close"];
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeButton.frame = CGRectMake(PLVScreenWidth - 141 - 32, 56, 32, 32);
        [_closeButton setImage:image forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:_closeButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize labelSize = [self.tipsLabel sizeThatFits:self.bounds.size];
    CGSize bgViewSize = CGSizeMake(labelSize.width + 24 * 2, labelSize.height + 56 + 24);
    self.contentView.frame = CGRectMake( (self.bounds.size.width - bgViewSize.width ) / 2 , (self.bounds.size.height - bgViewSize.height ) / 2, bgViewSize.width, bgViewSize.height);
    self.gradientLayer.frame = self.contentView.bounds;
    
    self.titleLabel.frame = CGRectMake(0, 26, bgViewSize.width, 18);
    
    self.tipsLabel.frame = CGRectMake(24, CGRectGetMaxY(self.titleLabel.frame) + 12, labelSize.width, labelSize.height);
    
    self.closeButton.frame = CGRectMake(bgViewSize.width - 16 - 18, 16, 18, 18);
    
}
#pragma mark - [ Public Method]

- (void)showInView:(UIView *)view {
    self.frame = view.bounds;
    [view addSubview:self];
}

- (void)dismiss {
    [self removeFromSuperview];
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.colors = @[(__bridge id)PLV_UIColorFromRGB(@"#30344F").CGColor, (__bridge id)PLV_UIColorFromRGB(@"#2D324C").CGColor];
        _gradientLayer.locations = @[@0.0, @1.0];
        _gradientLayer.startPoint = CGPointMake(0.5, 0.0);
        _gradientLayer.endPoint = CGPointMake(0.5, 1.0);
    }
    return _gradientLayer;
}

#pragma mark setTips

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
}

#pragma mark - Event
#pragma mark Action

- (void)closeButtonAction {
    [self dismiss];
}

@end
