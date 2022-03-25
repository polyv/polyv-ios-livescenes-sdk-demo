//
//  PLVHCDocumentListCellMaskView.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/6/30.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCDocumentListCellMaskView.h"

// 工具
#import "PLVHCUtils.h"

// 依赖库
#import <PLVLiveScenesSDK/PLVLiveScenesSDK.h>
#import <PLVFoundationSDK/PLVFoundationSDK.h>

#pragma mark - PLVHCDocumentProgressView -

@interface PLVHCDocumentProgressView : UIView

#pragma mark UI

@property (nonatomic, strong) CAShapeLayer *backLayer;

@property (nonatomic, strong) CAShapeLayer *ringLayer;

#pragma mark 数据

@property (nonatomic, assign) CGFloat ringRadius;

@property (nonatomic, assign) CGFloat progress;

- (instancetype)initWithRadius:(CGFloat)radius;

- (void)updateProgress:(CGFloat)progrss;

@end

@implementation PLVHCDocumentProgressView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithRadius:(CGFloat)radius {
    self = [[PLVHCDocumentProgressView alloc] initWithFrame:CGRectMake(0, 0, radius * 2, radius * 2)];
    self.backgroundColor = [UIColor clearColor];
    self.ringRadius = radius;
    
    [self addBackLayerToSuperLayer];
    [self addRingLayerToSuperLayer];
    
    [self updateProgress:0];
    return self;
}

#pragma mark - [ Public Method ]

- (void)updateProgress:(CGFloat)progrss {
    if (progrss < 0) {
        _progress = 0;
    } else if (progrss < 1) {
        _progress = progrss;
    } else {
        _progress = 1;
    }
    
    self.ringLayer.strokeEnd = progrss;
}

#pragma mark - [ Private Method ]

- (void)addBackLayerToSuperLayer {
    if (_backLayer.superlayer) {
        [_backLayer removeFromSuperlayer];
        _backLayer = nil;
    }
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.ringRadius, self.ringRadius) radius:self.ringRadius startAngle:-M_PI_2 endAngle:3*M_PI_2 clockwise:YES];
    CAShapeLayer *layer = [CAShapeLayer layer];
    
    layer.lineWidth = 2;
    layer.strokeColor = [PLVColorUtil colorFromHexString:@"#FFFFFF"].CGColor;
    layer.path = path.CGPath;
    layer.bounds = (CGRect){0, 0, self.ringRadius * 2, self.ringRadius * 2};
    
    // 填充颜色，默认为black，nil为不填充
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.position = CGPointMake(self.ringRadius, self.ringRadius);
    layer.strokeEnd = 1;
    [self.layer addSublayer:layer];
    _backLayer = layer;
}

- (void)addRingLayerToSuperLayer {
    if (_ringLayer.superlayer) {
        [_ringLayer removeFromSuperlayer];
        _ringLayer = nil;
    }
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.ringRadius, self.ringRadius) radius:self.ringRadius startAngle:-M_PI_2 endAngle:3*M_PI_2 clockwise:YES];
    CAShapeLayer *layer = [CAShapeLayer layer];
    
    layer.lineWidth = 2;
    layer.strokeColor = [PLVColorUtil colorFromHexString:@"#366BEE"].CGColor;
    layer.path = path.CGPath;
    layer.bounds = (CGRect){0, 0, self.ringRadius * 2, self.ringRadius * 2};
    
    // 填充颜色，默认为black，nil为不填充
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.position = CGPointMake(self.ringRadius, self.ringRadius);
    layer.strokeEnd = 0;
    [self.layer addSublayer:layer];
    _ringLayer = layer;
}

@end

#pragma mark - PLVHCDocumentListCellMaskView -

@interface PLVHCDocumentListCellMaskView ()

@property (nonatomic, strong) UIView *bgMaskView;
@property (nonatomic, strong) PLVHCDocumentProgressView *processView;
@property (nonatomic, strong) UILabel *redLabel;
@property (nonatomic, strong) UILabel *whiteLabel;

@property (nonatomic, assign) BOOL loss;

@end

@implementation PLVHCDocumentListCellMaskView

#pragma mark - [ Life Cycle ]

- (instancetype)initWithAnimateLoss:(BOOL)loss {
    self = [super init];
    if (self) {
        self.loss = loss;
        
        [self addSubview:self.bgMaskView];
        if (loss) {
            self.whiteLabel.text = @"动效丢失，已转换为图片";
            [self addSubview:self.whiteLabel];
            
            [self.button setTitle:@"知道了" forState:UIControlStateNormal];
            [self addSubview:self.button];
        } else {
            [self addSubview:self.processView];

            self.whiteLabel.hidden = YES;
            [self addSubview:self.whiteLabel];
            [self addSubview:self.redLabel];
            [self addSubview:self.button];
        }
    }
    return self;
}

