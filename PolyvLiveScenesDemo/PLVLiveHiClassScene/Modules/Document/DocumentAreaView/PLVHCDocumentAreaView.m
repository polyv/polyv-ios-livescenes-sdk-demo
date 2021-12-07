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
#import "PLVHCDocumentMinimumSheet.h"
#import "PLVHCBrushToolBarView.h"
#import "PLVHCBrushToolSelectSheet.h"
#import "PLVHCBrushColorSelectSheet.h"

/// 模块
#import "PLVRoomDataManager.h"
#import "PLVHCDocumentMinimumModel.h"

/// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>
@interface PLVHCDocumentAreaView ()<
PLVDocumentContainerViewDelegate, // ppt、白板容器视图回调
PLVHCDocumentMinimumSheetDelegate, // 文档最小化弹层视图回调
PLVHCBrushToolbarViewDelegate, // 画笔工具视图回调
PLVHCBrushToolSelectSheetDelegate, // 工具选择器视图回调
PLVHCBrushColorSelectSheetDelegate // 颜色选择器视图回调
>

#pragma mark UI
/// view hierarchy
///
/// (PLVHCDocumentAreaView) self
///    ├─ (PLVDocumentContainerView) containerView
///    ├─ (PLVHCDocumentInputView) inputView(动态显示)
///    ├─ (PLVHCDocumentMinimumSheet) documentMinimumSheet(动态显示)
///    ├─ (PLVHCBrushToolBarView) brushToolBarView(动态显示)
///    ├─ (PLVHCBrushToolSelectSheet) brushToolSelectSheet(动态显示)
///    ├─ (PLVHCBrushColorSelectSheet) brushColorSelectSheet(动态显示)
///    ├─ (UIButton) resetZoomButton(动态显示)
///
@property (nonatomic, strong) PLVDocumentContainerView *containerView; // PPT、白板功能模块视图
@property (nonatomic, strong) PLVHCDocumentInputView *inputView; // 文字输入视图
@property (nonatomic, strong) PLVHCDocumentMinimumSheet *documentMinimumSheet; // 文档最小化弹层
@property (nonatomic, strong) PLVHCBrushToolBarView *brushToolBarView; // 画笔工具视图
@property (nonatomic, strong) PLVHCBrushToolSelectSheet *brushToolSelectSheet; // 画笔工具选择弹层
@property (nonatomic, strong) PLVHCBrushColorSelectSheet *brushColorSelectSheet; // 画笔颜色选择弹层
@property (nonatomic, strong) UIButton *resetZoomButton; // 重置画板缩放比例

#pragma mark 数据

@property (nonatomic, assign) PLVRoomUserType userType;

@end

@implementation PLVHCDocumentAreaView

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.userType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
        [self addSubview:self.containerView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize selfSize = self.bounds.size; // self的frame已经考虑了安全距离，所以子类不需要理会安全距离问题
    CGFloat rightPadding = 36 + 14; // 右边间距（36是与工具栏右间距对齐，14是工具栏的centX）
    CGFloat sheetMaxWidth = selfSize.width - rightPadding; // 各个弹层最大宽度
    CGFloat bootomPadding = 8; // 底部间距
    
    // PPT/白板区域高度：父视图高度-8
    CGFloat documentViewHeight = selfSize.height - bootomPadding;
    // PPT/白板区域宽度：固定为高度的2.2倍，并且不超过最多可用宽度:sheetMaxWidth-8-rightPadding
    CGFloat documentAreaViewWidth = MIN(documentViewHeight * 2.2, selfSize.width - bootomPadding - rightPadding);
    self.containerView.frame = CGRectMake(selfSize.width - documentAreaViewWidth - rightPadding, 0, documentAreaViewWidth, documentViewHeight);

    // 画笔工具视图，内部自适应，(宽度：动态按钮宽度+ 右边间距，高度固定36)
    _brushToolBarView.screenSafeWidth = selfSize.width;
    
    // 画笔工具选择弹层，总共7(讲师、组长)、6(学生)种工具，每个工具固定大小为36*44,间距8*数量 + 左右间距4
    CGFloat brushToolCount = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher || [PLVHiClassManager sharedManager].currentUserIsGroupLeader ? 7 : 6;
    CGSize brushToolSelectViewSize = CGSizeMake( 4 * 2 + 36 * brushToolCount + 8 * (brushToolCount - 1), 44);
    CGFloat brushToolSelectViewX = sheetMaxWidth - brushToolSelectViewSize.width;
    CGFloat brushToolSelectViewY = CGRectGetMinY(_brushToolBarView.frame) - brushToolSelectViewSize.height - 14; // 与画笔工具视图间距14，显示在其上面
    _brushToolSelectSheet.frame = CGRectMake(brushToolSelectViewX, brushToolSelectViewY, brushToolSelectViewSize.width, brushToolSelectViewSize.height);
    
    // 画笔颜色选择弹层，总共6种颜色，左间距4 + 每个颜色固定大小为36*44 + 间距8*5 + 右间距4
    CGSize brushColorSelectViewSize = CGSizeMake(4 + 36 * 6 + 8 * 5 + 4, 44);
    CGFloat brushColorSelectViewX = sheetMaxWidth - brushColorSelectViewSize.width;
    CGFloat brushColorSelectViewY = CGRectGetMinY(_brushToolBarView.frame) - brushColorSelectViewSize.height - 14; // 与画笔工具视图间距14，显示在其上面
    _brushColorSelectSheet.frame = CGRectMake(brushColorSelectViewX, brushColorSelectViewY, brushColorSelectViewSize.width, brushColorSelectViewSize.height);
    
    // 重置画板缩放比例 固定宽高(116,36)
    _resetZoomButton.frame = CGRectMake(36, 12, 116, 36);
}

