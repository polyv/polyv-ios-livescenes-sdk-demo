//
//  PLVHCChatroomSheet.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2021/6/24.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVHCChatroomSheet.h"

// 工具类
#import "PLVHCUtils.h"

// UI
#import "PLVHCNewMessgaeTipView.h"
#import "PLVHCChatroomListView.h"
#import "PLVHCSendMessageView.h"
#import "PLVHCChatroomToolView.h"
#import "PLVHCEmojiSelectSheet.h"
#import "PLVHCSendMessageToolView.h"
#import "PLVHCSendMessageTextView.h"

// 模块
#import "PLVHCChatroomViewModel.h"
#import "PLVRoomDataManager.h"

// 依赖库
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import <PLVImagePickerController/PLVImagePickerController.h>

#pragma mark PLVImagePickerController 分类
@interface PLVImagePickerController (PLVHCOverwrite)
@end

@implementation PLVImagePickerController (PLVHCOverwrite)

- (void)setColumnNumber:(NSInteger)columnNumber {
    if (columnNumber <= 2) {
        columnNumber = 2;
    } else if (columnNumber >= 8) {
        columnNumber = 8;
    }

    [self setValue:@(columnNumber) forKey:@"_columnNumber"];
    
    PLVAlbumPickerController *albumPickerVc = [self.childViewControllers firstObject];
    albumPickerVc.columnNumber = columnNumber;
    [PLVImageManager manager].columnNumber = columnNumber;
}

@end

@interface PLVHCChatroomSheet()<
PLVHCChatroomViewModelDelegate,
PLVHCChatroomListViewDelegate,
PLVHCEmojiSelectSheetDelegate,
PLVHCChatroomToolViewDelegate,
PLVHCSendMessageViewDelegate
>

#pragma mark UI


/// view hierarchy
/// (UIView) superview
///  └── (PLVHCChatroomSheet) self
///          ├─ 常驻视图：
///          ├─ (PLVHCChatroomListView) chatroomListView
///          ├─ (PLVHCChatroomToolView) toolView
///          ├─ 动态显示视图：
///          ├─ (PLVHCNewMessgaeTipView) receiveNewMessageView
///          ├─ (PLVHCSendMessageView) sendMsgView
///          ├─ (PLVHCEmojiSelectSheet) emojiSelectSheet
///          └── (PLVImagePickerController) imagePicker
///
///

#pragma mark 常驻视图
@property (nonatomic, strong) PLVHCChatroomListView *chatroomListView; // 聊天室列表
@property (nonatomic, strong) PLVHCChatroomToolView *toolView; // 底部工具视图

#pragma mark 动态显示视图
@property (nonatomic, strong) PLVHCNewMessgaeTipView *receiveNewMessageView; // 新消息提示视图
@property (nonatomic, strong) PLVHCSendMessageView *sendMsgView; // 发送消息输入框视图
@property (nonatomic, strong) PLVHCEmojiSelectSheet *emojiSelectSheet; // emoji选择弹层
@property (nonatomic, strong) PLVImagePickerController *imagePicker;

#pragma mark 数据

@property (nonatomic, assign) NSUInteger newMessageCount; // 未读消息条数(PLVHCChatroomSheet 内部使用)
@property (nonatomic, assign) NSUInteger externalNewMsgCount; //  未读消息条数(用于回调给外部视图使用，不做chatroomListView是否在底部判断)
@property (nonatomic, assign) PLVRoomUserType userType; // 用户类型
@property (nonatomic, assign, getter=isStartClass) BOOL startClass; // 是否开始直播

@end

@implementation PLVHCChatroomSheet

#pragma mark - [ Life Cycle ]

