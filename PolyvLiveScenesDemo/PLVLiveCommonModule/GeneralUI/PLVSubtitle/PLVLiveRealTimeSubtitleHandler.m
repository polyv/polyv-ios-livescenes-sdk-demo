//
//  PLVLiveRealTimeSubtitleHandler.m
//  PolyvLiveScenesDemo
//

#import "PLVLiveRealTimeSubtitleHandler.h"
#import "PLVLiveSubtitleSocketEvent.h"
#import "PLVRoomDataManager.h"
#import <PLVLiveScenesSDK/PLVSocketManager.h>
#import <PLVLiveScenesSDK/PLVLiveVideoAPI.h>

@interface PLVLiveRealTimeSubtitleHandler ()

@property (nonatomic, copy) NSString *channelId;
@property (nonatomic, copy) NSString *viewerId;
@property (nonatomic, assign) BOOL isInitial;
@property (nonatomic, assign) NSInteger subtitleLimit;

@property (nonatomic, strong, nullable) PLVLiveSubtitleModel *realTimeSubtitle;
@property (nonatomic, strong) NSMutableArray<PLVLiveSubtitleTranslation *> *translations;
@property (nonatomic, assign) BOOL enableSubtitle;
@property (nonatomic, assign) BOOL showSubtitle;

@property (nonatomic, copy, nullable) NSString *originLanguage;
@property (nonatomic, copy, nullable) NSString *translateLanguage;

/// 字幕处理队列（串行队列，保证线程安全）
@property (nonatomic, strong) dispatch_queue_t subtitleProcessQueue;

@end

@implementation PLVLiveRealTimeSubtitleHandler

- (instancetype)init {
    if (self = [super init]) {
        _translations = [NSMutableArray array];
        _subtitleProcessQueue = dispatch_queue_create("com.plv.livescenes.subtitle.process", DISPATCH_QUEUE_SERIAL);
        _subtitleLimit = NSIntegerMax;
    }
    return self;
}

#pragma mark - Public Methods

- (void)initDataWithChannelId:(NSString *)channelId viewerId:(NSString *)viewerId {
    if (self.isInitial) {
        return;
    }
    
    self.isInitial = YES;
    self.channelId = channelId;
    self.viewerId = viewerId;
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.subtitleProcessQueue, ^{
        // 获取频道字幕配置
        PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
        PLVLiveRealTimeSubtitleConfig *subtitleConfig = roomData.menuInfo.realTimeSubtitleConfig;
        
        if (subtitleConfig) {
            // 设置字幕启用状态
            weakSelf.enableSubtitle = subtitleConfig.realTimeSubtitleEnabled;
            weakSelf.showSubtitle = subtitleConfig.realTimeSubtitleEnabled;
            
            // 设置语言
            weakSelf.originLanguage = subtitleConfig.subtitleSourceLanguage;
            weakSelf.translateLanguage = subtitleConfig.subtitleTranslationEnabled ?subtitleConfig.subtitleTranslationLanguage:@"origin";
            // 双语显示
            if (![weakSelf.translateLanguage isEqualToString:@"origin"]){
                weakSelf.bilingualSubtitleEnabled = YES;
            }
            
            // 设置字幕条数限制
            // 根据后台配置：如果开启了条数限制开关且有配置条数，则使用配置的值；否则不限制
            if (subtitleConfig.realTimeSubtitleDisplayNumberLimitEnabled && 
                subtitleConfig.realTimeSubtitleDisplayNumber != nil) {
                NSInteger displayNumber = [subtitleConfig.realTimeSubtitleDisplayNumber integerValue];
                weakSelf.subtitleLimit = displayNumber > 0 ? displayNumber : NSIntegerMax;
                NSLog(@"PLVLiveRealTimeSubtitleHandler - 字幕条数限制已启用: %ld 条", (long)weakSelf.subtitleLimit);
            } else {
                weakSelf.subtitleLimit = NSIntegerMax;
                NSLog(@"PLVLiveRealTimeSubtitleHandler - 字幕条数不限制");
            }
        } else {
            // 没有配置，使用默认值
            weakSelf.enableSubtitle = YES;
            weakSelf.showSubtitle = YES;
            weakSelf.subtitleLimit = NSIntegerMax;
            NSLog(@"PLVLiveRealTimeSubtitleHandler - 未找到字幕配置，使用默认值");
        }
        
        // 从API加载当前字幕历史
        // [weakSelf loadCurrentSubtitleFromApi];
    });
}

