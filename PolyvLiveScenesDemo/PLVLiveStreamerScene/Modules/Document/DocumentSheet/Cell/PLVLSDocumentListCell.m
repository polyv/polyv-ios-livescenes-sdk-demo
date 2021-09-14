//
//  PLVLSDocumentListCell.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2019/10/14.
//  Copyright © 2019 easefun. All rights reserved.
//

#import "PLVLSDocumentListCell.h"
#import "PLVLSDocumentLoadingView.h"
#import "PLVLSDocumentListCellMaskView.h"
#import "PLVDocumentModel.h"
#import "PLVLSUtils.h"
#import "PLVDocumentConvertManager.h"
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface PLVLSDocumentListCell ()

@property (nonatomic, strong) PLVLSDocumentLoadingView *loadingView; // 加载视图
@property (nonatomic, strong) UIImageView *pptImageView; // 文档图片
@property (nonatomic, strong) PLVLSDocumentListCellMaskView *maskView; // 上传中顶部图层
@property (nonatomic, strong) PLVLSDocumentListCellMaskView *animateLossMaskView; // 动态丢失提示图层
@property (nonatomic, strong) UILabel *titleLabel; // 文档标题

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGesture;

@end

@implementation PLVLSDocumentListCell

#pragma mark - LifeCycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.pptImageView];
        [self.contentView addSubview:self.maskView];
        [self.contentView addSubview:self.animateLossMaskView];
        [self.contentView addSubview:self.titleLabel];
        
        [self addGestureRecognizer:self.longPressGesture];
    }
    return self;
}

- (void)layoutSubviews {
    CGSize size = self.bounds.size;
    CGRect pptImageRect = CGRectMake(0, 0, size.width, size.height - 28);
    
    self.pptImageView.frame = pptImageRect;
    self.maskView.frame = pptImageRect;
    self.animateLossMaskView.frame = pptImageRect;
    self.titleLabel.frame = CGRectMake(0, CGRectGetMaxY(self.pptImageView.frame) + 8, CGRectGetWidth(self.pptImageView.frame), 20);
    
    [super layoutSubviews];
}

#pragma mark - Override

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.pptImageView.layer.borderWidth = selected ? 2.0f : 0.0f;
    self.titleLabel.textColor = selected ? PLV_UIColorFromRGB(@"#4399FF") : PLV_UIColorFromRGB(@"#CFD1D6");
}

#pragma mark - [ Getter ]