- (instancetype)init {
    self = [super init];
    if (self) {
        self.userType = [PLVRoomDataManager sharedManager].roomData.roomUser.viewerType;
        
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#22273D"];
        self.layer.cornerRadius = 16;
        
        [self addSubview:self.chatroomListView];
        [self.chatroomListView addSubview:self.receiveNewMessageView];
        
        [self addSubview:self.toolView];
        [self addSubview:self.emojiSelectSheet];
        
        [PLVHCChatroomViewModel sharedViewModel].delegate = self;
        
        // 提前初始化 sendMsgView，避免弹出时才初始化导致卡顿
        [self sendMsgView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat bottomHeight = 34 + 8;
    CGFloat areaViewWidth = self.bounds.size.width;
    CGFloat areaViewHeight = self.bounds.size.height;
    CGFloat toolViewY= areaViewHeight - bottomHeight;
    CGFloat emojiSheetHeight = 131;
    
    self.chatroomListView.frame = CGRectMake(8, 0, areaViewWidth - 8 * 2, areaViewHeight - bottomHeight);
    self.receiveNewMessageView.frame = CGRectMake((areaViewWidth - 124 ) / 2, self.chatroomListView.frame.size.height - 28, 124, 28);
    
    self.toolView.frame = CGRectMake(8, toolViewY, areaViewWidth - 8 * 2, bottomHeight);
    self.emojiSelectSheet.frame = CGRectMake(8, areaViewHeight - bottomHeight - emojiSheetHeight, areaViewWidth - 8 * 2, emojiSheetHeight);
}

#pragma mark - [ Public Method ]

- (void)show {
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1;
    }];
}

- (void)showInView:(UIView *)parentView {
    if (!parentView) {
        return;
    }
    
    [parentView addSubview:self];
    // 将外部未读消息置为0、发送协议
    [self clearExternalNewMsgCount];
}

- (void)dismiss {
    [self removeFromSuperview];
}

- (void)startClass {
    self.startClass = YES;
    [self.toolView startClass];
    [self.chatroomListView startClass];
    [self.sendMsgView startClass];
}

- (void)finishClass {
    self.startClass = NO;
    [self.toolView finishClass];
    [self.chatroomListView finishClass];
    [self.sendMsgView finishClass];
}

#pragma mark - [ Private Method ]

#pragma mark Getter

- (PLVHCSendMessageView *)sendMsgView {
    if (!_sendMsgView) {
        _sendMsgView = [[PLVHCSendMessageView alloc] init];
        _sendMsgView.delegate = self;
    }
    return _sendMsgView;
}

- (PLVHCChatroomListView *)chatroomListView {
    if (!_chatroomListView) {
        _chatroomListView = [[PLVHCChatroomListView alloc] init];
        _chatroomListView.delegate = self;
    }
    return _chatroomListView;
}

- (PLVHCNewMessgaeTipView *)receiveNewMessageView {
    if (!_receiveNewMessageView) {
        _receiveNewMessageView = [[PLVHCNewMessgaeTipView alloc] init];
        [_receiveNewMessageView updateMeesageCount:0];
        
        __weak typeof(self) weakSelf = self;
        _receiveNewMessageView.didTapNewMessageView = ^{
            [weakSelf clearNewMessageCount];
            [weakSelf.chatroomListView scrollsToBottom:YES];
        };
    }
    return _receiveNewMessageView;
}

- (PLVHCChatroomToolView *)toolView {
    if (!_toolView) {
        _toolView = [[PLVHCChatroomToolView alloc] init];
        _toolView.delegate = self;
    }
    return _toolView;
}

- (PLVHCEmojiSelectSheet *)emojiSelectSheet {
    if (!_emojiSelectSheet) {
        _emojiSelectSheet = [[PLVHCEmojiSelectSheet alloc] init];
        _emojiSelectSheet.delegate = self;
        _emojiSelectSheet.alpha = 0;
    }
    return _emojiSelectSheet;
}

