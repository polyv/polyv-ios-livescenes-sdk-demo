//
//  PLVStickerCanvas.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/3/17.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVStickerCanvas.h"
#import "PLVStickerImageView.h"
#import "PLVStickerTextView.h"
#import "PLVStickerVideoView.h"
#import "PLVStickerPlayer.h"
#import "PLVMediaPlayerSampleBufferDisplayView.h"
#import <PLVFoundationSDK/PLVColorUtil.h>
#import "PLVSAUtils.h"

const NSInteger maxStickerImage = 10;
const NSInteger maxStickerText = 10;

@interface PLVStickerCanvas ()<
PLVStickerImageViewDelegate,
PLVStickerTextViewDelegate,
PLVStickerVideoViewDelegate
>

@property (nonatomic, strong) UIView *cusMskView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, assign) BOOL isFullScreen;
@property (nonatomic, strong) UIButton *deleteButton;

@property (nonatomic, assign) NSInteger curImageCount;
@property (nonatomic, assign) NSInteger curTextCount;
@property (nonatomic, strong) NSArray *images;

@end

@implementation PLVStickerCanvas

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]){
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [self addGestureRecognizer:tapGesture];
        self.clipsToBounds = YES;
        self.contentView.clipsToBounds = YES;
      
        [self addSubview:self.cusMskView];
        [self addSubview:self.contentView];
        
        self.isFullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
        
        [self updateUI];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    [self updateUI];
}

- (void)updateUI{
    // 需要和rtc摄像头采集的图像分辨率比例一致 默认9：16
    BOOL curFullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (curFullScreen){
        CGFloat height = self.bounds.size.height;
        CGFloat width = height * 16/ 9;
        CGFloat x = (self.bounds.size.width - width)/2;
        CGFloat y = 0;
        self.contentView.frame = CGRectMake(x, y, width, height);
    }
    else{
        CGFloat width = self.bounds.size.width;
        CGFloat height = width * 16/ 9;

        if (height > self.bounds.size.height){
            height = self.bounds.size.height;
            width = height * 9/ 16;
        }

        CGFloat x = (self.bounds.size.width - width)/2;
        CGFloat y = (self.bounds.size.height - height)/2;
        self.contentView.frame = CGRectMake(x, y, width, height);;
    }
    self.cusMskView.frame = self.bounds;
    // 横竖屏智适应
    if (curFullScreen != self.isFullScreen){
        // 初始化布局
        [self revertLayout];
    }
    
    self.isFullScreen = curFullScreen;
}

- (void)revertLayout{
    for (UIView *subView in self.contentView.subviews){
        if ([subView isKindOfClass:[PLVStickerImageView class]]){
            [subView removeFromSuperview];
        }
    }
    
    NSInteger defaultWidth = 150;
    NSInteger defaultHeight = 150;
    NSInteger x = 0;
    NSInteger y = 0;
    
    for (UIImage *image in self.images){
        defaultHeight = defaultWidth * (image.size.height / image.size.width);
        x = (self.contentView.bounds.size.width - defaultWidth)/2;
        y = (self.contentView.bounds.size.height - defaultHeight)/2;
        PLVStickerImageView *imageview = [[PLVStickerImageView alloc] initWithFrame:CGRectMake(x, y, defaultWidth, defaultHeight) contentImage:image];
        imageview.delegate = self;
        
        [self.contentView addSubview:imageview];
    }
    
    // 文字贴图重置坐标
    for (UIView *subView in self.contentView.subviews){
        if ([subView isKindOfClass:[PLVStickerTextView class]]){
            PLVStickerTextView *textView = (PLVStickerTextView *)subView;
            NSInteger startX = (self.contentView.bounds.size.width - textView.frame.size.width)/2;
            NSInteger startY = (self.contentView.bounds.size.height - textView.frame.size.height)/2 - 80;
            textView.frame = CGRectMake(startX, startY, textView.frame.size.width, textView.frame.size.height);
        }
    }
    
    // 视频贴图重置坐标
    for (UIView *subView in self.contentView.subviews){
        if ([subView isKindOfClass:[PLVStickerVideoView class]]){
            PLVStickerVideoView *videoView = (PLVStickerVideoView *)subView;
            [videoView resetRect];
        }
    }
}

