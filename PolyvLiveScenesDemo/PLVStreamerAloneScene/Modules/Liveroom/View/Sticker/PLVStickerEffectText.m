//
//  PLVStickerEffectText.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/7/9.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVStickerEffectText.h"
#import "PLVStickerEffectLable.h"
#import "PLVSAUtils.h"

@interface PLVStickerEffectText ()

@property (nonatomic, strong) PLVStickerEffectLable *effectLable; // 前景文本标签组件
@property (nonatomic, strong) PLVStickerEffectLable *backEffectLable; // 背景文本标签组件

@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UIImageView *tipsIcon;

@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) PLVStickerTextTemplateType templateType;

@end

@implementation PLVStickerEffectText

- (instancetype)initWithText:(NSString *)text templateType:(PLVStickerTextTemplateType)templateType {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.text = text;
        self.templateType = templateType;

        [self setupUI];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
        
//    [self configEffectLable:self.templateType];
    [self configEffectUI:self.templateType];
}

- (void)setupUI {
    self.bgImageView = [[UIImageView alloc] init];
    [self addSubview:self.bgImageView];

    self.tipsIcon = [[UIImageView alloc] init];
    [self addSubview:self.tipsIcon];

    // 前景标签
    self.effectLable = [[PLVStickerEffectLable alloc] init];
    self.effectLable.text = self.text;
    [self configEffectLable:self.templateType];
    
    // 背景标签
    self.backEffectLable = [[PLVStickerEffectLable alloc] init];
    self.backEffectLable.text = self.text;
    [self configBackEffectLable:self.templateType];
    
    [self configEffectUI:self.templateType];

    [self addSubview:self.backEffectLable];
    [self addSubview:self.effectLable];

}

- (void)updateText:(NSString *)text templateType:(PLVStickerTextTemplateType)templateType {
    self.text = text;
    self.effectLable.text = self.text;
    self.backEffectLable.text = self.text;

    self.templateType = templateType;

    [self configEffectLable:templateType];
    [self configBackEffectLable:templateType];
    
    [self configEffectUI:templateType];

    // 父视图动态调整自己的宽度

}

- (void)updateText:(NSString *)text{
    
    [self updateText:text templateType:self.templateType];
    
    // 父视图动态调整自己的宽度
}

- (void)configEffectLable:(PLVStickerTextTemplateType )templateType{
    PLVStickerTextTemplate *template = [PLVStickerTextTemplate defaultTextTemplateWithTemplateType:templateType];
    self.effectLable.textColor = template.textColor;
    self.effectLable.backgroundColor = template.backgroundColor;
    self.effectLable.font = [UIFont fontWithName:template.fontName size:template.fontSize];
    self.effectLable.textAlignment = template.textAlignment;
    self.effectLable.strokeWidth = template.strokeWidth;
    self.effectLable.strokeColor = template.strokeColor;
    self.effectLable.textInsets = template.textInsets;
    self.effectLable.customShadowOffset = template.customShadowOffset;
    self.effectLable.customShadowBlurRadius = template.customShadowBlurRadius;
    self.effectLable.customShadowColor = template.customShadowColor;
}

- (void)configBackEffectLable:(PLVStickerTextTemplateType )templateType{
    if (templateType == PLVStickerTextTemplateType0 || templateType == PLVStickerTextTemplateType1){
        PLVStickerTextTemplate *template = [PLVStickerTextTemplate defaultTextTemplateWithTemplateType:templateType];
        self.backEffectLable.textColor = template.textColor;
        self.backEffectLable.backgroundColor = template.backgroundColor;
        self.backEffectLable.font = [UIFont fontWithName:template.fontName size:template.fontSize];
        self.backEffectLable.textAlignment = template.textAlignment;
        self.backEffectLable.strokeWidth = template.backStrokeWidth;
        self.backEffectLable.strokeColor = template.backStrokeColor;
        self.backEffectLable.textInsets = template.textInsets;
        self.backEffectLable.customShadowOffset = template.customShadowOffset;
        self.backEffectLable.customShadowBlurRadius = template.customShadowBlurRadius;
        self.backEffectLable.customShadowColor = template.customShadowColor;
    }
}
    