- (void)handleSubtitleSocketMessage:(NSString *)event message:(id)message {
    if (!message) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.subtitleProcessQueue, ^{
        NSDictionary *dict = nil;
        if ([message isKindOfClass:[NSString class]]) {
            NSError *error = nil;
            NSData *jsonData = [(NSString *)message dataUsingEncoding:NSUTF8StringEncoding];
            dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
            if (error) {
                return;
            }
        } else if ([message isKindOfClass:[NSDictionary class]]) {
            dict = (NSDictionary *)message;
        } else {
            return;
        }
        
        if ([event isEqualToString:@"ADD"]) {
            [weakSelf handleSubtitleSocketMessageAdd:dict];
        } else if ([event isEqualToString:@"TRANSLATE"]) {
            [weakSelf handleSubtitleSocketMessageTranslate:dict];
        } else if ([event isEqualToString:@"ENABLE"]) {
            [weakSelf handleSubtitleSocketMessageEnable:dict];
        }
    });
}

- (void)setTranslateLanguage:(NSString *)language {
    if (!language || language.length == 0) {
        return;
    }
    
    if ([language isEqualToString:@"origin"]){
        _translateLanguage = language;
        return;
    }
    
    // 格式化语言代码（首字母大写）
    NSString *formattedLanguage = [language stringByReplacingCharactersInRange:NSMakeRange(0, 1) 
                                                                     withString:[[language substringToIndex:1] uppercaseString]];
    
    if ([self.translateLanguage isEqualToString:formattedLanguage]) {
        return;
    }
    
    _translateLanguage = formattedLanguage;
    
    // 立即清空旧的翻译数据，避免显示上一种语言的翻译
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.subtitleProcessQueue, ^{
        // 清空所有字幕的翻译部分
        NSMutableArray *clearedTranslations = [NSMutableArray array];
        for (PLVLiveSubtitleTranslation *translation in weakSelf.translations) {
            PLVLiveSubtitleTranslation *clearedTranslation = [[PLVLiveSubtitleTranslation alloc] initWithIndex:translation.index
                                                                                                         origin:translation.origin
                                                                                                    translation:nil];
            [clearedTranslations addObject:clearedTranslation];
        }
        weakSelf.translations = clearedTranslations;
        
        // 立即通知UI更新，显示清空后的状态
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([weakSelf.delegate respondsToSelector:@selector(subtitleHandler:didUpdateAllSubtitles:)]) {
                [weakSelf.delegate subtitleHandler:weakSelf didUpdateAllSubtitles:[weakSelf.translations copy]];
            }
        });
    });
    
    // 发送Socket消息，订阅指定语言的翻译
    NSDictionary *params = @{
        @"EVENT": @"LISTEN_LANGUAGE",
        @"language": formattedLanguage
    };
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
    if (!error && jsonData) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        // 注意：这里使用PLVSocketManager的方式发送消息
        [[PLVSocketManager sharedManager] emitEvent:@"subtitles" content:jsonString];
        NSLog(@"PLVLiveRealTimeSubtitleHandler - 发送语言切换Socket消息: %@", jsonString);
    }
    
    // 重新加载新语言的翻译字幕
    dispatch_async(self.subtitleProcessQueue, ^{
        [weakSelf loadCurrentSubtitleFromApi:NO loadTranslation:YES];
    });
}

#pragma mark - Private Methods