- (PLVImagePickerController *)imagePicker {
    if (!_imagePicker) {
        _imagePicker = [[PLVImagePickerController alloc] initWithMaxImagesCount:1 columnNumber:8 delegate:nil];
        _imagePicker.view.backgroundColor = [PLVColorUtil colorFromHexString:@"#1A1B1F"];
        _imagePicker.showSelectBtn = YES;
        _imagePicker.allowTakeVideo = NO;
        _imagePicker.allowPickingVideo = NO;
        _imagePicker.allowTakePicture = NO;
        _imagePicker.allowPickingOriginalPhoto = NO;
        _imagePicker.showPhotoCannotSelectLayer = YES;
        _imagePicker.cannotSelectLayerColor = [UIColor colorWithWhite:1.0 alpha:0.6];
        
        _imagePicker.iconThemeColor = [PLVColorUtil colorFromHexString:@"#366BEE"];
        _imagePicker.oKButtonTitleColorNormal = UIColor.whiteColor;
        _imagePicker.naviTitleColor = [UIColor colorWithWhite:0.6 alpha:1];
        _imagePicker.naviTitleFont = [UIFont systemFontOfSize:14.0];
        _imagePicker.barItemTextColor = [PLVColorUtil colorFromHexString:@"#366BEE"];
        _imagePicker.barItemTextFont = [UIFont systemFontOfSize:14.0];
        _imagePicker.naviBgColor = [PLVColorUtil colorFromHexString:@"#1A1B1F"];
        #pragma mark 图片选择回调
        [_imagePicker setPhotoPickerPageUIConfigBlock:^(UICollectionView *collectionView, UIView *bottomToolBar, UIButton *previewButton, UIButton *originalPhotoButton, UILabel *originalPhotoLabel, UIButton *doneButton, UIImageView *numberImageView, UILabel *numberLabel, UIView *divideLine) {
            divideLine.hidden = YES;
            collectionView.showsHorizontalScrollIndicator = NO;
            collectionView.backgroundColor = [PLVColorUtil colorFromHexString:@"#1A1B1F"];
            bottomToolBar.backgroundColor = [PLVColorUtil colorFromHexString:@"#1A1B1F"];
            bottomToolBar.layer.shadowColor = [UIColor colorWithRed:10/255.0 green:10/255.0 blue:17/255.0 alpha:1.0].CGColor;
            bottomToolBar.layer.shadowOffset = CGSizeMake(0,-1);
            bottomToolBar.layer.shadowOpacity = 1;
            bottomToolBar.layer.shadowRadius = 0;

            UIResponder *nextResponder = [collectionView nextResponder];
            if ([nextResponder isKindOfClass:UIView.class]) {
                [(UIView *)nextResponder setBackgroundColor:[PLVColorUtil colorFromHexString:@"#1A1B1F"]];
            }
        }];

        [_imagePicker setPhotoPickerPageDidLayoutSubviewsBlock:^(UICollectionView *collectionView, UIView *bottomToolBar, UIButton *previewButton, UIButton *originalPhotoButton, UILabel *originalPhotoLabel, UIButton *doneButton, UIImageView *numberImageView, UILabel *numberLabel, UIView *divideLine) {
            previewButton.hidden = YES;

            doneButton.layer.cornerRadius = 14.0;
            doneButton.backgroundColor = [PLVColorUtil colorFromHexString:@"#366BEE"];
            doneButton.frame = CGRectMake(CGRectGetMinX(doneButton.frame)-74.0/2, (CGRectGetHeight(doneButton.bounds)-28.0)/2, 74.0, 28.0);
        }];

        [_imagePicker setPhotoPickerPageDidRefreshStateBlock:^(UICollectionView *collectionView, UIView *bottomToolBar, UIButton *previewButton, UIButton *originalPhotoButton, UILabel *originalPhotoLabel, UIButton *doneButton, UIImageView *numberImageView, UILabel *numberLabel, UIView *divideLine) {
            numberLabel.hidden = YES;
            numberImageView.hidden = YES;
        }];

        [_imagePicker setAlbumCellDidLayoutSubviewsBlock:^(PLVAlbumCell *cell, UIImageView *posterImageView, UILabel *titleLabel) {
            titleLabel.textColor = UIColor.lightGrayColor;
            [(UITableViewCell *)cell setBackgroundColor:UIColor.clearColor];
            [(UITableViewCell *)cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            UIResponder *nextResponder = [(UITableViewCell *)cell nextResponder];
            if ([nextResponder isKindOfClass:UIView.class]) {
                [(UIView *)nextResponder setBackgroundColor:[PLVColorUtil colorFromHexString:@"#1A1B1F"]];
            }
            nextResponder = nextResponder.nextResponder;
            if ([nextResponder isKindOfClass:UIView.class]) {
                [(UIView *)nextResponder setBackgroundColor:[PLVColorUtil colorFromHexString:@"#1A1B1F"]];
            }
        }];

        __weak typeof(self)weakSelf = self;
        [_imagePicker setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
            if ([photos isKindOfClass:NSArray.class]) {
                [weakSelf sendImageWithImage:photos.firstObject];
                //clean选中缓存
                weakSelf.imagePicker.selectedAssets = [NSMutableArray array];
                [weakSelf.imagePicker popViewControllerAnimated:NO];
            }
        }];
        
        [_imagePicker setImagePickerControllerDidCancelHandle:^{
            //clean选中缓存
            weakSelf.imagePicker.selectedAssets = [NSMutableArray array];
            [weakSelf.imagePicker popViewControllerAnimated:NO];
        }];
    }
    return _imagePicker;
}

#pragma mark Setter

- (void)setNetState:(NSInteger)netState {
    _netState = netState;
    _sendMsgView.netState = netState;
    _chatroomListView.netState = netState;
}

