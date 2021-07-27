//
//  PLVLCLandscapeNewMessageView.m
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/11/6.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVLCLandscapeNewMessageView.h"
#import "PLVLCUtils.h"
#import <PLVFoundationSDK/PLVColorUtil.h>

@interface PLVLCLandscapeNewMessageView ()

@property (nonatomic, assign) NSUInteger messageCount;

@property (nonatomic, strong) UILabel *label;

@end

@implementation PLVLCLandscapeNewMessageView

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 12.5;
        self.layer.masksToBounds = YES;
        
        [self addSubview:self.label];
    }
    return self;
}

- (void)layoutSubviews {
    self.label.frame = self.bounds;
}

#pragma mark - Getter & Setter

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] init];
        _label.textColor = [PLVColorUtil colorFromHexString:@"#FF786D"];
        _label.font = [UIFont systemFontOfSize:12];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.attributedText = [self labelText];
    }
    return _label;
}

#pragma mark - Public

- (void)updateMeesageCount:(NSUInteger)count {
    self.messageCount = count;
    // 调整文本内容
    NSAttributedString *attributedString = [self labelText];
    self.label.attributedText = attributedString;
    // 根据文字宽度调整大小
    CGSize stringSize = [attributedString boundingRectWithSize:CGSizeMake(100, 25) options:0 context:nil].size;
    CGRect rect = self.frame;
    rect.size.width = stringSize.width + 8 * 2;
    self.frame = rect;
}

- (void)show {
    if (self.hidden == NO) {
        return;
    }
    self.hidden = NO;
}

- (void)hidden {
    if (self.hidden) {
        return;
    }
    self.hidden = YES;
    [self updateMeesageCount:0];
}

#pragma mark - Private

- (NSAttributedString *)labelText {
    NSMutableAttributedString *muString = [[NSMutableAttributedString alloc] init];
    
    NSString *string = [NSString stringWithFormat:@"%zd条新消息 ", self.messageCount];
    if (self.messageCount > 999) {
        string = @"999+条新消息 ";
    }
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string];
    
    UIImage *image = [PLVLCUtils imageForChatroomResource:@"plvlc_chatroom_arrow_icon"];
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    [attachment setImage:image];
    attachment.bounds = CGRectMake(0, -2, image.size.width, image.size.height);
    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
    
    [muString appendAttributedString:attributedString];
    [muString appendAttributedString:attachmentString];
    return [muString copy];
}


@end