/// 处理 ADD 事件
- (void)handleSubtitleSocketMessageAdd:(NSDictionary *)dict {
    PLVLiveSubtitleSocketEventAdd *event = [PLVLiveSubtitleSocketEventAdd modelWithDictionary:dict];
    if (!event || !event.index) {
        return;
    }
    
    // 更新实时字幕（单条）
    PLVLiveSubtitleModel *currentRealTime = self.realTimeSubtitle;
    self.realTimeSubtitle = [self handleSubtitleAppend:currentRealTime event:event];
    
    // 更新字幕列表（包含原文字幕和翻译字幕）
    PLVLiveSubtitleTranslation *currentTranslation = nil;
    for (PLVLiveSubtitleTranslation *translation in self.translations) {
        if (translation.index == event.index.integerValue) {
            currentTranslation = translation;
            break;
        }
    }
    
    PLVLiveSubtitleTranslation *newTranslation = nil;
    if (currentTranslation) {
        PLVLiveSubtitleModel *newOrigin = [self handleSubtitleAppend:currentTranslation.origin event:event];
        newTranslation = [[PLVLiveSubtitleTranslation alloc] initWithIndex:event.index.integerValue
                                                                    origin:newOrigin
                                                               translation:currentTranslation.translation];
    } else {
        PLVLiveSubtitleModel *newOrigin = [self handleSubtitleAppend:nil event:event];
        newTranslation = [[PLVLiveSubtitleTranslation alloc] initWithIndex:event.index.integerValue
                                                                    origin:newOrigin
                                                               translation:nil];
    }
    
    // 更新列表，保持最新N条（subtitleLimit）
    NSMutableArray *newTranslations = [NSMutableArray array];
    for (PLVLiveSubtitleTranslation *translation in self.translations) {
        if (translation.index != event.index.integerValue) {
            [newTranslations addObject:translation];
        }
    }
    [newTranslations addObject:newTranslation];
    
    // 按索引排序，取最后N条
    [newTranslations sortUsingComparator:^NSComparisonResult(PLVLiveSubtitleTranslation *obj1, PLVLiveSubtitleTranslation *obj2) {
        if (obj1.index < obj2.index) {
            return NSOrderedAscending;
        } else if (obj1.index > obj2.index) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    
    if (newTranslations.count > self.subtitleLimit) {
        NSInteger removeCount = newTranslations.count - self.subtitleLimit;
        [newTranslations removeObjectsInRange:NSMakeRange(0, removeCount)];
    }
    
    self.translations = newTranslations;
    
    // 通知代理
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(subtitleHandler:didUpdateRealTimeSubtitle:)]) {
            [self.delegate subtitleHandler:self didUpdateRealTimeSubtitle:self.realTimeSubtitle];
        }
        if ([self.delegate respondsToSelector:@selector(subtitleHandler:didUpdateAllSubtitles:)]) {
            [self.delegate subtitleHandler:self didUpdateAllSubtitles:[self.translations copy]];
        }
    });
}

/// 处理 TRANSLATE 事件
- (void)handleSubtitleSocketMessageTranslate:(NSDictionary *)dict {
    PLVLiveSubtitleSocketEventTranslate *event = [PLVLiveSubtitleSocketEventTranslate modelWithDictionary:dict];
    if (!event || !event.index) {
        return;
    }
    
    // 找到对应的字幕项
    PLVLiveSubtitleTranslation *translation = nil;
    for (PLVLiveSubtitleTranslation *t in self.translations) {
        if (t.index == event.index.integerValue) {
            translation = t;
            break;
        }
    }
    
    if (!translation) {
        return;
    }
    
    // 更新翻译内容
    PLVLiveSubtitleModel *newTranslation = [[PLVLiveSubtitleModel alloc] initWithIndex:event.index.integerValue
                                                                                 stable:YES
                                                                                   text:event.result ?: @""
                                                                         textStartIndex:0
                                                                               language:event.language ?: @""];
    
    PLVLiveSubtitleTranslation *newTranslationItem = [[PLVLiveSubtitleTranslation alloc] initWithIndex:translation.index
                                                                                                  origin:translation.origin
                                                                                             translation:newTranslation];
    
    // 更新列表
    NSMutableArray *newTranslations = [NSMutableArray array];
    for (PLVLiveSubtitleTranslation *t in self.translations) {
        if (t.index != event.index.integerValue) {
            [newTranslations addObject:t];
        }
    }
    [newTranslations addObject:newTranslationItem];
    
    // 按索引排序，取最后N条
    [newTranslations sortUsingComparator:^NSComparisonResult(PLVLiveSubtitleTranslation *obj1, PLVLiveSubtitleTranslation *obj2) {
        if (obj1.index < obj2.index) {
            return NSOrderedAscending;
        } else if (obj1.index > obj2.index) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    
    if (newTranslations.count > self.subtitleLimit) {
        NSInteger removeCount = newTranslations.count - self.subtitleLimit;
        [newTranslations removeObjectsInRange:NSMakeRange(0, removeCount)];
    }
    
    self.translations = newTranslations;
    
    // 通知代理
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(subtitleHandler:didUpdateAllSubtitles:)]) {
            [self.delegate subtitleHandler:self didUpdateAllSubtitles:[self.translations copy]];
        }
    });
}