#pragma mark - [ Public Method ]

- (void)enterClassroom {
    [self showBrushToolbarView:YES];
}

#pragma mark native -> js（公开使用）

- (void)openPptWithAutoId:(NSUInteger)autoId {
    if (self.userType != PLVRoomUserTypeTeacher &&
        ![PLVHiClassManager sharedManager].currentUserIsGroupLeader) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypePPT, @"%s 权限不足【userType:%zd】", __FUNCTION__ , self.userType);
        [PLVHCUtils showToastInWindowWithMessage:@"用户权限不足"];
        return;
    }
    [self.containerView openPptWithAutoId:autoId];
}

- (void)setPaintBrushAuthWithUserId:(NSString *)userId {
    if (self.userType != PLVRoomUserTypeTeacher &&
        ![PLVHiClassManager sharedManager].currentUserIsGroupLeader) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypePPT, @"%s 权限不足【userType:%zd】", __FUNCTION__ , self.userType);
        [PLVHCUtils showToastInWindowWithMessage:@"用户权限不足"];
        return;
    }
    [self.containerView setPaintBrushAuthWithUserId:userId];
    [PLVHCUtils showToastWithType:PLVHCToastTypeIcon_AuthBrush message:@"已授权该学生画笔"];
}

- (void)removePaintBrushAuthWithUserId:(NSString *)userId {
    if (self.userType != PLVRoomUserTypeTeacher &&
        ![PLVHiClassManager sharedManager].currentUserIsGroupLeader) {
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

- (void)setOrRemoveGroupLeader:(BOOL)isLeader {
    [self.containerView setOrRemoveGroupLeader:isLeader];
    // 处理交互
    if (isLeader) {
        self.brushToolBarView.haveBrushPermission = YES;
        [self showBrushToolbarView:YES];
    } else {
        self.brushToolBarView.haveBrushPermission = NO;
        [self showBrushToolbarView:NO];
        
        [self showDocumentMinimumSheet:NO];
        [self showResetZoomButton:NO];
    }
    [self.brushToolSelectSheet updateLayout]; // 更新画笔工具layout
}

- (void)switchRoomWithAckData:(NSDictionary *)ackData datacallback:(PLVContainerResponseCallback)callback {
    [self.containerView switchRoomWithAckData:ackData datacallback:callback];
}

- (BOOL)isMaxMinimumNum {
    return self.documentMinimumSheet.isMaxMinimumNum;
}

#pragma mark - [ Private Method ]
#pragma mark Getter

- (PLVDocumentContainerView *)containerView {
    if (!_containerView) {
        _containerView = [[PLVDocumentContainerView alloc] init];
        _containerView.delegate = self;
        PLVRoomUser *roomUser = [PLVRoomDataManager sharedManager].roomData.roomUser;
        NSString *userType = [PLVRoomUser userTypeStringWithUserType:self.userType];
        NSString *sessionId = [PLVRoomDataManager sharedManager].roomData.sessionId;
        
        [_containerView loadRequestWitParamString:[NSString stringWithFormat:@"userId=%@&userName=%@&userType=%@&sessionId=%@",
                                                   roomUser.viewerId,
                                                   roomUser.viewerName,
                                                   userType,
                                                   sessionId]];
        
        _containerView.backgroundColor = PLV_UIColorFromRGB(@"#313540");
        _containerView.layer.cornerRadius = 8;
        _containerView.clipsToBounds = YES;
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

- (PLVHCBrushToolBarView *)brushToolBarView {
    if (!_brushToolBarView) {
        _brushToolBarView = [[PLVHCBrushToolBarView alloc] init];
        _brushToolBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _brushToolBarView.delegate = self;
        [self addSubview:_brushToolBarView];
    }
    return _brushToolBarView;
}

- (PLVHCBrushToolSelectSheet *)brushToolSelectSheet {
    if (!_brushToolSelectSheet) {
        _brushToolSelectSheet = [[PLVHCBrushToolSelectSheet alloc] init];
        _brushToolSelectSheet.delegate = self;
    }
    return _brushToolSelectSheet;
}

- (PLVHCBrushColorSelectSheet *)brushColorSelectSheet {
    if (!_brushColorSelectSheet) {
        _brushColorSelectSheet = [[PLVHCBrushColorSelectSheet alloc] init];
        _brushColorSelectSheet.delegate = self;
    }
    return _brushColorSelectSheet;
}

- (PLVHCDocumentMinimumSheet *)documentMinimumSheet {
    if (!_documentMinimumSheet) {
        _documentMinimumSheet = [[PLVHCDocumentMinimumSheet alloc] init];
        _documentMinimumSheet.delegate = self;
    }
    return _documentMinimumSheet;
}

- (UIButton *)resetZoomButton {
    if(!_resetZoomButton) {
        _resetZoomButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _resetZoomButton.hidden = YES;
        _resetZoomButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#242940" alpha:0.9];
        _resetZoomButton.layer.cornerRadius = 18;
        _resetZoomButton.layer.masksToBounds = YES;
        [_resetZoomButton setImage:[PLVHCUtils imageForDocumentResource:@"plvhc_doc_btn_resetzoom"] forState:UIControlStateNormal];
        [_resetZoomButton setTitle:@"默认尺寸" forState:UIControlStateNormal];
        [_resetZoomButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _resetZoomButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_resetZoomButton addTarget:self action:@selector(resetZoomButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_resetZoomButton];
    }
    return _resetZoomButton;
}

#pragma mark Show/Hide Subview

- (void)showBrushToolbarView:(BOOL)show {
    if (show &&
        self.brushToolBarView.haveBrushPermission) {
        [self.brushToolBarView showInView:self];
    } else {
        if (_brushToolBarView) {
            [self.brushToolBarView dismiss];
        }
        if (_brushToolSelectSheet) {
            [self.brushToolSelectSheet dismiss];
        }
        if (_brushColorSelectSheet) {
            [self.brushColorSelectSheet dismiss];
        }
    }
}

- (void)showDocumentMinimumSheet:(BOOL)show {
    if (show) {
        [self.documentMinimumSheet showInView:self];
    } else {
        if (_documentMinimumSheet) {
            [self.documentMinimumSheet dismiss];
        }
    }
}

- (void)showResetZoomButton:(BOOL)show {
    self.resetZoomButton.hidden = !show;
}

#pragma mark native -> js（内部使用）

- (void)dealClearEvent {
    __weak typeof(self) weaskSelf = self;
    [PLVHCUtils showAlertWithMessage:@"清屏后画笔痕迹将无法恢复，确认清屏吗？" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"清屏" confirmActionBlock:^{
        [weaskSelf.containerView doClear];
    }];
}

- (void)changeApplianceType:(PLVContainerApplianceType)type {
    [self.containerView changeApplianceType:type];
}

- (void)operateContainerWithContainerId:(NSString *)containerId close:(BOOL)close {
    if (self.userType != PLVRoomUserTypeTeacher &&
        ![PLVHiClassManager sharedManager].currentUserIsGroupLeader) {
        PLV_LOG_ERROR(PLVConsoleLogModuleTypePPT, @"%s 权限不足【userType:%zd】", __FUNCTION__ , self.userType);
        [PLVHCUtils showToastInWindowWithMessage:@"用户权限不足"];
        return;
    }
    [self.containerView operateContainerWithContainerId:containerId close:close];
}

- (void)resetZoom {
    if (self.userType != PLVRoomUserTypeTeacher &&
        ![PLVHiClassManager sharedManager].currentUserIsGroupLeader) {
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

#pragma mark 数据处理

/// 获取当前最小化数量
/// @param jsonObject js发给native的数据
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

/// 获取当前最小化文档数据
/// @param jsonObject js发给native的数据
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

#pragma mark 更新画笔数据

- (void)updateBrushToolStatusWithDict:(NSDictionary *)dict {
    if (!dict ||
        ![dict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    [self.brushToolBarView updateBrushToolStatusWithDict:dict];
}

- (void)updateBrushPermission:(BOOL)permission {
    if (self.brushToolBarView.haveBrushPermission == permission) { // 避免重复操作画笔权限(socket服务器在切换分组时，不管当前用户是否有画笔权限，都会发送一次取消画笔权限的通知)
        return;
    }
    
    self.brushToolBarView.haveBrushPermission = permission;
    [self showBrushToolbarView:permission];
    if ([PLVHiClassManager sharedManager].status == PLVHiClassStatusInClass) {
        NSString *message = permission ? @"老师已授予你画笔权限" : @"老师已回收你的画笔权限";
        PLVHCToastType type = permission ? PLVHCToastTypeIcon_AuthBrush : PLVHCToastTypeIcon_CancelAuthBrush;
        [PLVHCUtils showToastWithType:type message:message];
    }
}

#pragma mark 更新文档数据

- (void)refreshPptContainerTotal:(NSInteger)total {
    if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher ||
        [PLVHiClassManager sharedManager].currentUserIsGroupLeader) { // 讲师、组长才需要处理此数据
        [self.documentMinimumSheet refreshPptContainerTotal:total];
    }
}

- (void)refreshMinimizeContainerDataArray:(NSArray<PLVHCDocumentMinimumModel *> *)dataArray {
    if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher ||
        [PLVHiClassManager sharedManager].currentUserIsGroupLeader) { // 讲师、组长才需要处理此数据
        [self showDocumentMinimumSheet:dataArray.count > 0];
        [self.documentMinimumSheet refreshMinimizeContainerDataArray:dataArray];
    }
}


#pragma mark - [ Event ]
#pragma mark Action

- (void)resetZoomButtonAction {
    [self resetZoom];
}

#pragma mark - [ Delegate ]
#pragma mark PLVDocumentContainerViewDelegate

- (void)documentContainerViewDidFinishLoading:(PLVDocumentContainerView *)documentContainerView {
    self.containerView.backgroundColor = [UIColor clearColor];
    // 讲师登录设置默认工具为移动工具
    if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher) {
        [self.containerView changeApplianceType:PLVContainerApplianceTypeMove];
    }
}

- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didLoadFailWithError:(nonnull NSError *)error {
    [PLVHCUtils showToastInWindowWithMessage:@"PPT 加载失败"];
}

- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didRefreshPptContainerTotalWithJsonObject:(id)jsonObject {
    NSInteger total = [self pptTotalWithJsonObject:jsonObject];
    [self refreshPptContainerTotal:total];
}

- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didRefreshMinimizeContainerDataWithJsonObject:(id)jsonObject {
    NSArray *dataArray = [self minimunDataArrayWithJsonObject:jsonObject];
    [self refreshMinimizeContainerDataArray:dataArray];
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
    [self updateBrushToolStatusWithDict:dataDic];
}

- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didRefreshBrushPermission:(BOOL)permission userId:(nonnull NSString *)userId {
        if ([PLVFdUtil checkStringUseable:userId] &&
            [[PLVRoomDataManager sharedManager].roomData.roomUser.viewerId isEqualToString:userId]) { // 自己
            [self updateBrushPermission:permission];
        }
    
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(documentAreaView:didRefreshBrushPermission:userId:)]) {
        [self.delegate documentAreaView:self didRefreshBrushPermission:permission userId:userId];
    }
}

- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didChangeApplianceType:(PLVContainerApplianceType)applianceType {
    if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeSCStudent) { // 学生需要响应
        [self.brushToolSelectSheet updateBrushToolApplianceType:applianceType];
    }
}

- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didChangeStrokeHexColor:(NSString *)strokeHexColor {
    if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeSCStudent) { // 学生需要响应
        [self.brushToolBarView updateSelectColor:strokeHexColor];
        [self.brushColorSelectSheet updateSelectColor:strokeHexColor];
    }
}

- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didChangeZoomPercent:(CGFloat)percent {
    percent = roundf(percent * 100);
    BOOL show = percent != 100; // 当百分比不等于'100'(即1倍)时显示重置画板缩放按钮
    NSString *message = [NSString stringWithFormat:@"%.f%%", percent];
    [PLVHCUtils showToastWithType:PLVHCToastTypeText message:message];
    
    if ([PLVRoomDataManager sharedManager].roomData.roomUser.viewerType == PLVRoomUserTypeTeacher ||
        [PLVHiClassManager sharedManager].currentUserIsGroupLeader) {
        [self showResetZoomButton:show];
    } else if ([PLVHiClassManager sharedManager].groupState == PLVHiClassGroupStateJoiningGroup) { // 正在加入分组，需要等待3秒才能拿到正确的组长信息
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([PLVHiClassManager sharedManager].currentUserIsGroupLeader) {
                [weakSelf showResetZoomButton:show];
            }
        });
    }
}

