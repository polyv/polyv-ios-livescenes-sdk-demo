//
//  PLVEmojiSelectView.m
//  PolyvLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/27.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVEmojiSelectView.h"
#import "PLVEmoticonManager.h"
#import "PLVKeyboardUtils.h"

static NSInteger kEmojiMaxRow = 5;
static NSInteger kEmojiMaxColumn = 6;

@interface PLVEmojiSelectView ()
// 是否已经加载 emoji 图片，默认 NO
@property (nonatomic, assign) BOOL loadEmoji;

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) UIButton *deleteButton;

@property (nonatomic, strong) UIButton *sendButton;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) NSArray *faces;

@property (nonatomic, assign) CGFloat itemWidth;
@property (nonatomic, assign) CGFloat itemHeight;

@end

@implementation PLVEmojiSelectView

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0x2B/ 255.0 green:0x2C/ 255.0 blue:0x35/ 255.0 alpha:1.0];
        
        self.faces = [PLVEmoticonManager sharedManager].models;
        
        [self addSubview:self.contentView];
        [self.contentView addSubview:self.scrollView];
        [self.contentView addSubview:self.deleteButton];
        [self.contentView addSubview:self.sendButton];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.contentView.frame = CGRectMake(5, 5, self.bounds.size.width - 10, 190);
    CGSize scrollViewSize = CGSizeMake(self.contentView.frame.size.width * 6 / 7, self.contentView.frame.size.height);
    self.scrollView.frame = CGRectMake(0, 0, scrollViewSize.width, scrollViewSize.height);
    self.scrollView.contentSize = CGSizeMake(scrollViewSize.width * 4, scrollViewSize.height);
    
    self.itemWidth = scrollViewSize.width / kEmojiMaxColumn;
    self.itemHeight = scrollViewSize.height / kEmojiMaxRow;
    self.deleteButton.frame = CGRectMake(CGRectGetMaxX(self.scrollView.frame), 5, self.itemWidth - 5, self.itemHeight - 5);
    self.sendButton.frame = CGRectMake(CGRectGetMaxX(self.scrollView.frame), CGRectGetMaxY(self.deleteButton.frame) + 10, self.itemWidth - 5, self.itemHeight * 4 - 15);
    
    [self loadEmojiInScrollView];
}

#pragma mark - Getter & Setter

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
    }
    return _contentView;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.pagingEnabled = YES;
    }
    return _scrollView;
}

- (UIButton *)deleteButton {
    if (!_deleteButton) {
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _deleteButton.layer.cornerRadius = 5.0;
        _deleteButton.backgroundColor = [UIColor colorWithRed:0x3E/255.0 green:0x3E/255.0 blue:0x4E/255.0 alpha:1.0];
        [_deleteButton setImage:[PLVKeyboardUtils imageForKeyboardResource:@"plv_keyboard_btn_delete"] forState:UIControlStateNormal];
        [_deleteButton addTarget:self action:@selector(deleteButtonTouchBegin:)forControlEvents:UIControlEventTouchDown];
        [_deleteButton addTarget:self action:@selector(deleteButtonTouchEnd:)forControlEvents:UIControlEventTouchUpInside];
        [_deleteButton addTarget:self action:@selector(deleteButtonTouchEnd:)forControlEvents:UIControlEventTouchUpOutside];
    }
    return _deleteButton;
}

- (UIButton *)sendButton {
    if (!_sendButton) {
        _sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _sendButton.layer.cornerRadius = 5.0;
        _sendButton.layer.masksToBounds = YES;
        _sendButton.enabled = NO;
        [_sendButton setTitle:@"发送" forState:UIControlStateNormal];
        [_sendButton addTarget:self action:@selector(sendAction:) forControlEvents:UIControlEventTouchUpInside];
        
        UIImage *bgImage = [self createImageWithColor:[UIColor colorWithRed:0x3E/255.0 green:0x3E/255.0 blue:0x4E/255.0 alpha:1.0]];
        [_sendButton setBackgroundImage:bgImage forState:UIControlStateNormal];
        [_sendButton setBackgroundImage:bgImage forState:UIControlStateDisabled];
        [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
    }
    return _sendButton;
}

#pragma mark - Initialize

-(void)loadEmojiInScrollView {
    if (self.loadEmoji) {
        return;
    }
    self.loadEmoji = YES;
    
    for (int index = 0, row = 0; index < [self.faces count]; row++) {
        int page = row / kEmojiMaxRow;
        CGFloat addtionWidth = page * CGRectGetWidth(self.scrollView.bounds);
        NSInteger decreaseRow = page * kEmojiMaxRow;
        for (int col = 0; col < kEmojiMaxColumn; col++, index++) {
            if (index < [self.faces count]) {
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.showsTouchWhenHighlighted = YES;
                button.tag = index;
                PLVEmoticon *emojiModel = [_faces objectAtIndex:index];
                [button setImage:[[PLVEmoticonManager sharedManager] imageForEmoticonName:emojiModel.imageName] forState:UIControlStateNormal];
                [button setFrame:CGRectMake(col * self.itemWidth + addtionWidth, (row-decreaseRow) * self.itemHeight, self.itemWidth, self.itemHeight)];
                [button addTarget:self action:@selector(selected:) forControlEvents:UIControlEventTouchUpInside];
                [self.scrollView addSubview:button];
            } else {
                break;
            }
        }
    }
}

#pragma mark - Public Method

- (void)sendButtonEnable:(BOOL)enable {
    self.sendButton.enabled = enable;
}

#pragma mark - Private Method

- (UIImage *)createImageWithColor:(UIColor *)color {
    CGSize size = CGSizeMake(1.0, 1.0);
    UIGraphicsBeginImageContext(size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    CGContextFillRect(context, rect);
    
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return theImage;
}

#pragma mark - Action

- (void)deleteButtonTouchBegin:(id)sender {
    [self startTimer];
}

- (void)deleteButtonTouchEnd:(id)sender {
    [self stopTimer];
}

- (void)sendAction:(id)sender {
    if (self.delegate) {// && [self.delegate respondsToSelector:@selector(sendEmoji)]) {
        [self.delegate sendEmoji];
    }
}

-(void)selected:(id)sender {
    UIButton *button = (UIButton *)sender;
    if (self.delegate) {// && [self.delegate respondsToSelector:@selector(selectEmoji:)]) {
        [self.delegate selectEmoji:[_faces objectAtIndex:button.tag]];
    }
}

#pragma mark - Timer

- (void)startTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
    [self.timer fire];
}

- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)timerAction {
    if (self.delegate) {// && [self.delegate respondsToSelector:@selector(deleteEmoji)]) {
        [self.delegate deleteEmoji];
    }
}

@end