#pragma mark NewMessageCount

- (void)addNewMessageCount {
    if (!self.startClass) {
        return;
    }
    self.newMessageCount ++;
    [self.receiveNewMessageView updateMeesageCount:self.newMessageCount];
}

- (void)clearNewMessageCount {
    self.newMessageCount = 0;
    [self.receiveNewMessageView updateMeesageCount:0];
}

/// 增加外部未读消息数、发送协议方法
- (void)addExternalNewMsgCount {
    if (!self.startClass ||
        self.superview) { // 未开播、已显示不做处理
        return;
    }
    self.externalNewMsgCount ++;
    [self notifydidChangeNewMessageCount:self.externalNewMsgCount];
}

/// 将外部未读消息数置0、发送协议方法
- (void)clearExternalNewMsgCount {
    self.externalNewMsgCount = 0;
    [self notifydidChangeNewMessageCount:0];
}

#pragma mark 网络是否可用
- (BOOL)netCan{
    return self.netState > 0 && self.netState < 4;
}

#pragma mark Show & Hiden EmojiSelectSheet

- (void)emojiSelectSheetShow:(BOOL)show{
    [UIView animateWithDuration:0.3 animations:^{
        self.emojiSelectSheet.alpha = show ? 1 : 0;
    }];
}

#pragma mark 显示图片选择器
- (void)imagePickerButtonAction {
    __weak typeof(self)weakSelf = self;
    [PLVAuthorizationManager requestAuthorizationWithType:PLVAuthorizationTypePhotoLibrary completion:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                [[PLVHCUtils sharedUtils].homeVC presentViewController:weakSelf.imagePicker animated:YES completion:nil];
            } else {
                [PLVHCUtils showAlertWithMessage:@"应用需要获取您的相册权限，请前往设置" cancelActionTitle:@"取消" cancelActionBlock:nil confirmActionTitle:@"设置" confirmActionBlock:^{
                    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    if ([[UIApplication sharedApplication] canOpenURL:url]) {
                        [[UIApplication sharedApplication] openURL:url];
                    }
                }];
            }
        });
    }];
}

#pragma mark 发送消息

- (void)sendImageWithImage:(UIImage *)image {
    if (![self netCan]) {
        [PLVHCUtils showToastInWindowWithMessage:@"当前网络不可用，请检查网络设置"];
        return;
    }
    
    BOOL success = [[PLVHCChatroomViewModel sharedViewModel] sendImageMessage:image];
    if (!success) {
        [PLVHCUtils showToastInWindowWithMessage:@"消息发送失败"];
    }
}

- (void)sendMessageAndClearTextView {
    if (self.toolView.textView.isInPlaceholder) {
        [PLVHCUtils showToastInWindowWithMessage:@"发送内容不能为空！"];
        return;
    }
    if (self.toolView.textView.attributedText.length > 0) {
        NSString *text = [self.toolView.textView plvTextForRange:NSMakeRange(0, self.toolView.textView.attributedText.length)];
        
        if (![self netCan]) {
            [PLVHCUtils showToastInWindowWithMessage:@"当前网络不可用，请检查网络设置"];
        } else {
            BOOL success = [[PLVHCChatroomViewModel sharedViewModel] sendSpeakMessage:text replyChatModel:nil];
            if (!success) {
                [PLVHCUtils showToastInWindowWithMessage:@"发送消息失败"];
            }
        }
    }
    [self.toolView.textView clearText];
}

#pragma mark 发送 PLVHCChatroomSheetDelegate 协议方法

- (void)notifydidChangeNewMessageCount:(NSUInteger)count {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(chatroomSheet:didChangeNewMessageCount:)]) {
        [self.delegate chatroomSheet:self didChangeNewMessageCount:count];
    }
}

#pragma mark - Event

#pragma mark - [ Delegate ]
#pragma mark PLVHCChatroomViewModel Protocol

- (void)chatroomViewModelDidSendMessage:(PLVHCChatroomViewModel *)viewModel {
    [self.chatroomListView didSendMessage];
    [self clearNewMessageCount];
}

- (void)chatroomViewModelDidResendMessage:(PLVHCChatroomViewModel *)viewModel {
    [self.chatroomListView didSendMessage];
    [self clearNewMessageCount];
}

- (void)chatroomViewModelDidSendProhibitMessgae:(PLVHCChatroomViewModel *)viewModel {
    [self.chatroomListView didSendMessage];
    [self clearNewMessageCount];
}

