//
//  PLVLiveMarqueeStyleModel.m
//  PLVFoundationSDK
//
//  Created by PLV-UX on 2021/3/10.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLiveMarqueeModel.h"
#import "PLVMultiLanguageManager.h"

@interface PLVLiveMarqueeModel ()

/// 富文本字符串属性
@property (nonatomic, strong) NSMutableDictionary *attributes;
/// 第二个隐藏跑马灯的富文本字符串属性
@property (nonatomic, strong) NSMutableDictionary *secondAttributes;

@end

static NSString *StringValueWithJsonValue(id obj) {
    if (obj && ![obj isKindOfClass:[NSNull class]]) {
        return [NSString stringWithFormat:@"%@",obj];
    } else {
        return nil;
    }
}

static NSInteger IntegerValueWithJsonValue(id obj) {
    if (obj && [obj isKindOfClass:[NSObject class]]) {
        return [[NSString stringWithFormat:@"%@",obj] integerValue];
    } else {
        return 0;
    }
}

static float FloatValueWithJsonValue(id obj) {
    if (obj && [obj isKindOfClass:[NSObject class]]) {
        return [[NSString stringWithFormat:@"%@",obj] floatValue];
    } else {
        return 0.0;
    }
}

@implementation PLVLiveMarqueeModel
- (instancetype)init {
    if (self = [super init]) {
        _style = PLVLiveMarqueeModelStyleRoll;
        _content = PLVLocalizedString(@"PLV跑马灯");
        _fontSize = 30;
        _fontColor = @"#000000";
        _outline = NO;
        _outlineColor = @"#000000";
        _shadowAlpha = 1;
        _shadowBlurRadius = 4;
        _shadowOffsetX = 2;
        _shadowOffsetY = 2;
        _alpha = 1;
        _secondMarqueeAlpha = 0.02;
        _tweenTime = 1;
        _interval = 5;
        _lifeTime = 3;
        _speed = 20;
        _isHiddenWhenPause = YES;
        _isAlwaysShowWhenRun = NO;
    }
    return self;
}

/// 初始化最简单的跑马灯样式model
/// @param content 跑马灯内容
/// @param fontSize 字体大小
/// @param fontColor 字体颜色（0x000000）
/// @param alpha 文本透明度（范围：0~1）
/// @param style 动画类型
+ (instancetype)createMarqueeModelWithContent:(NSString *)content
                                     fontSize:(NSUInteger)fontSize
                                        speed:(NSUInteger)speed
                                    fontColor:(NSString *)fontColor
                                        alpha:(float)alpha
                                        style:(PLVLiveMarqueeModelStyle)style {
    PLVLiveMarqueeModel *model = [[PLVLiveMarqueeModel alloc]init];
    model.content = content;
    model.fontSize = fontSize;
    model.fontColor = [fontColor stringByReplacingOccurrencesOfString:@"0x" withString:@"#"];
    model.alpha = alpha <= 0 ? 1.0 : alpha;
    model.style = style;
    
    //default
    model.speed = speed <= 0 ? 20 : speed;
    model.outline = YES;
    model.outlineColor = @"#FFFFFF";
    return model;
}

/// 初始化跑马灯样式model（适用于自定义url方式获取的跑马灯数据转换为model）
/// @param marqueeDict 跑马灯数据
+ (instancetype)createMarqueeModelWithMarqueeDict:(NSDictionary *)marqueeDict {
    if (!marqueeDict
        || ![StringValueWithJsonValue(marqueeDict[@"show"]) isEqualToString:@"on"]) {
        return nil;
    }
    PLVLiveMarqueeModel *model = [[PLVLiveMarqueeModel alloc]init];
    model.errorMessage = StringValueWithJsonValue(marqueeDict[@"msg"]);
    model.style = IntegerValueWithJsonValue(marqueeDict[@"setting"]);
    model.content = StringValueWithJsonValue(marqueeDict[@"username"]);
    model.fontSize = IntegerValueWithJsonValue(marqueeDict[@"fontSize"]);
    model.fontColor = [StringValueWithJsonValue(marqueeDict[@"fontColor"]) stringByReplacingOccurrencesOfString:@"0x" withString:@"#"];
    
    model.outline = [StringValueWithJsonValue(marqueeDict[@"filter"]) isEqualToString:@"on"];
    model.shadowAlpha = FloatValueWithJsonValue(marqueeDict[@"filterAlpha"]);
    model.outlineColor = [StringValueWithJsonValue(marqueeDict[@"filterColor"]) stringByReplacingOccurrencesOfString:@"0x" withString:@"#"];
    model.shadowBlurRadius = IntegerValueWithJsonValue(marqueeDict[@"strength"]);
    model.shadowOffsetX = IntegerValueWithJsonValue(marqueeDict[@"blurX"]);
    model.shadowOffsetY = IntegerValueWithJsonValue(marqueeDict[@"blurY"]);
    
    model.alpha = FloatValueWithJsonValue(marqueeDict[@"alpha"]);
    if (model.alpha <= 0) {
        model.alpha = 1.0;
    }
    model.speed = IntegerValueWithJsonValue(marqueeDict[@"speed"])  / 10;
    model.interval = IntegerValueWithJsonValue(marqueeDict[@"interval"]);
    model.lifeTime = IntegerValueWithJsonValue(marqueeDict[@"lifeTime"]);
    model.tweenTime = IntegerValueWithJsonValue(marqueeDict[@"tweenTime"]);
    
    return model;
}


