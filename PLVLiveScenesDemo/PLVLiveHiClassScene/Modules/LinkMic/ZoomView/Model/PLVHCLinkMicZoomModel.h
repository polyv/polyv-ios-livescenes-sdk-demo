//
//  PLVHCLinkMicZoomModel.h
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2021/11/17.
//  Copyright © 2021 PLV. All rights reserved.
// 摄像头/连麦视图 放大模型，用于存放Socket发送、接收 摄像头/连麦视图 放大数据

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

///
@interface PLVHCLinkMicZoomModel : NSObject

#pragma mark Socket回调字段
/// 实际字段为'id' 窗口id，适配前端格式：plv-${userId}-drag，其中userId为聊天室的用户userId
@property (nonatomic, copy) NSString *windowId;
/// 窗口距离左边的距离，即摄像头画面左边缘距离白板布局左侧边的长度
@property (nonatomic, assign) CGFloat left;
/// 窗口距离顶部的距离，摄像头画面顶部边缘距离白板布局顶边的长度
@property (nonatomic, assign) CGFloat top;
/// 窗口宽度，即当前摄像头画面的宽度
@property (nonatomic, assign) CGFloat width;
/// 窗口高度，即当前摄像头画面的高度
@property (nonatomic, assign) CGFloat height;
/// 窗口父元素宽度，即白板宽度
@property (nonatomic, assign) CGFloat parentWidth;
/// 窗口父元素高度，即白板高度
@property (nonatomic, assign) CGFloat parentHeight;
/// 窗口层级，决定重叠时的显示层级，前端是初始为1000，每一次触发更新，全局计数+1
@property (nonatomic, assign) NSInteger index;

#pragma mark 自用字段

/// 聊天室的用户userId
@property (nonatomic, copy) NSString *userId;

/// 模型转字典
- (NSMutableDictionary *)modelToDictionary;

/// 模型转字典，用于更新窗口
- (NSMutableDictionary *)modelToDictionaryByUpdate;

/// 模型转字典，用于移除窗口
- (NSMutableDictionary *)modelToDictionaryByRemove;

/// 从窗口Id 解出userId
/// @param windowId 窗口Id
- (NSString *)userIdWithWindowId:(NSString *)windowId;

/// 从用户Id 生成windowId
/// @param userId 用户Id
- (NSString *)windowIdWithUserId:(NSString *) userId;

/// 更新模型数据，可用于更新已在放大区域的用户数据
- (void)updateWithModel:(PLVHCLinkMicZoomModel *)model;

/// 字典转模型
/// @param jsonDic 字典数据
+ (PLVHCLinkMicZoomModel *)modelWithJsonDic:(NSDictionary *)jsonDic;

/// 创建用于移除窗口模型
+ (PLVHCLinkMicZoomModel *)createOutZoomModelWithUserId:(NSString *)userId;

/// 创建放大窗口模型，内部会根据当前已显示几个窗口来初始化数据
+ (PLVHCLinkMicZoomModel *)createZoomModelWithUserId:(NSString *)userId parentSize:(CGSize)parentSize;

@end

NS_ASSUME_NONNULL_END
