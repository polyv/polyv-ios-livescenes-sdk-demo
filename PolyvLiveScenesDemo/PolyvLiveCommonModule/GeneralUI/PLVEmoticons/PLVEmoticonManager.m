//
//  PLVEmoticonManager.m
//  PLVCloudClassStreamerModul
//
//  Created by ftao on 2019/10/30.
//  Copyright © 2019 easefun. All rights reserved.
//

#import "PLVEmoticonManager.h"

@implementation PLVEmoticon

+  (instancetype)emoticonWithDictionary:(NSDictionary *)dictionary {
    if (dictionary && [dictionary isKindOfClass:NSDictionary.class]) {
        PLVEmoticon  *emoticon = [PLVEmoticon new];
        emoticon.text  = [NSString stringWithFormat:@"[%@]",dictionary[@"text"]];
        emoticon.imageName  = dictionary[@"image"];
        return emoticon;
    }  else {
        return nil;
    }
}

@end

@implementation PLVImageEmotion

+ (instancetype)imageEmoticonWithDictionary:(NSDictionary *)dictionary {
    if (dictionary && [dictionary isKindOfClass:NSDictionary.class]) {
        PLVImageEmotion *emoticon = [[PLVImageEmotion alloc] init];
        emoticon.title  = dictionary[@"title"];
        emoticon.url  = dictionary[@"url"];
        emoticon.imageId  = dictionary[@"id"];
        return emoticon;
    }  else {
        return nil;
    }
}

@end

@interface PLVEmoticonManager ()

@property (nonatomic, strong) NSBundle *emoticonBundle;

@property (nonatomic, strong) NSRegularExpression *regularExpression;

@property (nonatomic, strong) NSDictionary *emoticonDict;

@property (nonatomic, strong) NSArray<PLVEmoticon *> *models;

@end

static PLVEmoticonManager *_sharedManager = nil;

@implementation PLVEmoticonManager

+ (PLVEmoticonManager *)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[super allocWithZone:NULL] init];
    });
    return _sharedManager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self sharedManager];
}

#pragma mark - Getter

- (NSBundle *)emoticonBundle {
    if (!_emoticonBundle) {
        //_emoticonBundle = [NSBundle mainBundle];      // static library
        _emoticonBundle = [NSBundle bundleForClass:self.class]; // dynamic library
    }
    return _emoticonBundle;
}

- (NSRegularExpression *)regularExpression {
    if (!_regularExpression) {
        NSError *err;
        _regularExpression = [NSRegularExpression regularExpressionWithPattern:@"\\[[^\\[]{1,5}\\]" options:kNilOptions error:&err];
        if (err) {
            NSLog(@"regularExpression: err:%@",err.localizedDescription);
        }
    }
    return _regularExpression;
}

- (NSDictionary *)emoticonDict {
    if (!_emoticonDict) {
        [self loadEmoticonResource];
    }
    return _emoticonDict;
}

- (NSArray<PLVEmoticon *> *)models {
    if (!_models) {
        [self loadEmoticonResource];
    }
    return _models;
}

#pragma mark - Private

- (void)loadEmoticonResource {
    NSMutableArray *mModels = [NSMutableArray array];
    NSMutableDictionary *mEmoticonDict = [NSMutableDictionary dictionary];
    
    NSString *emoticonPlist = [self.emoticonBundle pathForResource:@"PLVEmoticon" ofType:@"plist"];
    NSArray<NSDictionary *> *items = [NSArray arrayWithContentsOfFile:emoticonPlist];
    for (NSDictionary *group in items) {
        if ([group[@"type"] isEqualToString:@"emoticon"]) {
            NSArray<NSDictionary *> *emoticons = group[@"emoticons"];
            [emoticons enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                PLVEmoticon *model= [PLVEmoticon emoticonWithDictionary:obj];
                if (model) {
                    [mModels addObject:model];
                    [mEmoticonDict setObject:model.imageName forKey:model.text];
                }
            }];
        }
    }
    
    _models =  [NSArray arrayWithArray:mModels];
    _emoticonDict = [NSDictionary dictionaryWithDictionary:mEmoticonDict];
}

#pragma mark - Public

- (UIImage *)imageForEmoticonName:(NSString *)emoticonName {
    NSBundle *bundle = [NSBundle bundleWithPath:[self.emoticonBundle pathForResource:@"PLVEmoticons" ofType:@"bundle"]];
    return [UIImage imageNamed:emoticonName inBundle:bundle compatibleWithTraitCollection:nil];
}

- (NSMutableAttributedString *)converEmoticonTextToEmotionFormatText:(NSString *)emoticonText attributes:(NSDictionary<NSAttributedStringKey,id> *)attributes {
    NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:emoticonText attributes:attributes];
    return [self converEmoticonTextToEmotionFormatText:attrStr font:attributes[NSFontAttributeName]];
}

- (NSMutableAttributedString *)converEmoticonTextToEmotionFormatText:(NSAttributedString *)emoticonText font:(UIFont *)font {
    NSMutableAttributedString *mAttributedStr = [[NSMutableAttributedString alloc] initWithAttributedString:emoticonText];
    NSArray<NSTextCheckingResult *> *matchArr = [self.regularExpression  matchesInString:emoticonText.string options:kNilOptions range:NSMakeRange(0, mAttributedStr.length)];
    
    NSUInteger offset = 0;
    for (NSTextCheckingResult *result in matchArr) {
        NSRange range = NSMakeRange(result.range.location - offset, result.range.length);
        
        NSString *emoticonText = [mAttributedStr.string substringWithRange:NSMakeRange(range.location, range.length)];
        NSString *imageName = self.emoticonDict[emoticonText];
        if (!imageName) {
            continue;
        }
        
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = [self imageForEmoticonName:imageName];
        attachment.bounds = CGRectMake(0, font.descender, font.lineHeight, font.lineHeight);
    
        NSAttributedString *emoticonAttrStr = [NSAttributedString attributedStringWithAttachment:attachment];
        [mAttributedStr replaceCharactersInRange:range withAttributedString:emoticonAttrStr];
        
        offset += result.range.length - emoticonAttrStr.length;
    }
    
    return mAttributedStr;
}

@end