- (UIView *)cusMskView{
    if (!_cusMskView){
        _cusMskView = [[UIView alloc] init];
        _cusMskView.backgroundColor = [PLVColorUtil colorFromHexString:@"#000000" alpha:0.3];
    }
    return _cusMskView;
}

- (UIView *)contentView{
    if (!_contentView){
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = [UIColor clearColor];
    }
    return _contentView;
}

- (UIButton *)deleteButton{
    if (!_deleteButton){
        _deleteButton = [[UIButton alloc] init];
        [_deleteButton setImage:[PLVSAUtils imageForLiveroomResource:@"plvsa_liveroom_sticker_delete"] forState:UIControlStateNormal];
        [_deleteButton setTitle:@"拖动到此处删除" forState:UIControlStateNormal];
        [_deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_deleteButton setBackgroundColor:[PLVColorUtil colorFromHexString:@"#000000" alpha:0.6]];
        _deleteButton.layer.cornerRadius = 21;
        _deleteButton.titleLabel.font = [UIFont systemFontOfSize:14];
    }
    return _deleteButton;
}

#pragma mark -- PUBLIC
- (void)setEnableEdit:(BOOL)enableEdit{
    for (UIView *subview in self.contentView.subviews) {
        if ([subview isKindOfClass:[PLVStickerImageView class]]) {
            PLVStickerImageView *view = (PLVStickerImageView *)subview;
            view.enableEdit = enableEdit;
        } else if ([subview isKindOfClass:[PLVStickerTextView class]]) {
            PLVStickerTextView *view = (PLVStickerTextView *)subview;
            view.enableEdit = enableEdit;
        }
    }
}

- (void)showCanvasWithImages:(NSArray<UIImage *> *)images{
    self.images = images;
    
    NSInteger newCount = self.curImageCount + images.count;
    NSInteger addCount = newCount > maxStickerImage ? (maxStickerImage - self.curImageCount) : images.count;
    NSMutableArray *showImages = [[NSMutableArray alloc] init];
    for (int i=0; i< addCount; i++){
        [showImages addObject:images[i]];
    }
    
    _curImageCount += addCount;
    
    // 图片默认显示宽度 100 根据image 宽高等比缩放默认显示高度
    NSInteger defaultWidth = 150;
    NSInteger defaultHeight = 150;
    NSInteger x = 0;
    NSInteger y = 0;
    for (UIImage *image in showImages){
        defaultHeight = defaultWidth * (image.size.height / image.size.width);
        x = (self.contentView.bounds.size.width - defaultWidth)/2;
        y = (self.contentView.bounds.size.height - defaultHeight)/2;
        PLVStickerImageView *imageview = [[PLVStickerImageView alloc] initWithFrame:CGRectMake(x, y, defaultWidth, defaultHeight) contentImage:image];
        imageview.delegate = self;
        
        [self.contentView addSubview:imageview];
    }
}

- (void)addVideoStickerWithURL:(NSURL *)fileURL{
    // 图片默认显示宽度 100 根据image 宽高等比缩放默认显示高度
    NSInteger defaultWidth = 150;
    NSInteger defaultHeight = 150;
    NSInteger x = 0;
    NSInteger y = 0;
    x = (self.contentView.bounds.size.width - defaultWidth)/2;
    y = (self.contentView.bounds.size.height - defaultHeight)/2;
    PLVStickerVideoView *imageview = [[PLVStickerVideoView alloc] initWithFrame:CGRectMake(x, y, defaultWidth, defaultHeight) videoURL:fileURL];;
    imageview.delegate = self;
    
    [self.contentView addSubview:imageview];
}

