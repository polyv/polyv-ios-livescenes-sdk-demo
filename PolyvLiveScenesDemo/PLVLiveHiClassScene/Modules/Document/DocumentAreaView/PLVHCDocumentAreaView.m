//
//  PLVHCDocumentAreaView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCDocumentAreaView.h"

/// 工具类
#import "PLVHCUtils.h"

/// UI
#import "PLVDocumentContainerView.h"
#import "PLVHCDocumentInputView.h"

/// 模块
#import "PLVRoomDataManager.h"
#import "PLVDocumentModel.h"
#import "PLVHCDocumentMinimumModel.h"

/// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>
@interface PLVHCDocumentAreaView ()<
PLVDocumentContainerViewDelegate
>

#pragma mark UI
/// view hierarchy
///
/// (PLVHCDocumentAreaView) self
///    ├─ (PLVDocumentContainerView) containerView
///    └─ (PLVHCDocumentInputView) inputView(动态显示)
///

@property (nonatomic, strong) PLVDocumentContainerView *containerView; // PPT、白板功能模块视图
@property (nonatomic, strong) PLVHCDocumentInputView *inputView; // 文字输入视图

#pragma mark 数据

@property (nonatomic, assign) PLVRoomUserType userType;

@end

@implementation PLVHCDocumentAreaView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.userType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
        
        self.backgroundColor = PLV_UIColorFromRGB(@"#313540");
        self.layer.cornerRadius = 8;
        self.clipsToBounds = YES;
        
        [self addSubview:self.containerView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.containerView.frame = self.bounds;
}

#pragma mark - [ Public Method ]

- (void)updateBrushToolStatusWithDict:(NSDictionary *)dict {
    if (!dict ||
        ![dict isKindOfClass:[NSDictionary class]]) {
        return;
    }
}

#pragma mark native -> js

- (void)openPptWithAutoId:(NSUInteger)autoId {
    if (self.userType != PLVRoomUserTypeTeacher) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypePPT, @"%s 权限不足【userType:%zd】", __FUNCTION__ , self.userType);
        [PLVHCUtils showToastInWindowWithMessage:@"用户权限不足"];
        return;
    }
    [self.containerView openPptWithAutoId:autoId];
}

- (void)operateContainerWithContainerId:(NSString *)containerId close:(BOOL)close {
    if (self.userType != PLVRoomUserTypeTeacher) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypePPT, @"%s 权限不足【userType:%zd】", __FUNCTION__ , self.userType);
        [PLVHCUtils showToastInWindowWithMessage:@"用户权限不足"];
        return;
    }
    [self.containerView operateContainerWithContainerId:containerId close:close];
}

- (void)setPaintBrushAuthWithUserId:(NSString *)userId {
    if (self.userType != PLVRoomUserTypeTeacher) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypePPT, @"%s 权限不足【userType:%zd】", __FUNCTION__ , self.userType);
        [PLVHCUtils showToastInWindowWithMessage:@"用户权限不足"];
        return;
    }
    [self.containerView setPaintBrushAuthWithUserId:userId];
    [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_AuthBrush message:@"已授权该学生画笔"];
}

- (void)removePaintBrushAuthWithUserId:(NSString *)userId {
    if (self.userType != PLVRoomUserTypeTeacher) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypePPT, @"%s 权限不足【userType:%zd】", __FUNCTION__ , self.userType);
        [PLVHCUtils showToastInWindowWithMessage:@"用户权限不足"];
        return;
    }
    [self.containerView removePaintBrushAuthWithUserId:userId];
    [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_AuthBrush message:@"已收回该学生画笔"];
}

- (void)removeSelfPaintBrushAuth {
    [self.containerView removePaintBrushAuth];
}

- (void)resetZoom {
    if (self.userType != PLVRoomUserTypeTeacher) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypePPT, @"%s 权限不足【userType:%zd】", __FUNCTION__ , self.userType);
        [PLVHCUtils showToastInWindowWithMessage:@"用户权限不足"];
        return;
    }
    [self.containerView resetZoom];
}