#pragma mark - 生成跑马灯描述

/// 根据模型内容生成描述跑马灯的富文本
- (NSAttributedString *)createMarqueeAttributedContent {
    if (self.content.length) {
        NSMutableAttributedString *mAttributedStr = [[NSMutableAttributedString alloc] initWithString:self.content attributes:self.attributes];
        return mAttributedStr;
    }
    return nil;
}

/// 根据富文本内容计算size
- (CGSize)marqueeAttributedContentSize {
    if (self.content.length) {
        return [self.content sizeWithAttributes:self.attributes];
    }
    return CGSizeZero;
}

- (NSAttributedString *)createSecondMarqueeAttributedContent {
    if (self.content.length) {
        NSMutableAttributedString *mAttributedStr = [[NSMutableAttributedString alloc] initWithString:self.content attributes:self.secondAttributes];
        return mAttributedStr;
    }
    return nil;
}

-(CGSize)secondmarqueeAttributedContentSize {
    if (self.content.length) {
        return [self.content sizeWithAttributes:self.secondAttributes];
    }
    return CGSizeZero;
}

#pragma mark - Loadlazy

- (NSMutableDictionary *)attributes {
    if (!_attributes) {
        _attributes = [NSMutableDictionary dictionaryWithObject:[UIFont systemFontOfSize:self.fontSize] forKey:NSFontAttributeName];
        [_attributes setObject:[self colorFromHexString:self.fontColor] forKey:NSForegroundColorAttributeName];
        if (self.outline) {
            [_attributes setObject:@(-2.0) forKey:NSStrokeWidthAttributeName];
            [_attributes setObject:[self colorFromHexString:self.outlineColor] forKey:NSStrokeColorAttributeName];
            
            NSShadow * shadow = [[NSShadow alloc] init];
            shadow.shadowBlurRadius = self.shadowBlurRadius;
            shadow.shadowColor = [UIColor colorWithWhite:0.0 alpha:self.shadowAlpha];
            shadow.shadowOffset = CGSizeMake(self.shadowOffsetX, self.shadowOffsetY);
            [_attributes setObject:shadow forKey:NSShadowAttributeName];
        }
    }
    return _attributes;
}

-(NSMutableDictionary *)secondAttributes
{
    if (!_secondAttributes) {
        _secondAttributes = [NSMutableDictionary dictionaryWithObject:[UIFont systemFontOfSize:self.fontSize] forKey:NSFontAttributeName];
        [_secondAttributes setObject:[UIColor blackColor] forKey:NSForegroundColorAttributeName];
        [_secondAttributes setObject:@(-2.0) forKey:NSStrokeWidthAttributeName];
        [_secondAttributes setObject:[UIColor whiteColor] forKey:NSStrokeColorAttributeName];
        
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowBlurRadius = self.shadowBlurRadius;
        shadow.shadowColor = [UIColor colorWithWhite:0.0 alpha:self.shadowAlpha];
        shadow.shadowOffset = CGSizeMake(self.shadowOffsetX, self.shadowOffsetY);
        [_secondAttributes setObject:shadow forKey:NSShadowAttributeName];
    }
    return _secondAttributes;
}


#pragma mark - Privates

/// 生成颜色UIColor
/// @param hexString 颜色值
- (UIColor *)colorFromHexString:(NSString *)hexString {
    if (!hexString) {
        return [UIColor whiteColor];
    }
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    if ([hexString rangeOfString:@"#"].location == 0) {
        [scanner setScanLocation:1];
    }
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

@end