- (UIImage *)generateImageWithTransparentBackground {
    if (self.contentView.subviews.count == 0)
        return nil;
    
    // 创建一个带透明通道的上下文
    CGSize canvasSize = self.contentView.bounds.size;
    UIGraphicsBeginImageContextWithOptions(canvasSize, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 清空背景，确保背景是透明的
    CGContextClearRect(context, self.contentView.bounds);
    
    // 遍历所有子视图并渲染
    for (UIView *subview in self.contentView.subviews) {
        if ([subview isKindOfClass:[PLVStickerImageView class]] ||
            [subview isKindOfClass:[PLVStickerTextView class]] ||
            [subview isKindOfClass:[PLVStickerVideoView class]]) {
            // 保存当前上下文状态
            CGContextSaveGState(context);
            
            // 将坐标系转换为子视图的坐标系
            CGContextTranslateCTM(context, subview.frame.origin.x, subview.frame.origin.y);
            
            // 应用子视图的变换（如果有）
            CGContextConcatCTM(context, subview.transform);
            
            // 特殊处理视频贴图
            if ([subview isKindOfClass:[PLVStickerVideoView class]]) {
                PLVStickerVideoView *videoView = (PLVStickerVideoView *)subview;
                UIImage *videoSnapshot = [self getVideoSnapshotFromVideoView:videoView];

                if (videoSnapshot) {
                    // 绘制视频截图
                    [videoSnapshot drawInRect:CGRectMake(0, 0, subview.bounds.size.width, subview.bounds.size.height)];
                } else {
                    // 如果没有视频截图，渲染普通层
                    [subview.layer renderInContext:context];
                }
            } else {
                // 渲染其他类型的子视图
                [subview.layer renderInContext:context];
            }
            
            // 恢复上下文状态
            CGContextRestoreGState(context);
        }
    }
    
    // 从上下文中获取图像
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

/// 从视频贴图中获取视频截图
/// @param videoView 视频贴图视图
- (UIImage *)getVideoSnapshotFromVideoView:(PLVStickerVideoView *)videoView {
    if (!videoView || !videoView.player) {
        return nil;
    }
    
    // 使用播放器的公开snapshot接口
    PLVStickerPlayer *player = videoView.player;
    if ([player respondsToSelector:@selector(snapshot)]) {
        UIImage *snapshot = [player snapshot];
        if (snapshot) {
            return snapshot;
        }
    }
    
    // 如果无法获取播放器截图，尝试使用drawViewHierarchyInRect方法作为备选方案
    UIGraphicsBeginImageContextWithOptions(videoView.bounds.size, NO, [UIScreen mainScreen].scale);
    BOOL success = [videoView drawViewHierarchyInRect:videoView.bounds afterScreenUpdates:NO];
    UIImage *image = nil;
    if (success) {
        image = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return image;
}

- (BOOL)hasMaxTextCount{
    return self.curTextCount >= maxStickerText;
}

- (BOOL)hasVideo{
    for (UIView *subview in self.contentView.subviews) {
        if ([subview isKindOfClass:[PLVStickerVideoView class]]) {
            return YES;
        }
    }
    return NO;
}

- (void)tapAction:(UITapGestureRecognizer *)tapGesture{
    // 如果当前处于文字贴纸添加或者编辑状态 （StickerTemplateView 显示中）不处理
    if (self.currentEditingTextView.editState >= PLVStickerTextEditStateActionVisible)
        return;

    // 重置所有文本贴纸状态
    [self resetAllTextViewsState];

    // 重置所有图片贴纸状态
    [self resetAllImageViewsState];

    // 重置所有视频贴纸状态（关闭控制栏）
    [self resetAllVideoViewsState];

    self.cusMskView.hidden = YES;
    self.enableEdit = NO;
    
    // 关闭编辑模式
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerCanvasExitEditMode:)]){
        [self.delegate stickerCanvasExitEditMode:self];
    }
}

- (BOOL)isDeleteAllSticker{
    for (UIView *subview in self.contentView.subviews) {
        if ([subview isKindOfClass:[PLVStickerImageView class]] || 
            [subview isKindOfClass:[PLVStickerTextView class]] ||
            [subview isKindOfClass:[PLVStickerVideoView class]]) {
            return NO;
        }
    }
    return YES;
}