- (void)updateSelectToolType:(PLVHCBrushToolType)toolType {
    switch (toolType) {
        case PLVHCBrushToolTypeChoice:
            [self.containerView changeApplianceType:PLVContainerApplianceTypeChoice];
            break;
        case PLVHCBrushToolTypeFreeLine:
            [self.containerView changeApplianceType:PLVContainerApplianceTypeFreeLine];
            break;
        case PLVHCBrushToolTypeArrow:
            [self.containerView changeApplianceType:PLVContainerApplianceTypeArrow];
            break;
        case PLVHCBrushToolTypeText:
            [self.containerView changeApplianceType:PLVContainerApplianceTypeText];
            break;
        case PLVHCBrushToolTypeEraser:
            [self.containerView changeApplianceType:PLVContainerApplianceTypeEraser];
            break;
        case PLVHCBrushToolTypeMove:
            [self.containerView changeApplianceType:PLVContainerApplianceTypeMove];
            break;
        case PLVHCBrushToolTypeClear:
            [self dealClearEvent];
            break;
        case PLVHCBrushToolTypeRevoke:
            [self.containerView doUndo];
            break;
        default:
            PLV_LOG_ERROR(PLVConsoleLogModuleTypePPT, @"%s 使用未定义画笔类型【toolType:%zd】", __FUNCTION__ , toolType);
            break;
    }
}

- (void)updateSelectColor:(NSString *)color {
    if ([PLVFdUtil checkStringUseable:color]) {
        [self.containerView changeStrokeWithHexColor:color];
    }
}

- (void)doDelete {
    [self.containerView doDelete];
}

- (void)doUndo {
    [self.containerView doUndo];
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (PLVDocumentContainerView *)containerView {
    if (!_containerView) {
        _containerView = [[PLVDocumentContainerView alloc] init];
        _containerView.delegate = self;
        PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
        NSString *userType = [PLVRoomUser userTypeStringWithUserType:self.userType];
        [_containerView loadRequestWitParamString:[NSString stringWithFormat:@"userId=%@&userName=%@&userType=%@",
                                                   roomUser.viewerId,
                                                   roomUser.viewerName,
                                                   userType]];
    }
    return _containerView;
}

- (PLVHCDocumentInputView *)inputView {
    if (_inputView == nil) {
        _inputView = [[PLVHCDocumentInputView alloc] init];
        __weak typeof(self) weakSelf = self;
        _inputView.documentInputCompleteHandler = ^(NSString * _Nullable inputText) {
            if ([PLVFdUtil checkStringUseable:inputText]) {
                [weakSelf.containerView finishEditText:inputText];
            } else {
                [weakSelf.containerView cancelEditText];
            }
            
        };
    }
    return _inputView;
}

#pragma mark 发送js事件

- (void)dealClearEvent {
    __weak typeof(self) weaskSelf = self;
    [PLVHCUtils showAlertWithMessage:@"清屏后画笔痕迹将无法恢复，确认清屏吗？" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"清屏" confirmActionBlock:^{
        [weaskSelf.containerView doClear];
    }];
}

- (void)changeApplianceType:(PLVContainerApplianceType)type {
    [self.containerView changeApplianceType:type];
}

#pragma mark 数据处理

/// 获取当前最小化数量
/// @param jsonObject js发回native的数据
- (NSInteger)pptTotalWithJsonObject:(id)jsonObject {
    NSInteger total = -1;
    NSDictionary *totalDic = nil;
    
    if (!jsonObject) {
        return total;
    }
    
    if ([jsonObject isKindOfClass:[NSString class]]) {
        NSData *data = [jsonObject dataUsingEncoding:NSUTF8StringEncoding];
        totalDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    } else if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        totalDic = (NSDictionary *)jsonObject;
    }
    if (totalDic) {
        total = PLV_SafeIntegerForDictKey(totalDic, @"total");
    }
    
    return total;
}

- (NSArray <PLVHCDocumentMinimumModel *>*)minimunDataArrayWithJsonObject:(id)jsonObject {
    NSArray *listArray = nil;
    NSMutableArray *minimunDataArray = nil;
    
    if (jsonObject) {
        NSDictionary *dataDic = [self jsonDictWithJsonObject:jsonObject];
        if (dataDic) {
            listArray = PLV_SafeArraryForDictKey(dataDic, @"list");
        }
        
        if (listArray) {
            minimunDataArray = [NSMutableArray array];
            for (NSDictionary *dic in listArray) {
                if (dic &&
                    [dic isKindOfClass:[NSDictionary class]]) {
                    PLVHCDocumentMinimumModel *model = [PLVHCDocumentMinimumModel modelWithDictionary:dic];
                    if (model) {
                        [minimunDataArray addObject:model];
                    }
                }
            }
        }
    }
    
    return minimunDataArray;
}