- (UIImageView *)pptImageView {
    if (!_pptImageView) {
        _pptImageView = [[UIImageView alloc] init];
        _pptImageView.backgroundColor = PLV_UIColorFromRGB(@"#313540");
        _pptImageView.layer.cornerRadius = 4;
        _pptImageView.layer.borderColor = PLV_UIColorFromRGB(@"#4399FF").CGColor;
        _pptImageView.clipsToBounds = YES;
        _pptImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _pptImageView;
}

- (PLVLSDocumentListCellMaskView *)maskView {
    if (!_maskView) {
        _maskView = [[PLVLSDocumentListCellMaskView alloc] init];
        [_maskView.button addTarget:self
                             action:@selector(maskViewButtonAction)
                   forControlEvents:UIControlEventTouchUpInside];
        _maskView.hidden = YES;
    }
    return _maskView;
}

- (PLVLSDocumentListCellMaskView *)animateLossMaskView {
    if (!_animateLossMaskView) {
        _animateLossMaskView = [[PLVLSDocumentListCellMaskView alloc] initWithAnimateLoss:YES];
        [_animateLossMaskView.button addTarget:self action:@selector(animateLossMaskViewButtonAction) forControlEvents:UIControlEventTouchUpInside];
        _animateLossMaskView.hidden = YES;
    }
    return _animateLossMaskView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = PLV_UIColorFromRGB(@"#CFD1D6");
        _titleLabel.font = [UIFont systemFontOfSize:14];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UILongPressGestureRecognizer *)longPressGesture {
    if (!_longPressGesture) {
        _longPressGesture = [[UILongPressGestureRecognizer alloc] init];
        _longPressGesture.minimumPressDuration = 1.0;
        [_longPressGesture addTarget:self action:@selector(longPressGestureAction:)];
    }
    return _longPressGesture;
}

#pragma mark - Action

- (void)longPressGestureAction:(UILongPressGestureRecognizer *)gesture {
    if (!self.maskView.hidden) {
        return;
    }
    if (gesture.state == UIGestureRecognizerStateBegan) {
        !self.longPressHandler ?: self.longPressHandler(self.tag);
    }
}

- (void)maskViewButtonAction {
    if (self.buttonHandler) {
        self.buttonHandler(self.maskView.status);
    }
}

- (void)animateLossMaskViewButtonAction {
    self.animateLossMaskView.hidden = YES;
    if (self.animateLossButtonHandler) {
        self.animateLossButtonHandler();
    }
}

#pragma mark - Public

// 开启loading
- (void)startLoading {
    if (!_loadingView) {
        _loadingView = [[PLVLSDocumentLoadingView alloc] init];
        _loadingView.backgroundColor = PLV_UIColorFromRGBA(@"#000000", 0.4f);
    }
    [self.loadingView startAnimating];
    [self.contentView addSubview:self.loadingView];
    self.loadingView.frame = self.pptImageView.frame;
}

// 关闭loading
- (void)stopLoading {
    if (self.loadingView) {
        [self.loadingView stopAnimating];
        [self.loadingView removeFromSuperview];
        _loadingView = nil;
    }
}

- (void)setUploadModel:(PLVDocumentUploadModel *)uploadModel {
    UIImage *image = [PLVLSUtils imageForDocumentResource:@"plvls_doc_placeholder"];
    [self.pptImageView setImage:image];
    
    NSString *fileType = uploadModel.filePath.pathExtension;
    NSString *fileName = [uploadModel.fileName substringToIndex:(uploadModel.fileName.length - fileType.length) - 1];
    NSString *titleLabelString = [self getName:fileName fileType:fileType cutCount:0];
    self.titleLabel.text = titleLabelString;
    
    self.maskView.hidden = NO;
    self.maskView.status = uploadModel.status;
    
    __weak typeof(self) weakSelf = self;
    uploadModel.uploadProgress = ^(float progress) {
        if (uploadModel.status == NO) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.maskView updateProgress:progress];
            });
        }
    };
}

- (void)setDocumentModel:(PLVDocumentModel *)documentModel {
    NSString *titleLabelString = [self getName:documentModel.fileName fileType:documentModel.fileType cutCount:0];
    self.titleLabel.text = titleLabelString;
    
    UIImage *image = [PLVLSUtils imageForDocumentResource:@"plvls_doc_placeholder"];
    [self.pptImageView sd_setImageWithURL:[NSURL URLWithString:documentModel.previewImage] placeholderImage:image options:SDWebImageRetryFailed];

    BOOL animateLoss = [PLVDocumentConvertManager isAnimateLossFromCacheWithFileId:documentModel.fileId];
    self.animateLossMaskView.hidden = !animateLoss;
    self.maskView.hidden = YES;
}

#pragma mark - Private

// 文件名省略号处理
- (NSString *)getName:(NSString *)fileName fileType:(NSString *)fileType cutCount:(NSInteger)cutCount {
    if (!fileName || ![fileName isKindOfClass:[NSString class]]) {
        fileName = @"";
    }
    if (!fileType || ![fileType isKindOfClass:[NSString class]]) {
        fileType = @"";
    }
    
    NSString *string = [NSString stringWithFormat:@"%@.%@", fileName, fileType];
    if (cutCount > 0) {
        string = [NSString stringWithFormat:@"%@...%@", fileName, fileType];
    }
    
    CGFloat width = [string boundingRectWithSize:CGSizeMake(MAXFLOAT, 20)
                                        options:NSStringDrawingUsesLineFragmentOrigin
                                     attributes:@{NSFontAttributeName:self.titleLabel.font}
                                        context:nil].size.width;
    
    if (width > 144.0 && fileName.length > 1) {
        fileName = [fileName substringToIndex:fileName.length - 1];
        return [self getName:fileName fileType:fileType cutCount:cutCount + 1];;
    }
    
    return string;
}

@end
