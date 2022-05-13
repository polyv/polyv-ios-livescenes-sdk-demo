//
//  PLVLSNewRemindMessageView.m
//  PolyvLiveScenesDemo
//
//  Created by lijingtong on 2022/2/15.
//  Copyright © 2022 PLV. All rights reserved.
//

#import "PLVLSNewRemindMessageView.h"
#import "PLVLSUtils.h"

@interface PLVLSNewRemindMessageView ()

@property (nonatomic, assign) NSUInteger messageCount;

@property (nonatomic, strong) UILabel *label;

@end

@implementation PLVLSNewRemindMessageView

#pragma mark - [ Life Cycle ]
- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 14;
        self.layer.masksToBounds = YES;
        
        [self addSubview:self.label];
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
        [self addGestureRecognizer:gesture];
    }
    return self;
}

- (void)layoutSubviews {
    self.label.frame = self.bounds;
}

#pragma mark - [ Public Method ]
- (void)updateMessageCount:(NSUInteger)count {
    self.messageCount = count;
    // 调整文本内容
    NSAttributedString *attributedString = [self labelTextWithScroll:NO];
    self.label.attributedText = attributedString;
    // 根据文字宽度调整大小
    CGSize stringSize = [attributedString boundingRectWithSize:CGSizeMake(100, 25) options:0 context:nil].size;
    CGRect rect = self.frame;
    rect.size.width = stringSize.width + 8 * 2;
    self.frame = rect;
    
    self.hidden = (count <= 0);
}

- (void)updateScrollMessage {
    // 调整文本内容
    NSAttributedString *attributedString = [self labelTextWithScroll:YES];
    self.label.attributedText = attributedString;
    // 根据文字宽度调整大小
    CGSize stringSize = [attributedString boundingRectWithSize:CGSizeMake(100, 25) options:0 context:nil].size;
    CGRect rect = self.frame;
    rect.size.width = stringSize.width + 8 * 2;
    self.frame = rect;
    self.hidden = NO;
}

#pragma mark - [ Private Method ]
#pragma mark Getter
- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.textColor = [UIColor colorWithRed:0x43/255.0 green:0x99/255.0 blue:0xff/255.0 alpha:1];
        _label.font = [UIFont systemFontOfSize:12];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.attributedText = [self labelTextWithScroll:NO];
    }
    return _label;
}

- (NSAttributedString *)labelTextWithScroll:(BOOL)scroll {
    NSMutableAttributedString *muString = [[NSMutableAttributedString alloc] init];
    
    NSString *string = nil;
    if (scroll) {
        string = @"返回底部";
    } else {
        string = [NSString stringWithFormat:@"%zd条新消息 ", self.messageCount];
        if (self.messageCount > 999) {
            string = @"999+条新消息 ";
        }
    }
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string];
    
    UIImage *image = [PLVLSUtils imageForChatroomResource:@"plvls_chatroom_newremindmsg_arrow"];
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    [attachment setImage:image];
    attachment.bounds = CGRectMake(0, -2, image.size.width, image.size.height);
    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
    
    [muString appendAttributedString:attributedString];
    [muString appendAttributedString:attachmentString];
    return [muString copy];
}

#pragma mark - [ Event ]
#pragma mark Action
- (void)tapAction {
    [self updateMessageCount:0];
    if (self.didTapNewMessageView) {
        self.didTapNewMessageView();
    }
}

@end