/// 处理 ENABLE 事件
- (void)handleSubtitleSocketMessageEnable:(NSDictionary *)dict {
    PLVLiveSubtitleSocketEventEnable *event = [PLVLiveSubtitleSocketEventEnable modelWithDictionary:dict];
    if (!event) {
        return;
    }
    
    BOOL enable = event.enable ? event.enable.boolValue : NO;
    
    if (enable) {
        // 启用时重新加载字幕历史
        // [self loadCurrentSubtitleFromApi];
    }
    
    self.showSubtitle = enable;
}

/// 字幕追加逻辑
- (PLVLiveSubtitleModel *)handleSubtitleAppend:(nullable PLVLiveSubtitleModel *)src event:(PLVLiveSubtitleSocketEventAdd *)event {
    if (src && src.index == event.index.integerValue) {
        // 增量更新：计算需要保留的文本长度
        NSInteger replaceIndex = event.replaceIndex ? event.replaceIndex.integerValue : 0;
        NSInteger takeLength = MAX(0, replaceIndex - src.textStartIndex);
        
        NSString *keptText = @"";
        if (takeLength > 0 && takeLength <= src.text.length) {
            keptText = [src.text substringToIndex:takeLength];
        }
        
        // 拼接新内容
        NSString *newText = [keptText stringByAppendingString:event.text ?: @""];
        NSInteger newStartIndex = MIN(src.textStartIndex, replaceIndex);
        BOOL stable = (event.sliceType && event.sliceType.integerValue == 2);
        
        return [[PLVLiveSubtitleModel alloc] initWithIndex:event.index.integerValue
                                                    stable:stable
                                                      text:newText
                                            textStartIndex:newStartIndex
                                                  language:event.language ?: @""];
    } else {
        // 新建字幕项
        NSInteger replaceIndex = event.replaceIndex ? event.replaceIndex.integerValue : 0;
        BOOL stable = (event.sliceType && event.sliceType.integerValue == 2);
        return [[PLVLiveSubtitleModel alloc] initWithIndex:event.index.integerValue
                                                    stable:stable
                                                      text:event.text ?: @""
                                            textStartIndex:replaceIndex
                                                  language:event.language ?: @""];
    }
}

/// 从API加载字幕历史（重载方法）
- (void)loadCurrentSubtitleFromApi {
    [self loadCurrentSubtitleFromApi:YES loadTranslation:YES];
}

/// 从API加载字幕历史
- (void)loadCurrentSubtitleFromApi:(BOOL)loadRealTime loadTranslation:(BOOL)loadTranslation {
    if (!self.channelId || !self.viewerId) {
        NSLog(@"PLVLiveRealTimeSubtitleHandler - loadCurrentSubtitleFromApi: channelId或viewerId为空");
        return;
    }
    
    // 获取字幕配置
    PLVRoomData *roomData = [PLVRoomDataManager sharedManager].roomData;
    PLVLiveRealTimeSubtitleConfig *subtitleConfig = roomData.menuInfo.realTimeSubtitleConfig;
    
    if (!subtitleConfig || !subtitleConfig.realTimeSubtitleEnabled) {
        NSLog(@"PLVLiveRealTimeSubtitleHandler - loadCurrentSubtitleFromApi: 字幕功能未启用");
        return;
    }
    
    NSLog(@"PLVLiveRealTimeSubtitleHandler - 开始从API加载字幕历史, loadRealTime:%d, loadTranslation:%d", loadRealTime, loadTranslation);
    
    // 获取chatToken（异步）
    __weak typeof(self) weakSelf = self;
    [PLVLiveVideoAPI getChatTokenWithChannelId:self.channelId
                                        userId:self.viewerId
                                    completion:^(NSDictionary *data) {
        if (!data || !data[@"token"]) {
            NSLog(@"PLVLiveRealTimeSubtitleHandler - 获取chatToken失败: 返回数据为空");
            return;
        }
        
        NSString *token = data[@"token"];
        NSLog(@"PLVLiveRealTimeSubtitleHandler - 获取chatToken成功");
        
        // 调用API获取字幕列表
        [weakSelf requestSubtitlesListWithToken:token loadRealTime:loadRealTime loadTranslation:loadTranslation];
        
    } failure:^(NSError *error) {
        NSLog(@"PLVLiveRealTimeSubtitleHandler - 获取chatToken失败: %@", error.localizedDescription);
    }];
}