- (NSDictionary *)jsonDictWithJsonObject:(id)jsonObject {
    NSDictionary *jsonDict = nil;
    if (jsonObject) {
        if ([jsonObject isKindOfClass:[NSString class]]) {
            NSData *data = [jsonObject dataUsingEncoding:NSUTF8StringEncoding];
            jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        } else if ([jsonObject isKindOfClass:[NSDictionary class]]) {
            jsonDict = (NSDictionary *)jsonObject;
        }
    }
    return jsonDict;
}


#pragma mark - [ Delegate ]
#pragma mark PLVDocumentContainerViewDelegate

- (void)documentContainerViewDidFinishLoading:(PLVDocumentContainerView *)documentContainerView {
    self.containerView.backgroundColor = [UIColor clearColor];
    // 讲师登录设置默认工具为移动工具
    if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher) {
        [self.containerView changeApplianceType:PLVContainerApplianceTypeMove];
    }

    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentAreaViewDidFinishLoading:)]) {
        [self.delegate documentAreaViewDidFinishLoading:self];
    }
}

- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didLoadFailWithError:(nonnull NSError *)error {
    [PLVHCUtils showToastInWindowWithMessage:@"PPT 加载失败"];
}

- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didRefreshPptContainerTotalWithJsonObject:(id)jsonObject {
    NSInteger total = [self pptTotalWithJsonObject:jsonObject];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentAreaView:didRefreshPptContainerTotal:)]) {
        [self.delegate documentAreaView:self didRefreshPptContainerTotal:total];
    }
}

- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didRefreshMinimizeContainerDataWithJsonObject:(id)jsonObject {
    NSArray *dataArray = [self minimunDataArrayWithJsonObject:jsonObject];
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentAreaView:didRefreshMinimizeContainerDataArray:)]) {
        [self.delegate documentAreaView:self didRefreshMinimizeContainerDataArray:dataArray];
    }
}

- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView willStartEditTextWithJsonObject:(id)jsonObject {
    NSDictionary *dataDic = [self jsonDictWithJsonObject:jsonObject];
    if (dataDic) {
        NSString *content = PLV_SafeStringForDictKey(dataDic, @"content");
        NSString *strokeStyle = PLV_SafeStringForDictKey(dataDic, @"strokeStyle");
        [self.inputView presentWithText:content textColor:strokeStyle inViewController:[PLVHCUtils sharedUtils].homeVC];
    }
}

- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didRefreshBrushToolStatusWithJsonObject:(id)jsonObject {
    NSDictionary *dataDic = [self jsonDictWithJsonObject:jsonObject];
    if (dataDic) {
        if (dataDic &&
            self.delegate &&
            [self.delegate respondsToSelector:@selector(documentAreaView:didRefreshBrushToolStatusWithJsonDict:)]) {
            [self.delegate documentAreaView:self didRefreshBrushToolStatusWithJsonDict:dataDic];
        }
    }
}

- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didRefreshBrushPermission:(BOOL)permission userId:(nonnull NSString *)userId {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentAreaView:didRefreshBrushPermission:userId:)]) {
        [self.delegate documentAreaView:self didRefreshBrushPermission:permission userId:userId];
    }
}

- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didChangeApplianceType:(PLVContainerApplianceType)applianceType {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentAreaView:didChangeApplianceType:)]) {
        [self.delegate documentAreaView:self didChangeApplianceType:applianceType];
    }
}

- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didChangeStrokeHexColor:(NSString *)strokeHexColor {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentAreaView:didChangeStrokeHexColor:)]) {
        [self.delegate documentAreaView:self didChangeStrokeHexColor:strokeHexColor];
    }
}

- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didChangeZoomPercent:(CGFloat)percent {
    percent = roundf(percent * 100);
    BOOL show = percent != 100; // 当百分比不等于'100'(即1倍)时显示重置画板缩放按钮
    NSString *message = [NSString stringWithFormat:@"%.f%%", percent];
    
    [PLVHCUtils showToastWithType:PLVHCToastTypeText message:message];
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentAreaView:didChangeResetZoomButtonShow:)]) {
        [self.delegate documentAreaView:self didChangeResetZoomButtonShow:show];
    }
}
@end