- (instancetype)init {
    self = [self initWithAnimateLoss:NO];
    return self;
}

- (void)layoutSubviews {
    self.bgMaskView.frame = self.bounds;
    
    if (self.loss) {
        self.whiteLabel.frame = CGRectMake(0, (self.bounds.size.height - 48)/2.0, self.bounds.size.width, 14);
        self.button.frame = CGRectMake((self.bounds.size.width - 66) / 2.0, CGRectGetMaxY(self.whiteLabel.frame) + 10, 66.0, 24.0);
    } else {
        CGPoint center = CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
        
        self.processView.center = center;
        
        self.whiteLabel.frame = CGRectMake(0, 0, self.bounds.size.width, 14);
        self.whiteLabel.center = center;
        
        self.redLabel.frame = CGRectMake(0, (self.bounds.size.height - 48)/2.0, self.bounds.size.width, 14);
        self.button.frame = CGRectMake((self.bounds.size.width - 66) / 2.0, CGRectGetMaxY(self.redLabel.frame) + 10, 66.0, 24.0);
    }
    
    [super layoutSubviews];
}

#pragma mark - [ Public Method ]

- (void)updateProgress:(CGFloat)progrss {
    if (progrss <= self.processView.progress) {
        return;
    }
    [self.processView updateProgress:progrss];
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (UIView *)bgMaskView {
    if (!_bgMaskView) {
        _bgMaskView = [[UIView alloc] init];
        _bgMaskView.backgroundColor = [PLVColorUtil colorFromHexString:@"#1A1B1F" alpha:0.7];
    }
    return _bgMaskView;
}

- (UILabel *)whiteLabel {
    if (!_whiteLabel) {
        _whiteLabel = [[UILabel alloc] init];
        _whiteLabel.font = [UIFont systemFontOfSize:12];
        _whiteLabel.textColor = [UIColor whiteColor];
        _whiteLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _whiteLabel;
}

- (UILabel *)redLabel {
    if (!_redLabel) {
        _redLabel = [[UILabel alloc] init];
        _redLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _redLabel;
}

- (PLVHCDocumentProgressView *)processView {
    if (!_processView) {
        _processView = [[PLVHCDocumentProgressView alloc] initWithRadius:15];
        _processView.hidden = YES;
    }
    return _processView;
}

- (UIButton *)button {
    if (!_button) {
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.backgroundColor = [PLVColorUtil colorFromHexString:@"#1A1B1F"];
        _button.titleLabel.font = [UIFont systemFontOfSize:12];
        _button.layer.cornerRadius = 12.0;
        _button.layer.borderColor = [UIColor whiteColor].CGColor;
        _button.layer.borderWidth = 1.0;
    }
    return _button;
}

#pragma mark Setter

- (void)setStatus:(PLVDocumentUploadStatus)status {
    if (self.loss) {
        return;
    }
    
    if (status == PLVDocumentUploadStatusUploading) {
        if (_status != PLVDocumentUploadStatusUploading) {
            [self.processView updateProgress:0];
        }
        self.processView.hidden = NO;
        self.whiteLabel.hidden = self.redLabel.hidden = self.button.hidden = YES;
    } else if (status == PLVDocumentUploadStatusFailure ||
               status == PLVDocumentUploadStatusConvertFailure) {
        self.redLabel.hidden = NO;
        self.button.hidden = NO;
        self.processView.hidden = self.whiteLabel.hidden = YES;
        NSString *text = (status == PLVDocumentUploadStatusFailure) ? @"上传失败" : @"无法解码";
        [self setRedLabelText:text];
        NSString *buttonTitle = (status == PLVDocumentUploadStatusFailure) ? @"重试" : @"帮助";
        [self.button setTitle:buttonTitle forState:UIControlStateNormal];
    } else if (status == PLVDocumentUploadStatusSuccess) {
        self.whiteLabel.hidden = NO;
        self.processView.hidden = self.redLabel.hidden = self.button.hidden = YES;
        self.whiteLabel.text = @"等待转码...";
    }
    _status = status;
}

#pragma mark NSMutableAttributedString

- (void)setRedLabelText:(NSString *)text {
    NSMutableAttributedString *muString = [[NSMutableAttributedString alloc] init];
    UIImage *image = [PLVHCUtils imageForDocumentResource:@"plvhc_doc_icon_error"];
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = image;
    attachment.bounds = CGRectMake(0, -2, 14, 14);
    [muString appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
    
    NSDictionary *attributeDict = @{NSFontAttributeName:[UIFont systemFontOfSize:12],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#F24453"]};
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", text]
                                                                 attributes:attributeDict];
    [muString appendAttributedString:string];
    
    self.redLabel.attributedText = [muString copy];
}

@end