- (void)documentContainerView:(PLVDocumentContainerView *)documentContainerView didRefreshGroupLeader:(BOOL)isLeader userId:(NSString *)userId {
    // 组长身份的切换回调
    // 更详细的组长切换信息可参考： -[PLVHCHiClassViewController liveroomViewModelDidGroupLeaderUpdate:groupName:groupLeaderId:groupLeaderName:]
}

#pragma mark PLVHCDocumentMinimumSheetDelegate

- (void)documentMinimumSheet:(PLVHCDocumentMinimumSheet *)documentMinimumSheet didCloseItemModel:(PLVHCDocumentMinimumModel *)model {
    [self operateContainerWithContainerId:model.containerId close:YES];
}

- (void)documentMinimumSheet:(PLVHCDocumentMinimumSheet *)documentMinimumSheet didSelectItemModel:(PLVHCDocumentMinimumModel *)model {
    [self operateContainerWithContainerId:model.containerId close:NO];
}

#pragma mark PLVHCBrushToolbarViewDelegate

- (void)brushToolBarViewDidTapDeleteButton:(PLVHCBrushToolBarView *)brushToolBarView {
    [self doDelete];
}

- (void)brushToolBarViewDidTapRevokeButton:(PLVHCBrushToolBarView *)brushToolBarView {
    [self doUndo];
}