#pragma mark -- PLVStickerImageViewDelegate
- (void)plv_StickerViewDidTapContentView:(PLVStickerImageView *)stickerView{
    // 检查并处理模版界面状态：当从文本贴纸切换到图片贴纸时
    [self handleTemplateViewStateBeforeSwitchingToImageSticker];

    // 实现贴纸焦点切换的互斥逻辑：当图片贴纸被选中时，重置所有文本贴纸状态
    [self resetAllTextViewsState];

    // 重置其他图片贴纸的选中状态（互斥选中）
    [self resetOtherImageViewsStateExcept:stickerView];

    // 设置当前图片贴纸为选中状态
    stickerView.enabledBorder = YES;

    // 进入编辑模式
    self.enableEdit = YES;
    self.cusMskView.hidden = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerCanvasEnterEditMode:)]){
        [self.delegate stickerCanvasEnterEditMode:self];
    }
    
    // 前一个获取焦点的贴纸组件去掉焦点
    for (UIView *subview in self.contentView.subviews) {
        if ([subview isKindOfClass:[PLVStickerImageView class]]) {
            PLVStickerImageView *view = (PLVStickerImageView *)subview;
            view.enabledBorder = NO;
        }
    }
    // 获取焦点
    stickerView.enabledBorder = YES;
}

- (void)plv_StickerViewHandleMove:(PLVStickerImageView *)stickerView point:(CGPoint)point gestureEnded:(BOOL)gestureEnded{
    NSLog(@"point: %@", NSStringFromCGPoint(point));
    [self addSubview:self.deleteButton];
    self.deleteButton.hidden = gestureEnded;

    self.deleteButton.frame = CGRectMake((self.bounds.size.width - 160)/2, (self.bounds.size.height - 42 -35), 160, 42);
    if (CGRectContainsPoint(self.deleteButton.frame, point)){
        self.deleteButton.backgroundColor = [UIColor redColor];
        if (gestureEnded){
            [stickerView removeFromSuperview];
            self.curImageCount --;
            if ([self isDeleteAllSticker]){
                // 退出编辑模式
                [self tapAction:nil];
                self.curImageCount = 0;
            }
        }
    }else{
        [self.deleteButton setBackgroundColor:[PLVColorUtil colorFromHexString:@"#000000" alpha:0.6]];
    }
}

- (void)plv_StickerViewDidTapDoneButton:(PLVStickerImageView *)stickerView {
    // 完成编辑，退出编辑模式
    [self tapAction:nil];  // 调用现有的退出编辑方法
}

#pragma mark PLVStickerVideoViewDelegate

- (void)plv_StickerVideoViewDidTapContentView:(PLVStickerVideoView *)stickerView{
    // 实现贴纸焦点切换的互斥逻辑：当视频贴纸被选中时，重置所有文本贴纸状态
    [self resetAllTextViewsState];

    // 重置所有图片贴纸状态
    [self resetAllImageViewsState];

    // 重置其他视频贴纸状态（关闭其他视频的控制栏）
    [self resetOtherVideoViewsStateExcept:stickerView];

    // 进入编辑模式
    self.cusMskView.hidden = NO;
    self.enableEdit = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerCanvasEnterEditMode:)]){
        [self.delegate stickerCanvasEnterEditMode:self];
    }
}

- (void)plv_StickerVideoViewDidUpdateAudioPacket:(PLVStickerVideoView *)stickerView audioPacket:(NSDictionary *)audioPacket {
    // 处理音频数据包
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerCanvasDidUpdateAudioPacket:audioPacket:)]) {
        [self.delegate stickerCanvasDidUpdateAudioPacket:self audioPacket:audioPacket];
    }
}

- (void)plv_StickerVideoView:(PLVStickerVideoView *)stickerView didChangeAudioVolume:(CGFloat)stickerVolume microphoneVolume:(CGFloat)micVolume {
    // 传递音量设置变化给代理
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerCanvas:didChangeAudioVolume:microphoneVolume:)]) {
        [self.delegate stickerCanvas:self didChangeAudioVolume:stickerVolume microphoneVolume:micVolume];
    }
}

