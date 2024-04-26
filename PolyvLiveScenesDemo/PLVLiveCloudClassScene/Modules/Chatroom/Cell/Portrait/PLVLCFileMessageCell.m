//
//  PLVLCFileMessageCell.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2022/7/19.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCFileMessageCell.h"
#import "PLVChatTextView.h"
#import "PLVLCUtils.h"
#import <PLVLiveScenesSDK/PLVFileMessage.h>

@interface PLVLCFileMessageCell ()

#pragma mark 数据

/// 消息数据模型
@property (nonatomic, strong) PLVFileMessage *fileMessage;

#pragma mark UI

/// 文件名内容视图
@property (nonatomic, strong) PLVChatTextView *textView;
/// 背景气泡
@property (nonatomic, strong) UIView *bubbleView;
/// 文件类型图标
@property (nonatomic, strong) UIImageView *fileImageView;
/// 手势视图
@property (nonatomic, strong) UIView *tapGestureView;

@end


@implementation PLVLCFileMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.textView];
        [self.contentView addSubview:self.fileImageView];
        [self.contentView addSubview:self.tapGestureView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.cellWidth == 0) {
        return;
    }
    
    CGFloat originX = self.nickLabel.frame.origin.x;
    CGFloat originY =  self.nickLabel.frame.origin.y + 20;
    
    CGFloat xPadding = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 20.0 : 16.0; // 头像左间距，气泡右间距
    CGFloat bubblePadding =  12;//textView、fileImageView与bubble的内部间距均为12
    
    CGFloat imageViewWidth = 40;
    CGFloat imageViewHeight = 48;
    
    CGFloat maxTextViewWidth = self.cellWidth - originX - xPadding - imageViewWidth - bubblePadding * 3;
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(maxTextViewWidth, MAXFLOAT)];
    
    self.textView.frame = CGRectMake(originX + bubblePadding, originY + (imageViewHeight - textViewSize.height) / 2 + bubblePadding, textViewSize.width, textViewSize.height);
    self.fileImageView.frame = CGRectMake(originX + bubblePadding * 2 + textViewSize.width, originY + bubblePadding, imageViewWidth, imageViewHeight);
    CGSize bubbleSize = CGSizeMake(textViewSize.width + imageViewWidth + bubblePadding * 3, imageViewHeight + bubblePadding * 2);

    
    self.bubbleView.frame = CGRectMake(originX, originY, bubbleSize.width, bubbleSize.height);
    self.tapGestureView.frame = CGRectMake(originX, originY, bubbleSize.width, bubbleSize.height);
    
    // 绘制气泡外部曲线
    CAShapeLayer *maskLayer = [PLVLCMessageCell bubbleLayerWithSize:bubbleSize];
    self.bubbleView.layer.mask = maskLayer;
}

#pragma mark - Getter

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [PLVColorUtil colorFromHexString:@"#2B2C35"];
    }
    return _bubbleView;
}

- (PLVChatTextView *)textView {
    if (!_textView) {
        _textView = [[PLVChatTextView alloc] init];
        _textView.textContainer.maximumNumberOfLines = 2;
        _textView.textContainer.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return _textView;
}

- (UIImageView *)fileImageView {
    if (!_fileImageView) {
        _fileImageView = [[UIImageView alloc] init];
        _fileImageView.layer.masksToBounds = YES;
        _fileImageView.userInteractionEnabled = NO;
        _fileImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _fileImageView;
}

- (UIView *)tapGestureView {
    if (!_tapGestureView) {
        _tapGestureView = [[UIView alloc] init];
        _tapGestureView.backgroundColor = [UIColor clearColor];
        _tapGestureView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureViewAction)];
        [_tapGestureView addGestureRecognizer:tap];
    }
    return _tapGestureView;
}

#pragma mark - UI

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    [super updateWithModel:model loginUserId:loginUserId cellWidth:cellWidth];
    
    if (self.cellWidth == 0 || ![PLVLCFileMessageCell isModelValid:model]) {
        self.cellWidth = 0;
        return;
    }
    
    self.fileMessage = model.message;
    
    NSMutableAttributedString *contentLabelString;
    if (model.attributeString) { // 如果在 model 中已经存在计算好的 消息多属性文本 ，那么 就直接使用；
        contentLabelString = model.attributeString;
    } else {
        contentLabelString = [PLVLCFileMessageCell contentLabelAttributedStringWithMessage:model.message
                                                                                      user:model.user];
        model.attributeString = contentLabelString;
    }
    
    [self.textView setContent:contentLabelString showUrl:NO];
    
    UIImage *fileImageView = [PLVLCFileMessageCell imageWithMessage:model.message];
    [self.fileImageView setImage:fileImageView];
    
}

#pragma mark UI - ViewModel

/// 生成消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(id)message user:(PLVChatUser *)user {
    NSString *content = @"";
    if ([message isKindOfClass:[PLVFileMessage class]]) {
        PLVFileMessage *fileMessage = (PLVFileMessage *)message;
        content = fileMessage.name;
    } else {
        content = (NSString *)message;
    }
    
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:16.0],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:@"#ADADC0"]
    };
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:content attributes:attributeDict];
    return attributedString;
}

/// 获取文件类型图标
+ (UIImage *)imageWithMessage:(PLVFileMessage *)message {
    NSString *fileUrl = message.url;
    
    if (![PLVFdUtil checkStringUseable:fileUrl]) {
        return nil;
    }
    
    NSString *fileType = [[[fileUrl pathExtension] lowercaseString] substringToIndex:3];
    NSString *fileImageString = [NSString stringWithFormat:@"plvlc_chatroom_file_%@_icon",fileType];
    
    return [PLVLCUtils imageForChatroomResource:fileImageString];
}

#pragma mark - 高度计算

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    CGFloat cellHeight = [super cellHeightWithModel:model cellWidth:cellWidth];
    if (cellHeight == 0 || ![PLVLCFileMessageCell isModelValid:model]) {
        return 0;
    }
    
    CGFloat originY = 28.0; // 64 为气泡初始y值
    CGFloat imageViewHeight = 48;
    
    return originY + 12 + imageViewHeight + 12 + 16;
}

#pragma mark - Action

- (void)tapGestureViewAction {
    NSString *url = self.fileMessage.url;
    if ([PLVFdUtil checkStringUseable:url]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    }
}


#pragma mark - Utils

+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    id message = model.message;
    if (!message || ![message isKindOfClass:[PLVFileMessage class]]) {
        return NO;
    }
    return YES;
}

@end
