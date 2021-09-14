//
//  PLVLCSpeakMessageCell.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/12/1.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCSpeakMessageCell.h"
#import "PLVChatTextView.h"
#import "PLVEmoticonManager.h"
#import <PLVLiveScenesSDK/PLVSpeakMessage.h>
#import <PLVFoundationSDK/PLVColorUtil.h>

@interface PLVLCSpeakMessageCell ()

@property (nonatomic, strong) PLVChatTextView *textView; /// 消息文本内容视图
@property (nonatomic, strong) UIView *bubbleView; /// 背景气泡

@end

@implementation PLVLCSpeakMessageCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self.contentView addSubview:self.bubbleView];
        [self.contentView addSubview:self.textView];
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
    
    CGFloat xPadding = 16.0; // 头像左间距，气泡右间距
    CGFloat bubbleXPadding = 12;//textView与bubble的内部左右间距均为12
    
    CGFloat maxTextViewWidth = self.cellWidth - originX - xPadding - bubbleXPadding * 2;
    CGSize textViewSize = [self.textView sizeThatFits:CGSizeMake(maxTextViewWidth, MAXFLOAT)];
    self.textView.frame = CGRectMake(originX + bubbleXPadding, originY, textViewSize.width, textViewSize.height);
    
    // textView文本与textView的内部已有上下间距8，所以气泡与textView实际上等高
    // 但textView文本与textView的内部不存在左右间距，所以气泡与textView不等宽
    CGSize bubbleSize = CGSizeMake(textViewSize.width + bubbleXPadding * 2, textViewSize.height);
    self.bubbleView.frame = CGRectMake(originX, originY, bubbleSize.width, bubbleSize.height);
    
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
        _textView.showMenu = YES;
    }
    return _textView;
}

#pragma mark - UI

- (void)updateWithModel:(PLVChatModel *)model loginUserId:(NSString *)loginUserId cellWidth:(CGFloat)cellWidth {
    [super updateWithModel:model loginUserId:loginUserId cellWidth:cellWidth];
    
    if (self.cellWidth == 0 || ![PLVLCSpeakMessageCell isModelValid:model]) {
        self.cellWidth = 0;
        return;
    }
    
    NSMutableAttributedString *contentLabelString = [PLVLCSpeakMessageCell contentLabelAttributedStringWithMessage:model.message
                                                                                                              user:model.user];
    [self.textView setContent:contentLabelString showUrl:[model.user isUserSpecial]];
}

#pragma mark UI - ViewModel

/// 获取消息多属性文本
+ (NSMutableAttributedString *)contentLabelAttributedStringWithMessage:(id)message user:(PLVChatUser *)user {
    NSString *content = @"";
    if ([message isKindOfClass:[PLVSpeakMessage class]]) {
        PLVSpeakMessage *speakMessage = (PLVSpeakMessage *)message;
        content = speakMessage.content;
    } else {
        content = (NSString *)message;
    }
    
    NSString *colorHexString = [user isUserSpecial] ? @"#78A7ED" : @"#ADADC0";
    NSDictionary *attributeDict = @{
                                    NSFontAttributeName: [UIFont systemFontOfSize:16.0],
                                    NSForegroundColorAttributeName:[PLVColorUtil colorFromHexString:colorHexString]
    };
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:content attributes:attributeDict];
    //云课堂小表情显示需要变大 用font 22；
    NSMutableAttributedString *emojiAttributedString = [[PLVEmoticonManager sharedManager] converEmoticonTextToEmotionFormatText:attributedString font:[UIFont systemFontOfSize:22.0]];
    return emojiAttributedString;
}

#pragma mark - 高度计算

+ (CGFloat)cellHeightWithModel:(PLVChatModel *)model cellWidth:(CGFloat)cellWidth {
    CGFloat cellHeight = [super cellHeightWithModel:model cellWidth:cellWidth];
    if (cellHeight == 0 || ![PLVLCSpeakMessageCell isModelValid:model]) {
        return 0;
    }
    
    CGFloat originX = 64.0; // 64 为气泡初始x值
    CGFloat originY = 28.0; // 64 为气泡初始y值
    CGFloat xPadding = 16.0; // 头像左间距，气泡右间距
    CGFloat bubbleXPadding = 12;//textView与bubble的内部左右间距均为12
    CGFloat maxTextViewWidth = cellWidth - originX - xPadding - bubbleXPadding * 2;
    
    NSMutableAttributedString *contentLabelString = [PLVLCSpeakMessageCell contentLabelAttributedStringWithMessage:model.message
                                                                                                              user:model.user];
    CGSize contentLabelSize = [[contentLabelString copy] boundingRectWithSize:CGSizeMake(maxTextViewWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    CGFloat textViewHeight = 8 + contentLabelSize.height + 8; // textView文本与textView的内部有上下间距8
    
    return originY + textViewHeight + 16; // 16为气泡底部外间距
}

#pragma mark - Utils

+ (BOOL)isModelValid:(PLVChatModel *)model {
    if (!model || ![model isKindOfClass:[PLVChatModel class]]) {
        return NO;
    }
    
    id message = model.message;
    if (!message ||
        (![message isKindOfClass:[PLVSpeakMessage class]] && // 文本消息
         ![message isKindOfClass:[NSString class]])) {       // 私聊消息
        return NO;
    }
    
    return YES;
}

@end