- (void)configEffectUI:(PLVStickerTextTemplateType )templateType{
    // 计算文本尺寸
    CGSize textSize = [self calculateTextSize];
    CGFloat padding = 16.0;
    CGFloat width = textSize.width + padding * 2;
    CGFloat height = textSize.height + 10;
    
    self.effectLable.frame = CGRectMake(0, 0, textSize.width, textSize.height);
    self.effectLable.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    
    // 设置背景和图标的基础框架
    self.bgImageView.frame = CGRectMake(0, 0, width, height);
    self.bgImageView.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    self.bgImageView.backgroundColor = [UIColor clearColor];
    
    // 根据模板类型设置不同的样式
    switch (self.templateType) {
        case PLVStickerTextTemplateType0: // 关注主播
            self.bgImageView.hidden = YES;
            self.tipsIcon.hidden = YES;
            
            // 背景标签 层叠描边效果
            self.backEffectLable.hidden = NO;
            NSInteger startX = CGRectGetMinX(self.effectLable.frame) - 2;
            NSInteger startY = CGRectGetMinY(self.effectLable.frame) + 2;
            CGRect backEffectRect = CGRectMake(startX, startY, textSize.width + 4, textSize.height);
            self.backEffectLable.frame = backEffectRect;
            break;
            
        case PLVStickerTextTemplateType1: // 限时抢购
            self.bgImageView.hidden = YES;
            self.tipsIcon.hidden = YES;
            
            // 背景标签 层叠描边效果
            self.backEffectLable.hidden = NO;
            startX = CGRectGetMinX(self.effectLable.frame) - 2 ;
            startY = CGRectGetMinY(self.effectLable.frame) - 1;
            backEffectRect = CGRectMake(startX, startY, textSize.width + 4 , textSize.height + 4);
            self.backEffectLable.frame = backEffectRect;
            break;
            
        case PLVStickerTextTemplateType2: // 新品推荐
        {
            self.bgImageView.hidden = NO;
            UIImage *bgImage = [PLVSAUtils imageForLiveroomResource:@"plv_sticker_effect_text_bg_2"];
            UIEdgeInsets insets = UIEdgeInsetsMake(bgImage.size.height * 0.5  , bgImage.size.width * 0.5  , bgImage.size.height * 0.5 , bgImage.size.width * 0.5 );
            self.bgImageView.image = [bgImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
            // 文本向右偏移10个像素
            CGPoint orig = self.effectLable.center;
            self.effectLable.center = CGPointMake(orig.x + 10, orig.y);

            self.tipsIcon.hidden = YES;
            self.backEffectLable.hidden = YES;
            break;
        }
            
        case PLVStickerTextTemplateType3: // 精品课程
            self.bgImageView.hidden = NO;
            self.bgImageView.image = nil;
            self.bgImageView.backgroundColor = [UIColor yellowColor];
            self.tipsIcon.hidden = NO;
            self.tipsIcon.image = [PLVSAUtils imageForLiveroomResource:@"plv_sticker_effect_text_tips_3"];
            self.backEffectLable.hidden = YES;

            // 设置提示图标在右下角
            self.tipsIcon.frame = CGRectMake(CGRectGetMaxX(self.bgImageView.frame) - 10, height - 5, 20, 20);
            break;
            
        case PLVStickerTextTemplateType4: // 分享有礼
        {
            self.bgImageView.hidden = NO;
            UIImage *bgImage = [PLVSAUtils imageForLiveroomResource:@"plv_sticker_effect_text_bg_4"];
            UIEdgeInsets insets = UIEdgeInsetsMake(bgImage.size.height * 0.5, bgImage.size.width * 0.5, bgImage.size.height * 0.5, bgImage.size.width * 0.5);
            self.bgImageView.image = [bgImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
            self.tipsIcon.hidden = YES;
            self.backEffectLable.hidden = YES;

            break;
        }
            
        case PLVStickerTextTemplateType5: // 精品课程(气泡)
        {
            self.bgImageView.hidden = NO;
            UIImage *bgImage = [PLVSAUtils imageForLiveroomResource:@"plv_sticker_effect_text_bg_5"];
            UIEdgeInsets insets = UIEdgeInsetsMake(bgImage.size.height * 0.5, bgImage.size.width * 0.5, bgImage.size.height * 0.5, bgImage.size.width * 0.5);
            self.bgImageView.image = [bgImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
            self.tipsIcon.hidden = YES;
            self.backEffectLable.hidden = YES;

            break;
        }
            
        case PLVStickerTextTemplateType6: // 扫码关注
            self.bgImageView.hidden = YES;
            self.tipsIcon.hidden = NO;
            self.tipsIcon.image = [PLVSAUtils imageForLiveroomResource:@"plv_sticker_effect_text_tips_6"];
            
            // 设置提示图标在左侧
            CGSize iconSize = self.tipsIcon.image.size;
            self.tipsIcon.frame = CGRectMake(self.effectLable.frame.origin.x - iconSize.width, (self.bounds.size.height - iconSize.height)/2, iconSize.width, iconSize.height);
            
            self.backEffectLable.hidden = YES;

            break;
            
        case PLVStickerTextTemplateType7: // 看这里
            self.bgImageView.hidden = YES;
            self.tipsIcon.hidden = NO;
            self.tipsIcon.image = [PLVSAUtils imageForLiveroomResource:@"plv_sticker_effect_text_tips_7"];
            
            // 设置提示图标在左侧（与扫码关注类似）
            self.tipsIcon.frame = CGRectMake(self.effectLable.frame.origin.x - 20, self.effectLable.frame.origin.y, 20, 20);
            
            self.backEffectLable.hidden = YES;

            break;
            
        default:
            self.bgImageView.hidden = YES;
            self.tipsIcon.hidden = YES;
            self.backEffectLable.hidden = YES;

            break;
    }
}
        

// 计算文本尺寸的辅助方法
- (CGSize)calculateTextSize {
    if (!self.text || self.text.length == 0) {
        return CGSizeZero;
    }
    
    UIFont *font = self.effectLable.font;
    if (!font) {
        font = [UIFont systemFontOfSize:18.0]; // 默认字体大小
    }
    
    CGSize maxSize = CGSizeMake(MAXFLOAT, self.bounds.size.height);
    CGSize textSize = [self.text boundingRectWithSize:maxSize
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName: font}
                                              context:nil].size;
    
    return textSize;
}

- (CGFloat)getBoundWidthForText{
    CGFloat width = [self calculateTextSize].width + self.tipsIcon.image.size.width + 50;
    return width;
}

@end
