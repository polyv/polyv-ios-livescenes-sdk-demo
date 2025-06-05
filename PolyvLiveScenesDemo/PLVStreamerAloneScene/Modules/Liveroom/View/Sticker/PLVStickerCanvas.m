//
//  PLVStickerCanvas.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/3/17.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVStickerCanvas.h"
#import "PLVStickerImageView.h"
#import <PLVFoundationSDK/PLVColorUtil.h>
#import "PLVSAUtils.h"

const NSInteger maxStickerImage = 10;

@interface PLVStickerCanvas ()<
PLVStickerImageViewDelegate
>

@property (nonatomic, strong) UIView *cusMskView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, assign) BOOL isFullScreen;
@property (nonatomic, strong) UIButton *deleteButton;

@property (nonatomic, assign) NSInteger curImageCount;
@property (nonatomic, strong) NSArray *images;
@end

@implementation PLVStickerCanvas

- (instancetype)init{
    if (self = [super init]){
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [self addGestureRecognizer:tapGesture];
      
        [self addSubview:self.cusMskView];
        [self addSubview:self.contentView];
        
        self.isFullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    BOOL curFullScreen = [UIScreen mainScreen].bounds.size.width > [UIScreen mainScreen].bounds.size.height;
    if (curFullScreen){
        NSInteger height = self.bounds.size.height;
        CGFloat width = height * 16/ 9;
        CGFloat x = (self.bounds.size.width - width)/2;
        CGFloat y = 0;
        self.contentView.frame = CGRectMake(x, y, width, height);
    }
    else{
        NSInteger width = self.bounds.size.width;
        CGFloat height = width * 16/ 9;
        CGFloat x = 0;
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
        [subView removeFromSuperview];
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
        if ([subview isKindOfClass:[PLVStickerImageView class]]) {

            // 保存当前上下文状态
            CGContextSaveGState(context);
            
            // 将坐标系转换为子视图的坐标系
            CGContextTranslateCTM(context, subview.frame.origin.x, subview.frame.origin.y);
            
            // 应用子视图的变换（如果有）
            CGContextConcatCTM(context, subview.transform);
            
            // 渲染子视图
            [subview.layer renderInContext:context];
            
            // 恢复上下文状态
            CGContextRestoreGState(context);
        }
    }
    
    // 从上下文中获取图像
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)tapAction:(UITapGestureRecognizer *)tapGesture{
    // 关闭编辑模式
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerCanvasExitEditMode:)]){
        [self.delegate stickerCanvasExitEditMode:self];
    }
    self.cusMskView.hidden = YES;
}

- (BOOL)isDeleteAllSticker{
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[PLVStickerImageView class]]) {
            return NO;
        }
    }
    return YES;
}

#pragma mark -- PLVStickerImageViewDelegate
- (void)plv_StickerViewDidTapContentView:(PLVStickerImageView *)stickerView{
    // 进入编辑模式
    self.cusMskView.hidden = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerCanvasEnterEditMode:)]){
        [self.delegate stickerCanvasEnterEditMode:self];
    }
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


@end
