//
//  PLVLSEmojiSelectView.m
//  PLVLiveStreamerDemo
//
//  Created by ftao on 2019/11/13.
//  Copyright © 2019 PLV. All rights reserved.
//

#import "PLVLSEmojiSelectView.h"
#import "PLVEmoticonManager.h"
#import "PLVLSUtils.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>

@interface PLVLSEmojiSelectView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *sendButton;

@property (nonatomic, assign) BOOL layoutEmoticonButton;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation PLVLSEmojiSelectView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [PLVColorUtil colorFromHexString:@"#2B2C35"];
        self.layoutEmoticonButton = NO;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.pagingEnabled = YES;
    [self addSubview:self.scrollView];
    
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.deleteButton.backgroundColor = PLV_UIColorFromRGB(@"#3E3E4E");
    UIImage *deleteImage = [PLVLSUtils imageForChatroomResource:@"plvls_emoji_delete_btn"];
    [self.deleteButton setImage:deleteImage forState:UIControlStateNormal];
    [self.deleteButton addTarget:self action:@selector(deleteButtonTouchBegin)forControlEvents:UIControlEventTouchDown];
    [self.deleteButton addTarget:self action:@selector(deleteButtonTouchEnd)forControlEvents:UIControlEventTouchUpInside];
    [self.deleteButton addTarget:self action:@selector(deleteButtonTouchEnd)forControlEvents:UIControlEventTouchUpOutside];
    self.deleteButton.layer.cornerRadius = 4.0;
    [self addSubview:self.deleteButton];
    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendButton.backgroundColor = PLV_UIColorFromRGB(@"#3E3E4E");
    [self.sendButton setTitle:@"发送" forState:UIControlStateNormal];
    self.sendButton.titleLabel.font = [UIFont  systemFontOfSize:14.0];
    [self.sendButton addTarget:self action:@selector(sendButtonButtonAction) forControlEvents:UIControlEventTouchUpInside];
    self.sendButton.layer.cornerRadius = 4.0;
    [self addSubview:self.sendButton];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat buttonWidth = 48.0;
    CGFloat sidePadding = PLVLSUtils.safeSidePad + 40;
    CGFloat bottomSide = PLVLSUtils.safeBottomPad;
    
    self.deleteButton.frame = CGRectMake(CGRectGetWidth(self.bounds)-sidePadding-buttonWidth, 17.0, buttonWidth, buttonWidth);
    self.sendButton.frame = CGRectMake(CGRectGetMinX(self.deleteButton.frame), CGRectGetMaxY(self.deleteButton.frame)+8.0, buttonWidth, 112.0);
    
    self.scrollView.frame = CGRectMake(sidePadding, 0, CGRectGetMinX(self.deleteButton.frame)- sidePadding - 10, CGRectGetHeight(self.bounds) - bottomSide);
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.bounds) * 3, CGRectGetHeight(self.scrollView.bounds));
    
    if (!self.layoutEmoticonButton) {
        self.layoutEmoticonButton = YES;
        [self layoutEmoticonButtons];
    }
}

- (void)layoutEmoticonButtons {
    int maxRow = 4;
    int maxCol = 12;
    CGFloat itemWidth = CGRectGetWidth(self.scrollView.bounds) / maxCol;
    CGFloat itemHeight = CGRectGetHeight(self.scrollView.bounds) / maxRow;
    
    NSArray *models = [PLVEmoticonManager sharedManager].models;
    for (int index = 0, row = 0; index < models.count; row++) {
        int page = row / maxRow;
        CGFloat addtionWidth = page * CGRectGetWidth(self.scrollView.bounds);
        int decreaseRow = page * maxRow;
        for (int col = 0; col < maxCol; col++, index ++) {
            if (index < models.count) {
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                [self.scrollView addSubview:button];
                [button setBackgroundColor:[UIColor clearColor]];
                [button setFrame:CGRectMake(col * itemWidth + addtionWidth, (row-decreaseRow) * itemHeight, itemWidth, itemHeight)];
                button.tag = index;
                [button addTarget:self action:@selector(emoticonButtonAction:) forControlEvents:UIControlEventTouchUpInside];
                
                PLVEmoticon *emoticon = [models objectAtIndex:index];
                UIImage *emoticonImage = [[PLVEmoticonManager sharedManager] imageForEmoticonName:emoticon.imageName];
                [button setImage:emoticonImage forState:UIControlStateNormal];
            } else {
                break;
            }
        }
    }
}

#pragma mark - Actions

- (void)deleteButtonTouchBegin {
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(deleteAction) userInfo:nil repeats:YES];
        [self.timer fire];
    }
}

- (void)deleteButtonTouchEnd {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)sendButtonButtonAction {
    if ([self.delegate respondsToSelector:@selector(emojiSelectView_didReceiveEvent:)]) {
        [self.delegate emojiSelectView_didReceiveEvent:PLVLSEmojiSelectViewEventSend];
    }
}

- (void)emoticonButtonAction:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(emojiSelectView_didSelectEmoticon:)]) {
        NSArray *models = [PLVEmoticonManager sharedManager].models;
        [self.delegate emojiSelectView_didSelectEmoticon:models[button.tag]];
    }
}

#pragma mark - Public

- (void)sendButtonEnable:(BOOL)enable {
    self.sendButton.enabled = enable;
}

#pragma mark - Private

- (void)deleteAction {
    if ([self.delegate respondsToSelector:@selector(emojiSelectView_didReceiveEvent:)]) {
        [self.delegate emojiSelectView_didReceiveEvent:PLVLSEmojiSelectViewEventDelete];
    }
}

@end