- (void)plv_StickerVideoViewDidTapDeleteButton:(PLVStickerVideoView *)stickerView {
    // 检查是否删除了所有贴纸
    if ([self isDeleteAllSticker]) {
        // 退出编辑模式
        [self tapAction:nil];
    }
}

- (void)addTextStickerWithModel:(PLVStickerTextModel *)textModel {
    if (self.curTextCount >= maxStickerText) {
        NSLog(@"已达到最大文本贴图数量限制: %ld", (long)maxStickerText);
        return;
    }
    
    // 默认初始位置
    NSInteger startX = (self.contentView.bounds.size.width - textModel.defaultSize.width)/2;
    NSInteger startY = (self.contentView.bounds.size.height - textModel.defaultSize.height)/2 - 80;
    CGRect frame = CGRectMake(startX, startY, textModel.defaultSize.width, textModel.defaultSize.height);
    PLVStickerTextView *textView = [[PLVStickerTextView alloc] initWithFrame:frame textModel:textModel];

    textView.delegate = self;
    textView.enableEdit = YES;
    // 标记为新增贴纸
    textView.isNewlyAdded = YES;
    // 新增的stickertext 处于编辑状态
    textView.editState = PLVStickerTextEditStateActionVisible;
    
    [self.contentView addSubview:textView];
    self.curTextCount++;
}

- (void)updateTextStickerWithModel:(PLVStickerTextModel *)textModel {
    // 更新当前 拥有焦点的贴纸数据
    if (self.currentEditingTextView) {
        // 更新样式和文案
        [self.currentEditingTextView updateTextMode:textModel];
    }
    else{
        
    }    
}

- (void)executeDone{
    if (self.currentEditingTextView){
        [self.currentEditingTextView executeDone];
    }
}

- (void)executeCancel{
    if (self.currentEditingTextView){
        [self.currentEditingTextView executeCancel];
    }
}

- (void)exitEditMode{
    // 重置当前贴纸状态 否则tapAction 不会顺利执行
    if (self.currentEditingTextView){
        self.currentEditingTextView.editState = PLVStickerTextEditStateNormal;
    }

    // 借用手势点击事件处理方法
    [self tapAction:nil];
}

- (void)executeCancelDelete:(PLVStickerTextView *)textView {
    NSLog(@"executeCancelDelete: isNewlyAdded = %@", textView.isNewlyAdded ? @"YES" : @"NO");
    if (textView.isNewlyAdded) {
        // 新增的贴纸：直接删除
        NSLog(@"删除新增贴纸");
        [textView removeFromSuperview];
        self.curTextCount--;
    } else {
        // 已存在的贴纸：恢复显示
        NSLog(@"恢复已存在贴纸显示");
        textView.hidden = NO;
    }
}

- (void)executeConfirmDelete:(PLVStickerTextView *)textView {
    // 无论新增还是已存在的贴纸，都彻底删除
    [textView removeFromSuperview];
    self.curTextCount--;
    
    // 检查是否删除了所有贴纸
    if ([self isDeleteAllSticker]) {
        // 退出编辑模式
        [self tapAction:nil];
        self.curTextCount = 0;
    }
}

- (PLVStickerTextView *)currentEditingTextView{
    // 逆序遍历 找到第一个处于编辑状态的贴纸    
    for (NSInteger i = self.contentView.subviews.count - 1; i >= 0; i--) {
        UIView *subview = self.contentView.subviews[i];
        if ([subview isKindOfClass:[PLVStickerTextView class]]) {
            PLVStickerTextView *textView = (PLVStickerTextView *)subview;
            // 检查是否处于编辑状态（除了普通状态都算编辑状态）
            if (textView.editState != PLVStickerTextEditStateNormal) {
                return textView;
            }
        }
    }
    return nil;
}

#pragma mark -- PLVStickerTextViewDelegate

