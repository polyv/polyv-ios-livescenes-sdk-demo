//
//  PLVLSDocumentPagesCell.m
//  PLVLiveStreamerDemo
//
//  Created by Hank on 2021/3/9.
//  Copyright © 2021 PLV. All rights reserved.
//  文档页面列表Cell

#import "PLVLSDocumentPagesCell.h"

#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVLSUtils.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVLSDocumentPagesCell ()

@property (nonatomic, strong) UIImageView *ivLogo;  // 页面图片
@property (nonatomic, strong) UIButton *btnCount;   // 页面序号

@end

@implementation PLVLSDocumentPagesCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    
    return self;
}

#pragma mark - [ Public Methods ]

- (void)setSelected:(BOOL)selected {
    super.selected = selected;
    
    self.ivLogo.layer.borderWidth = selected ? 2.0f : 0.0f;
    self.btnCount.selected = selected;
}

- (void)setImgUrl:(NSString *)imgUrl index:(NSInteger)index {
    NSURL *url = [NSURL URLWithString:imgUrl];
    UIImage *imgPlaceholder = [PLVLSUtils imageForDocumentResource:@"plvls_doc_placeholder"];
    [self.ivLogo sd_setImageWithURL:url placeholderImage:imgPlaceholder options:SDWebImageRetryFailed];
    
    [self.btnCount setTitle:[NSString stringWithFormat:@"%ld", (long)index] forState:UIControlStateNormal];
}

#pragma mark - [ Private Methods ]

- (void)setupUI {
    [self.contentView addSubview:self.ivLogo];
    [self.contentView addSubview:self.btnCount];
    
    CGSize selfSize = self.bounds.size;
    self.ivLogo.frame = self.bounds;
    self.btnCount.frame = CGRectMake(selfSize.width - 24, selfSize.height - 16, 24, 16);
    
    // 设置序号视图圆角
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.btnCount.bounds
                                                   byRoundingCorners:(UIRectCornerTopLeft|UIRectCornerBottomRight)
                                                         cornerRadii:CGSizeMake(4, 4)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = self.btnCount.bounds;
    maskLayer.path = maskPath.CGPath;
    self.btnCount.layer.mask = maskLayer;
    [self.btnCount.layer setMasksToBounds:YES];
}

#pragma mark - [ Getter ]

- (UIImageView *)ivLogo {
    if (! _ivLogo) {
        _ivLogo = [[UIImageView alloc] init];
        _ivLogo.backgroundColor = PLV_UIColorFromRGB(@"#313540");
        _ivLogo.layer.cornerRadius = 4;
        _ivLogo.layer.borderColor = PLV_UIColorFromRGB(@"#4399FF").CGColor;
        _ivLogo.clipsToBounds = YES;
        _ivLogo.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    return _ivLogo;
}

- (UIButton *)btnCount {
    if (! _btnCount) {
        UIImage *imgNormal = [PLVColorUtil createImageWithColor:PLV_UIColorFromRGBA(@"#1D2539", 0.8f)];
        UIImage *imgSelected = [PLVColorUtil createImageWithColor:PLV_UIColorFromRGB(@"#4399FF")];
        
        _btnCount = [UIButton buttonWithType:UIButtonTypeCustom];
        [_btnCount setBackgroundImage:imgNormal forState:UIControlStateNormal];
        [_btnCount setBackgroundImage:imgSelected forState:UIControlStateSelected];
        _btnCount.titleLabel.font = [UIFont systemFontOfSize:14];
        [_btnCount setTitleColor:PLV_UIColorFromRGB(@"#F0F1F6") forState:UIControlStateNormal];
        [_btnCount setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        _btnCount.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        _btnCount.userInteractionEnabled = NO;
    }
    
    return _btnCount;
}

@end
