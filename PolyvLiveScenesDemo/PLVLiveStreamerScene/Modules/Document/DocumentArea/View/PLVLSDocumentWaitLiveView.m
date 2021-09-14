//
//  PLVLSDocumentWaitLiveView.m
//  PLVLiveScenesDemo
//
//  Created by Lincal on 2021/8/19.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLSDocumentWaitLiveView.h"

#import "PLVLSUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLSDocumentWaitLiveView ()

@property (nonatomic, strong) UIImageView * placeholderImageView; // ‘直播未开始’占位图
@property (nonatomic, strong) UILabel * tipsLabel; // ‘直播未开始’提示语

@end

@implementation PLVLSDocumentWaitLiveView

#pragma mark - [ Life Period ]
- (void)dealloc{
    NSLog(@"%s",__FUNCTION__);
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews{
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    
    CGFloat heightScale = 321.0 / 240.0;
    CGFloat placeholderImageViewHeight = viewHeight / heightScale;
    self.placeholderImageView.frame = CGRectMake((viewWidth - placeholderImageViewHeight) / 2.0,
                                                 (viewHeight - placeholderImageViewHeight) / 2.0,
                                                 placeholderImageViewHeight, placeholderImageViewHeight);
    
    CGFloat tipsLabelYScale = 321.0 / 218.0;
    CGFloat tipsLabelY = viewHeight / tipsLabelYScale;
    CGFloat tipsLabelWidth = 200.0;
    self.tipsLabel.frame = CGRectMake((viewWidth - tipsLabelWidth) / 2.0, tipsLabelY, tipsLabelWidth, 17);
}

#pragma mark - [ Private Methods ]
- (void)setupUI{
    self.backgroundColor = PLV_UIColorFromRGB(@"#313540");
    
    /// 添加视图
    [self addSubview:self.placeholderImageView];
    [self addSubview:self.tipsLabel];
}

#pragma mark Getter
- (UIImageView *)placeholderImageView{
    if (!_placeholderImageView) {
        _placeholderImageView = [[UIImageView alloc] init];
        _placeholderImageView.image = [PLVLSUtils imageForDocumentResource:@"plvls_doc_waitLive"];
        _placeholderImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _placeholderImageView;
}

- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [[UILabel alloc] init];
        _tipsLabel.text = @"直播尚未开始，请稍作等待";
        _tipsLabel.font = [UIFont fontWithName:@"PingFang SC" size:12];
        _tipsLabel.textColor = PLV_UIColorFromRGB(@"#F0F1F5");
        _tipsLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _tipsLabel;
}

@end