- (void)plv_StickerTextViewDidTapContentView:(PLVStickerTextView *)stickerTextView {
    // 实现贴纸焦点切换的互斥逻辑：当文本贴纸被选中时，重置所有图片贴纸状态
    [self resetAllImageViewsState];

    // 进入编辑模式
    self.cusMskView.hidden = NO;
    self.enableEdit = YES;
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerCanvasEnterEditMode:)]){
        [self.delegate stickerCanvasEnterEditMode:self];
    }
}

- (void)plv_StickerTextViewHandleMove:(PLVStickerTextView *)stickerTextView point:(CGPoint)point gestureEnded:(BOOL)ended {
    NSLog(@"text point: %@", NSStringFromCGPoint(point));
    [self addSubview:self.deleteButton];
    self.deleteButton.hidden = ended;

    self.deleteButton.frame = CGRectMake((self.bounds.size.width - 160)/2, (self.bounds.size.height - 42 -35), 160, 42);
    if (CGRectContainsPoint(self.deleteButton.frame, point)){
        self.deleteButton.backgroundColor = [UIColor redColor];
        if (ended){
            [stickerTextView removeFromSuperview];
            self.curTextCount--;
            if ([self isDeleteAllSticker]){
                // 退出编辑模式
                [self tapAction:nil];
                self.curTextCount = 0;
            }
        }
    }else{
        [self.deleteButton setBackgroundColor:[PLVColorUtil colorFromHexString:@"#000000" alpha:0.6]];
    }
}

- (void)plv_StickerTextViewDidBeginEditing:(PLVStickerTextView *)stickerTextView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerCanvasBeginEditingText:)]) {
        [self.delegate stickerCanvasBeginEditingText:self];
    }
}

- (void)plv_StickerTextViewDidEndEditing:(PLVStickerTextView *)stickerTextView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerCanvasEndEditingText:)]) {
        [self.delegate stickerCanvasEndEditingText:self];
    }
}

- (void)plv_StickerTextView:(PLVStickerTextView *)stickerTextView didChangeEditState:(PLVStickerTextEditState)editState {
    // 处理文本贴纸状态变化
    switch (editState) {
        case PLVStickerTextEditStateSelected:
        case PLVStickerTextEditStateActionVisible:
        case PLVStickerTextEditStateTextEditing:
            // 取消其他文本贴纸的选中状态（互斥选中）
            [self resetOtherTextViewsStateExcept:stickerTextView];
            
            // 进入编辑模式
            self.cusMskView.hidden = NO;
            self.enableEdit = YES;
            if (self.delegate && [self.delegate respondsToSelector:@selector(stickerCanvasEnterEditMode:)]) {
                [self.delegate stickerCanvasEnterEditMode:self];
            }
            
            // 单独回调文本贴纸状态变化
            if (self.delegate && [self.delegate respondsToSelector:@selector(stickerCanvasTextEditStateChanged:textView:)]){
                [self.delegate stickerCanvasTextEditStateChanged:self textView:stickerTextView];
            }
            
            break;
            
        case PLVStickerTextEditStateNormal:
            // 检查是否还有其他文本贴纸处于编辑状态
            if (![self hasAnyTextViewInEditState]) {
                // 退出编辑模式
                self.cusMskView.hidden = YES;
                self.enableEdit = NO;
                if (self.delegate && [self.delegate respondsToSelector:@selector(stickerCanvasExitEditMode:)]) {
                    [self.delegate stickerCanvasExitEditMode:self];
                }
            }
            break;
    }
}

#pragma mark - State Management Helper Methods

- (void)resetOtherTextViewsStateExcept:(PLVStickerTextView *)exceptTextView {
    for (UIView *subview in self.contentView.subviews) {
        if ([subview isKindOfClass:[PLVStickerTextView class]] && subview != exceptTextView) {
            PLVStickerTextView *textView = (PLVStickerTextView *)subview;
            [textView resetToNormalState];
        }
    }
}

