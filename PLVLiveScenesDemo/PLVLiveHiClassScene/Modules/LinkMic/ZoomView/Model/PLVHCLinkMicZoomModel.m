//
//  PLVHCLinkMicZoomModel.m
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/11/17.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCLinkMicZoomModel.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVHCLinkMicZoomManager.h"

@implementation PLVHCLinkMicZoomModel

- (NSString *)userId {
    return [self userIdWithWindowId:self.windowId];
}

- (NSMutableDictionary *)modelToDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    plv_dict_set(dict, @"id", self.windowId);
    plv_dict_set(dict, @"left", @(self.left));
    plv_dict_set(dict, @"top", @(self.top));
    plv_dict_set(dict, @"width", @(self.width));
    plv_dict_set(dict, @"height", @(self.height));
    plv_dict_set(dict, @"parentWidth", @(self.parentWidth));
    plv_dict_set(dict, @"parentHeight", @(self.parentHeight));
    plv_dict_set(dict, @"index", @(self.index));
    
    return dict;
}

- (NSMutableDictionary *)modelToDictionaryByUpdate {
    NSMutableDictionary *dict = [self modelToDictionary];
    plv_dict_set(dict, @"EVENT", @"update");
    return dict;
}

- (NSMutableDictionary *)modelToDictionaryByRemove {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    plv_dict_set(dict, @"id", self.windowId);
    plv_dict_set(dict, @"EVENT", @"remove");
    return dict;
}

// 从窗口Id 解出userId
- (NSString *)userIdWithWindowId:(NSString *)windowId {
    if (![PLVFdUtil checkStringUseable:windowId]) {
        return nil;
    }
    
    NSString *userId = nil;
    NSArray *array = [windowId componentsSeparatedByString:@"-"];
    if ([PLVFdUtil checkArrayUseable:array] &&
        array.count == 3) {
        userId = array[1];
    }
    return userId;
}

// 从userId 生成窗口Id，plv-${userId}-drag
- (NSString *)windowIdWithUserId:(NSString *) userId {
    if (![PLVFdUtil checkStringUseable:userId]) {
        return nil;
    }
    return [NSString stringWithFormat:@"plv-%@-drag", userId];
}


- (void)updateWithModel:(PLVHCLinkMicZoomModel *)model {
    self.windowId = model.windowId;
    self.left = model.left;
    self.top = model.top;
    self.width = model.width;
    self.height = model.height;
    self.parentWidth = model.parentWidth;
    self.parentHeight = model.parentHeight;
    self.index = model.index;
}

+ (PLVHCLinkMicZoomModel *)createZoomModelWithUserId:(NSString *)userId parentSize:(CGSize)parentSize {
    if ([PLVHCLinkMicZoomManager sharedInstance].isMaxZoomNum) {
        NSLog(@"最多支持放大%d个摄像头",kPLVHCLinkMicZoomMAXNum);
        return nil;
    }
    
    PLVHCLinkMicZoomModel *model = [[PLVHCLinkMicZoomModel alloc] init];
    CGFloat height = parentSize.height / 2;
    CGFloat width = 16 * height / 9;
    width = MIN(parentSize.width / 2, width); // 保证两个视图时不超出父类宽度
    height = width * 9 / 16; // 保证宽高为16:9
    CGFloat left;
    CGFloat top;
    CGFloat firstLeft = (parentSize.width - width * 2) / 2;
    CGFloat firstTop = (parentSize.height - height * 2) / 2;
    NSUInteger num = [PLVHCLinkMicZoomManager sharedInstance].zoomModelArrayM.count;
    
    switch (num) {
        case 0:
            left = firstLeft;
            top = firstTop;
            break;
        case 1:
            left = parentSize.width - firstLeft - width;
            top = firstTop;
            break;
        case 2:
            left = firstLeft;
            top = parentSize.height - firstTop - height;
            break;
        case 3:
            left = parentSize.width - firstLeft - width;
            top = parentSize.height - firstTop - height;
            break;
        default:
            return nil;
            break;
    }
    model.windowId = [model windowIdWithUserId:userId];
    model.left = left;
    model.top = top;
    model.width = width;
    model.height = height;
    model.parentWidth = parentSize.width;
    model.parentHeight = parentSize.height;
    model.index = [PLVHCLinkMicZoomManager sharedInstance].windowMaxIndex;
    return model;

}

+ (PLVHCLinkMicZoomModel *)modelWithJsonDic:(NSDictionary *)jsonDic {
    if (![PLVFdUtil checkDictionaryUseable:jsonDic]) {
        return nil;
    }
    
    PLVHCLinkMicZoomModel *model = [[PLVHCLinkMicZoomModel alloc] init];
    model.windowId = PLV_SafeStringForDictKey(jsonDic, @"id");
    model.left = PLV_SafeFloatForDictKey(jsonDic, @"left");
    model.top = PLV_SafeFloatForDictKey(jsonDic, @"top");
    model.width = PLV_SafeFloatForDictKey(jsonDic, @"width");
    model.height = PLV_SafeFloatForDictKey(jsonDic, @"height");
    model.parentWidth = PLV_SafeFloatForDictKey(jsonDic, @"parentWidth");
    model.parentHeight = PLV_SafeFloatForDictKey(jsonDic, @"parentHeight");
    model.index = PLV_SafeIntegerForDictKey(jsonDic, @"index");
    
    return model;
}

+ (PLVHCLinkMicZoomModel *)createOutZoomModelWithUserId:(NSString *)userId {
    if (![PLVFdUtil checkStringUseable:userId]) {
        return nil;
    }
    PLVHCLinkMicZoomModel *model = [[PLVHCLinkMicZoomModel alloc] init];
    model.windowId = [model windowIdWithUserId:userId];
    return model;
}

@end