- (void)brushToolBarViewDidTapColorButton:(PLVHCBrushToolBarView *)brushToolBarView {
    if (self.brushColorSelectSheet.superview) {
        [self.brushColorSelectSheet dismiss];
    } else {
        [self.brushToolSelectSheet dismiss];
        [self.brushColorSelectSheet showInView:self];
    }
}

- (void)brushToolBarViewDidTapToolButton:(PLVHCBrushToolBarView *)brushToolBarView {
    if (self.brushToolSelectSheet.superview) {
        [self.brushToolSelectSheet dismiss];
    } else {
        [self.brushColorSelectSheet dismiss];
        [self.brushToolSelectSheet showInView:self];
    }
}

#pragma mark  PLVHCBrushToolSelectSheetDelegate

- (void)brushToolSelectSheet:(PLVHCBrushToolSelectSheet *)brushToolSelectSheet didSelectToolType:(PLVHCBrushToolType)toolType selectImage:(UIImage *)selectImage localTouch:(BOOL)localTouch{
    [self.brushToolBarView updateSelectToolType:toolType selectImage:selectImage];
    if (localTouch) { // 本地点击才需要发送JS事件
        [self updateSelectToolType:toolType];
    }
}

#pragma mark  PLVHCBrushColorSelectSheetDelegate

- (void)brushColorSelectSheet:(PLVHCBrushColorSelectSheet *)brushColorSelectSheet didSelectColor:(NSString *)color localTouch:(BOOL)localTouch{
    [self.brushToolBarView updateSelectColor:color];
    if (localTouch) { // 本地点击才需要发送JS事件
        [self updateSelectColor:color];
    }
}
@end