/// 请求字幕列表（内部方法）
- (void)requestSubtitlesListWithToken:(NSString *)token loadRealTime:(BOOL)loadRealTime loadTranslation:(BOOL)loadTranslation {
    // 这里需要调用实际的字幕列表API
    // 由于SDK中可能没有暴露这个API，我们需要使用PLVLiveVideoAPI来实现
    // 参考Android的实现：PLVApiManager.getPlvApichatApiKt().getSubtitlesList(...)
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.polyv.net/live/v3/channel/chat/get-subtitles-list?channelId=%@&token=%@", 
                          self.channelId, token];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    
    NSLog(@"PLVLiveRealTimeSubtitleHandler - 请求字幕列表: %@", urlString);
    
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"PLVLiveRealTimeSubtitleHandler - 请求字幕列表失败: %@", error);
            return;
        }
        
        if (!data) {
            NSLog(@"PLVLiveRealTimeSubtitleHandler - 请求字幕列表返回空数据");
            return;
        }
        
        NSError *jsonError = nil;
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if (jsonError || !responseDict) {
            NSLog(@"PLVLiveRealTimeSubtitleHandler - 解析字幕列表JSON失败: %@", jsonError);
            return;
        }
        
        NSLog(@"PLVLiveRealTimeSubtitleHandler - 字幕列表API响应: %@", responseDict);
        
        // 解析返回数据
        NSDictionary *dataDict = responseDict[@"data"];
        NSArray *subtitleList = dataDict[@"list"];
        
        if (![subtitleList isKindOfClass:[NSArray class]]) {
            NSLog(@"PLVLiveRealTimeSubtitleHandler - 字幕列表格式错误");
            return;
        }
        
        dispatch_async(weakSelf.subtitleProcessQueue, ^{
            [weakSelf parseSubtitleListResponse:subtitleList loadRealTime:loadRealTime loadTranslation:loadTranslation];
        });
    }];
    
    [task resume];
}

