//
//  PLVLCLandscapeFileCell.m
//  PolyvLiveScenesDemo
//
//  Created by Dan on 2022/7/19.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLCLandscapeFileCell.h"
#import "PLVChatTextView.h"
#import "PLVLCUtils.h"
#import <PLVLiveScenesSDK/PLVFileMessage.h>
#import <PLVFoundationSDK/PLVColorUtil.h>

@interface PLVLCLandscapeFileCell ()

#pragma mark 数据

/// 消息数据模型
@property (nonatomic, strong) PLVFileMessage *fileMessage;
/// cell宽度
@property (nonatomic, assign) CGFloat cellWidth;
/// 登录用户的聊天室userId
@property (nonatomic, strong) NSString *loginUserId;

#pragma mark UI

/// 消息文本内容视图
@property (nonatomic, strong) PLVChatTextView *textView;
/// 文件类型图片
@property (nonatomic, strong) UIImageView *fileImageView;
/// 背景气泡
@property (nonatomic, strong) UIView *bubbleView;
/// 手势视图
@property (nonatomic, strong) UIView *tapGestureView;

@end

@implementation PLVLCLandscapeFileCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.textView];
        [self.contentView addSubview:self.fileImageView];
        [self.contentView addSubview:self.tapGestureView];
    }
    return self;
}

- (void)layoutSubviews {
    if (self.cellWidth == 0) {
        return;
    }
    
    CGFloat xPadding = 12.0; // 气泡与textView的左右内间距
    CGFloat yPadding = 8.0; // textView文本与textView的内部有上下间距8
    CGFloat imageViewWidth = 32;
    CGFloat imageViewHeight = 38;
    
    CGFloat maxTextViewWidth = self.cellWidth - xPadding * 3 - imageViewWidth;
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(maxTextViewWidth, MAXFLOAT)];
    
    if (textViewSize.height < (imageViewHeight + 2 * yPadding)) {
        self.fileImageView.frame = CGRectMake(xPadding * 2 + textViewSize.width, yPadding, imageViewWidth, imageViewHeight);
        self.textView.frame = CGRectMake(xPadding, (imageViewHeight - textViewSize.height) / 2 + yPadding, textViewSize.width, textViewSize.height);
    } else {
        self.textView.frame = CGRectMake(xPadding, 0, textViewSize.width, textViewSize.height);
        self.fileImageView.frame = CGRectMake(xPadding * 2 + textViewSize.width, (textViewSize.height - imageViewHeight) / 2, imageViewWidth, imageViewHeight);
    }
    
    CGSize bubbleSize = CGSizeMake(textViewSize.width + imageViewWidth + xPadding + xPadding * 2, MAX(imageViewHeight + 2 * yPadding, textViewSize.height));
    self.bubbleView.frame = CGRectMake(0, 0, bubbleSize.width, bubbleSize.height);
    self.tapGestureView.frame = CGRectMake(0, 0, bubbleSize.width, bubbleSize.height);
}

#pragma mark - Getter

- (UIView *)bubbleView {
    if (!_bubbleView) {
        _bubbleView = [[UIView alloc] init];
        _bubbleView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _bubbleView.layer.cornerRadius = 14.0;
        _bubbleView.layer.masksToBounds = YES;
    }
    return _bubbleView;
}

- (PLVChatTextView *)textView {
    if (!_textView) {
        _textView = [[PLVChatTextView alloc] init];
        _textView.showMenu = YES;
        _textView.textContainer.maximumNumberOfLines = 3;
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
    if (![PLVLCLandscapeFileCell isModelValid:model] || cellWidth == 0) {
        self.cellWidth = 0;
        return;
    }
    
    self.cellWidth = cellWidth;
    
    if (loginUserId && [loginUserId isKindOfClass:[NSString class]] && loginUserId.length > 0) {
        self.loginUserId = loginUserId;
    }
    
    PLVFileMessage *message = (PLVFileMessage *)model.message;
    self.fileMessage = message;
    NSMutableAttributedString *contentLabelString = [PLVLCLandscapeFileCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:self.loginUserId];
    [self.textView setContent:contentLabelString showUrl:NO];
    UIImage *fileImageView = [PLVLCLandscapeFileCell imageWithMessage:model.message];
    [self.fileImageView setImage:fileImageView];
}

#pragma mark UI - ViewModel

/// 获取消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(PLVFileMessage *)message
                                                                  user:(PLVChatUser *)user
                                                           loginUserId:(NSString *)loginUserId {
    UIFont *font = [UIFont systemFontOfSize:14.0];
    NSString *nickNameColorHexString = [user isUserSpecial] ? @"#FFD36D" : @"#6DA7FF";
    UIColor *nickNameColor = [PLVColorUtil colorFromHexString:nickNameColorHexString];
    UIColor *contentColor = [UIColor whiteColor];
    
    NSDictionary *nickNameAttDict = @{NSFontAttributeName: font,
                                      NSForegroundColorAttributeName: nickNameColor};
    NSDictionary *contentAttDict = @{NSFontAttributeName: font,
                                     NSForegroundColorAttributeName:contentColor};
    
    NSString *content = user.userName;
    if (user.userId && [user.userId isKindOfClass:[NSString class]] &&
        loginUserId && [loginUserId isKindOfClass:[NSString class]] && [loginUserId isEqualToString:user.userId]) {
        content = [content stringByAppendingString:@"（我）"];
    }
    if (user.actor && [user.actor isKindOfClass:[NSString class]] && user.actor.length > 0) {
        content = [NSString stringWithFormat:@"%@-%@", user.actor, content];
    }
    content = [content stringByAppendingString:@"："];
    
    NSAttributedString *nickNameString = [[NSAttributedString alloc] initWithString:content attributes:nickNameAttDict];
    NSAttributedString *conentString = [[NSAttributedString alloc] initWithString:message.name attributes:contentAttDict];
    
    NSMutableAttributedString *contentLabelString = [[NSMutableAttributedString alloc] init];
    [contentLabelString appendAttributedString:nickNameString];
    [contentLabelString appendAttributedString:conentString];
    return contentLabelString;
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

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    if (![PLVLCLandscapeFileCell isModelValid:model] || cellWidth == 0) {
        return 0;
    }
    
    CGFloat xPadding = 12.0; // 气泡与textView的左右内间距
    CGFloat bubbleYPadding = 8.0; // 气泡与textView的上下内间距
    CGFloat imageViewWidth = 40;
    CGFloat imageViewHeight = 48;
    CGFloat maxTextViewWidth = cellWidth - imageViewWidth - xPadding * 3;
    
    PLVFileMessage *message = (PLVFileMessage *)model.message;
    NSMutableAttributedString *contentLabelString = [PLVLCLandscapeFileCell contentLabelAttributedStringWithMessage:message user:model.user loginUserId:loginUserId];
    
    PLVChatTextView *textView = [[PLVChatTextView alloc]init];
    textView.textContainer.maximumNumberOfLines = 3;
    textView.attributedText = contentLabelString;
    [textView setContent:contentLabelString showUrl:NO];
    CGSize contentLabelSize = [textView sizeThatFits:CGSizeMake(maxTextViewWidth, MAXFLOAT)];
    CGFloat bubbleHeight = MAX(contentLabelSize.height, imageViewHeight + bubbleYPadding * 2);
    
    return bubbleHeight + 5; // 气泡底部外间距为5
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