- (void)chatroomViewModelDidReceiveMessages:(PLVHCChatroomViewModel *)viewModel {
    BOOL isBottom = [self.chatroomListView didReceiveMessages];
    if (isBottom) { // tableview显示在最底部
        [self clearNewMessageCount];
    } else {
        // 统计未读消息数
        [self addNewMessageCount];
    }
    // 增加外部未读消息数、发送协议方法
    [self addExternalNewMsgCount];
}

- (void)chatroomViewModelDidReceiveCloseRoomMessage:(PLVHCChatroomViewModel *)viewModel {
    BOOL isBottom = [self.chatroomListView didReceiveMessages];
    if (isBottom) { // tableview显示在最底部
        [self clearNewMessageCount];
    } else {
        // 统计未读消息数
        [self addNewMessageCount];
    }
    [self.toolView setCloseRoomButtonState:[PLVChatroomManager sharedManager].closeRoom];
}

- (void)chatroomViewModelDidMessageDeleted:(PLVHCChatroomViewModel *)viewModel {
    [self.chatroomListView didMessageDeleted];
}

- (void)chatroomViewModel:(PLVHCChatroomViewModel *)viewModel loadHistorySuccess:(BOOL)noMore firstTime:(BOOL)first {
    [self.chatroomListView loadHistorySuccess:noMore firstTime:first];
}

- (void)chatroomViewModelLoadHistoryFailure:(PLVHCChatroomViewModel *)viewModel {
    [self.chatroomListView loadHistoryFailure];;
}


#pragma mark PLVHCChatroomListViewDelegate

- (void)chatroomListViewDidScrollTableViewUp:(PLVHCChatroomListView *)listView {
    [self clearNewMessageCount];
}

- (void)chatroomListView:(PLVHCChatroomListView *)listView didTapReplyMenuItem:(PLVChatModel *)model {
    [self.sendMsgView showWithChatModel:model];
}

#pragma mark PLVHCEmojiSelectSheetDelegate

- (void)emojiSelectSheet:(PLVHCEmojiSelectSheet *)sheet didReceiveEvent:(PLVHCEmojiSelectSheetEvent)event {
    if (event == PLVHCEmojiSelectSheetEventSend) {
        // 发送
        [self sendMessageAndClearTextView];
        [self.toolView setEmojiButtonState:NO];
        [self emojiSelectSheetShow:NO];
    } else {
        // 删除
        [self.toolView emojiDidDelete];
    }
}

- (void)emojiSelectSheet:(PLVHCEmojiSelectSheet *)sheet didSelectEmoticon:(PLVEmoticon *)emoticon {
    [self.toolView emojiDidSelectEmoticon:emoticon];
}

#pragma mark PLVHCChatroomToolViewDelegate

- (void)chatroomToolViewDidTapChatButton:(PLVHCChatroomToolView *)chatroomToolView emojiAttrStr:(NSAttributedString *)emojiAttrStr{
    [self.sendMsgView showWithAttributedString:emojiAttrStr];
}

- (void)chatroomToolViewDidTapImageButton:(PLVHCChatroomToolView *)chatroomToolView {
    [self imagePickerButtonAction];
}

- (void)chatroomToolViewDidTapEmojiButton:(PLVHCChatroomToolView *)chatroomToolView emojiButtonSelected:(BOOL)selected {
    [self emojiSelectSheetShow:selected];
}

- (void)chatroomToolViewDidTapCloseRoomButton:(PLVHCChatroomToolView *)chatroomToolView closeRoomButtonSelected:(BOOL)selected {
    
    // 与socket最真实状态校验，更新UI，防止误操作
    if ([PLVChatroomManager sharedManager].closeRoom == selected) {
        [self.toolView setCloseRoomButtonState:[PLVChatroomManager sharedManager].closeRoom];
        return;
    }
    
    BOOL sendSuccess = [[PLVChatroomManager sharedManager] sendCloseRoom:selected];
    if (sendSuccess) {
        NSString *string = selected ? @"已开启全体禁言" : @"已解除全体禁言";
        [PLVHCUtils showToastInWindowWithMessage:string];
    } 
    [self.toolView setCloseRoomButtonState:[PLVChatroomManager sharedManager].closeRoom];
}

#pragma mark PLVHCSendMessageViewDelegate

- (void)sendMessageViewDidTapImageButton:(PLVHCSendMessageView *)sendMessageView {
    [self imagePickerButtonAction];
}

@end