/// 解析字幕列表响应
- (void)parseSubtitleListResponse:(NSArray *)subtitleList loadRealTime:(BOOL)loadRealTime loadTranslation:(BOOL)loadTranslation {
    NSMutableArray *subtitleTranslations = [NSMutableArray array];
    
    for (NSDictionary *itemDict in subtitleList) {
        if (![itemDict isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        
        NSInteger index = [itemDict[@"index"] integerValue];
        NSInteger sliceType = [itemDict[@"sliceType"] integerValue];
        
        // 获取原文和翻译文本
        NSString *originText = itemDict[self.originLanguage];
        NSString *translateText = itemDict[self.translateLanguage];
        
        // 创建原文字幕对象
        PLVLiveSubtitleModel *origin = nil;
        if (originText && [originText isKindOfClass:[NSString class]] && originText.length > 0) {
            origin = [[PLVLiveSubtitleModel alloc] initWithIndex:index
                                                          stable:(sliceType == 2)
                                                            text:originText
                                                  textStartIndex:0
                                                        language:self.originLanguage ?: @""];
        }
        
        // 创建翻译字幕对象
        PLVLiveSubtitleModel *translation = nil;
        if (translateText && [translateText isKindOfClass:[NSString class]] && translateText.length > 0) {
            translation = [[PLVLiveSubtitleModel alloc] initWithIndex:index
                                                               stable:(sliceType == 2)
                                                                 text:translateText
                                                       textStartIndex:0
                                                             language:self.translateLanguage ?: @""];
        }
        
        // 如果有原文，则创建翻译对象
        if (origin) {
            PLVLiveSubtitleTranslation *translationItem = [[PLVLiveSubtitleTranslation alloc] initWithIndex:index
                                                                                                      origin:origin
                                                                                                 translation:translation];
            [subtitleTranslations addObject:translationItem];
        }
    }
    
    // 按索引排序
    [subtitleTranslations sortUsingComparator:^NSComparisonResult(PLVLiveSubtitleTranslation *obj1, PLVLiveSubtitleTranslation *obj2) {
        if (obj1.index < obj2.index) {
            return NSOrderedAscending;
        } else if (obj1.index > obj2.index) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    
    // 取最后N条
    if (subtitleTranslations.count > self.subtitleLimit) {
        NSInteger removeCount = subtitleTranslations.count - self.subtitleLimit;
        [subtitleTranslations removeObjectsInRange:NSMakeRange(0, removeCount)];
    }
    
    NSLog(@"PLVLiveRealTimeSubtitleHandler - 解析得到 %lu 条字幕", (unsigned long)subtitleTranslations.count);
    
    // 更新状态
    if (loadRealTime) {
        PLVLiveSubtitleTranslation *latest = subtitleTranslations.lastObject;
        if (latest) {
            self.realTimeSubtitle = latest.origin;
        }
    }
    
    if (loadTranslation) {
        self.translations = subtitleTranslations;
    }
    
    // 通知代理
    dispatch_async(dispatch_get_main_queue(), ^{
        if (loadRealTime && [self.delegate respondsToSelector:@selector(subtitleHandler:didUpdateRealTimeSubtitle:)]) {
            [self.delegate subtitleHandler:self didUpdateRealTimeSubtitle:self.realTimeSubtitle];
        }
        if (loadTranslation && [self.delegate respondsToSelector:@selector(subtitleHandler:didUpdateAllSubtitles:)]) {
            [self.delegate subtitleHandler:self didUpdateAllSubtitles:[self.translations copy]];
        }
    });
}

#pragma mark - Public Static Methods

/// 根据语言编码获取语言显示名称
+ (NSString *)languageNameForCode:(NSString *)languageCode {
    if (!languageCode || languageCode.length == 0) {
        return @"";
    }
    
    // 统一的语言代码映射表（与Android保持一致，支持22种语言）
    static NSDictionary<NSString *, NSString *> *languageMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        languageMap = @{
            @"origin": @"原文(不翻译)",
            @"Chinese": @"中文",
            @"zh-CN": @"中文",
            @"English": @"英语",
            @"en-US": @"英语",
            @"Cantonese": @"粤语",
            @"yue": @"粤语",
            @"Uyghur": @"维吾尔语",
            @"ug": @"维吾尔语",
            @"Tagalog": @"菲律宾语",
            @"tl": @"菲律宾语",
            @"Thai": @"泰语",
            @"th": @"泰语",
            @"th-TH": @"泰语",
            @"Malay": @"马来语",
            @"ms": @"马来语",
            @"Indonesian": @"印尼语",
            @"id": @"印尼语",
            @"id-ID": @"印尼语",
            @"Lao": @"老挝语",
            @"lo": @"老挝语",
            @"Burmese": @"缅甸语",
            @"my": @"缅甸语",
            @"Vietnamese": @"越南语",
            @"vi": @"越南语",
            @"vi-VN": @"越南语",
            @"French": @"法语",
            @"fr": @"法语",
            @"fr-FR": @"法语",
            @"Japanese": @"日本语",
            @"ja": @"日本语",
            @"ja-JP": @"日本语",
            @"German": @"德语",
            @"de": @"德语",
            @"de-DE": @"德语",
            @"Korean": @"韩语",
            @"ko": @"韩语",
            @"ko-KR": @"韩语",
            @"Russian": @"俄语",
            @"ru": @"俄语",
            @"ru-RU": @"俄语",
            @"Portuguese": @"葡萄牙语",
            @"pt": @"葡萄牙语",
            @"pt-PT": @"葡萄牙语",
            @"Turkish": @"土耳其语",
            @"tr": @"土耳其语",
            @"tr-TR": @"土耳其语",
            @"Arabic": @"阿拉伯语",
            @"ar": @"阿拉伯语",
            @"ar-SA": @"阿拉伯语",
            @"Spanish": @"西班牙语",
            @"es": @"西班牙语",
            @"es-ES": @"西班牙语",
            @"Khmer": @"高棉语",
            @"km": @"高棉语",
            @"km-KH": @"高棉语",
            @"Tamil": @"泰米尔语",
            @"ta": @"泰米尔语",
            @"ta-SG": @"泰米尔语",
            @"zh-HK": @"中文(繁体)"
        };
    });
    
    return languageMap[languageCode] ?: languageCode;
}

@end