- (void)resetAllTextViewsState {
    for (UIView *subview in self.contentView.subviews) {
        if ([subview isKindOfClass:[PLVStickerTextView class]]) {
            PLVStickerTextView *textView = (PLVStickerTextView *)subview;
            [textView resetToNormalState];
        }
    }
}

- (BOOL)hasAnyTextViewInEditState {
    for (UIView *subview in self.contentView.subviews) {
        if ([subview isKindOfClass:[PLVStickerTextView class]]) {
            PLVStickerTextView *textView = (PLVStickerTextView *)subview;
            if (textView.editState != PLVStickerTextEditStateNormal) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)plv_StickerTextViewDidTapDeleteButton:(PLVStickerTextView *)stickerTextView {
    // 进入删除模式，设置模版界面的删除状态
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerCanvasTextViewDidEnterDeleteMode:)]) {
        [self.delegate stickerCanvasTextViewDidEnterDeleteMode:stickerTextView];
    }
}

#pragma mark - Image Sticker State Management Helper Methods

/// 重置除指定图片贴纸外的其他图片贴纸状态
- (void)resetOtherImageViewsStateExcept:(PLVStickerImageView *)exceptImageView {
    for (UIView *subview in self.contentView.subviews) {
        if ([subview isKindOfClass:[PLVStickerImageView class]] && subview != exceptImageView) {
            PLVStickerImageView *imageView = (PLVStickerImageView *)subview;
            imageView.enabledBorder = NO; // 取消边框显示，表示取消选中
        }
    }
}

/// 重置所有图片贴纸状态
- (void)resetAllImageViewsState {
    for (UIView *subview in self.contentView.subviews) {
        if ([subview isKindOfClass:[PLVStickerImageView class]]) {
            PLVStickerImageView *imageView = (PLVStickerImageView *)subview;
            imageView.enabledBorder = NO; // 取消边框显示，表示取消选中
        }
    }
}

#pragma mark - Video Sticker State Management Helper Methods

/// 重置除指定视频贴纸外的其他视频贴纸状态
- (void)resetOtherVideoViewsStateExcept:(PLVStickerVideoView *)exceptVideoView {
    for (UIView *subview in self.contentView.subviews) {
        if ([subview isKindOfClass:[PLVStickerVideoView class]] && subview != exceptVideoView) {
            PLVStickerVideoView *videoView = (PLVStickerVideoView *)subview;
            // 关闭控制栏
            [videoView hideVideoControl];
            // 取消边框显示
            videoView.enabledBorder = NO;
        }
    }
}

/// 重置所有视频贴纸状态
- (void)resetAllVideoViewsState {
    for (UIView *subview in self.contentView.subviews) {
        if ([subview isKindOfClass:[PLVStickerVideoView class]]) {
            PLVStickerVideoView *videoView = (PLVStickerVideoView *)subview;
            // 关闭控制栏
            [videoView hideVideoControl];
            // 取消边框显示
            videoView.enabledBorder = NO;
        }
    }
}

#pragma mark - Template View State Management

/// 处理模版界面状态：当从文本贴纸切换到图片贴纸时
- (void)handleTemplateViewStateBeforeSwitchingToImageSticker {
    // 检查是否有文本贴纸处于编辑状态且模版界面可能正在显示
    if ([self hasTextStickerInEditingState]) {
        // 通过代理通知上层处理模版界面状态
        if (self.delegate && [self.delegate respondsToSelector:@selector(stickerCanvasRequestHandleTemplateViewState:)]) {
            [self.delegate stickerCanvasRequestHandleTemplateViewState:self];
        }
    }
}

/// 检查是否有文本贴纸处于编辑状态
- (BOOL)hasTextStickerInEditingState {
    for (UIView *subview in self.contentView.subviews) {
        if ([subview isKindOfClass:[PLVStickerTextView class]]) {
            PLVStickerTextView *textView = (PLVStickerTextView *)subview;
            // 检查是否处于actionshow或textedit状态
            if (textView.editState == PLVStickerTextEditStateActionVisible ||
                textView.editState == PLVStickerTextEditStateTextEditing) {
                return YES;
            }
        }
    }
    return NO;
}

@end
