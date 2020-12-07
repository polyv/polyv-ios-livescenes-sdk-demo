//
//  PLVECRewardView.m
//  PolyvLiveScenesDemo
//
//  Created by ftao on 2020/6/28.
//  Copyright © 2020 polyv. All rights reserved.
//

#import "PLVECRewardView.h"
#import "PLVECUtils.h"

@implementation PLVECGiftItem

+ (instancetype)giftItemWithName:(NSString *)name imageName:(NSString *)imageName {
    PLVECGiftItem *item = [[self alloc] init];
    if (item) {
        item.name = name;
        item.imageName = imageName;
    }
    return item;
}

@end

@interface PLVECGiftButton : UIControl

@property (nonatomic, strong) UIImageView *iconImageView;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UILabel *tipLabel;

@end

@implementation PLVECGiftButton

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.iconImageView = [[UIImageView alloc] init];
        [self addSubview:self.iconImageView];
        
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.textColor = [UIColor colorWithWhite:208/255.0 alpha:1];
        self.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [self addSubview:self.titleLabel];
                
        self.tipLabel = [[UILabel alloc] init];
        self.tipLabel.backgroundColor = [UIColor colorWithRed:1.0 green:166/255.0 blue:17/255.0 alpha:1.0];
        self.tipLabel.textAlignment = NSTextAlignmentCenter;
        self.tipLabel.textColor = UIColor.whiteColor;
        self.tipLabel.font = [UIFont systemFontOfSize:14.0];
        self.tipLabel.text = @"打赏";
        [self addSubview:self.tipLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.layer.cornerRadius = 10.0;
    self.layer.masksToBounds = YES;
    
    self.iconImageView.frame = CGRectMake(CGRectGetWidth(self.bounds)/2-24, 8, 48, 48);
    if (self.isSelected) {
        self.backgroundColor = [UIColor colorWithRed:62/255.0 green:65/255.0 blue:78/255.0 alpha:1];
        self.titleLabel.frame = CGRectMake(0, CGRectGetMaxY(self.iconImageView.frame), CGRectGetWidth(self.bounds), 12);
        self.tipLabel.hidden = NO;
        self.tipLabel.frame = CGRectMake(0, CGRectGetHeight(self.bounds)-24, CGRectGetWidth(self.bounds), 24);
    } else {
        self.backgroundColor = UIColor.clearColor;
        self.titleLabel.frame = CGRectMake(0, CGRectGetMaxY(self.iconImageView.frame)+8, CGRectGetWidth(self.bounds), 12);
        self.tipLabel.hidden = YES;
    }
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];

    [self layoutSubviews];
}

@end

@interface PLVECRewardView ()

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) NSMutableArray<PLVECGiftItem *> *giftItems;

@property (nonatomic, assign) NSInteger selectedButtonTag;

@end

@implementation PLVECRewardView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 16, 50, 22)];
        self.titleLabel.text = @"礼物";
        self.titleLabel.textColor = UIColor.whiteColor;
        self.titleLabel.font = [UIFont systemFontOfSize:16];
        [self addSubview:self.titleLabel];
        
        self.giftItems = [[NSMutableArray alloc] init];
        [self addGiftItemWithName:@"鲜花" imageName:@"plv_gift_icon_flower"];
        [self addGiftItemWithName:@"咖啡" imageName:@"plv_gift_icon_coffee"];
        [self addGiftItemWithName:@"点赞" imageName:@"plv_gift_icon_likes"];
        [self addGiftItemWithName:@"掌声" imageName:@"plv_gift_icon_clap"];
        [self addGiftItemWithName:@"666" imageName:@"plv_gift_icon_666"];
        [self addGiftItemWithName:@"小星星" imageName:@"plv_gift_icon_starlet"];
        [self addGiftItemWithName:@"钻石" imageName:@"plv_gift_icon_diamond"];
        [self addGiftItemWithName:@"跑车" imageName:@"plv_gift_icon_sportscar"];
        [self addGiftItemWithName:@"火箭" imageName:@"plv_gift_icon_rocket"];
        
        int maxColumn = 5;
        int btnWidth = 72, btnHeight = 98;
        CGFloat leftMargin = (CGRectGetWidth(frame) - btnWidth * maxColumn) / 2;
        for (int i=0; i<self.giftItems.count; i++) {
            int row = i / maxColumn;
            int column = i % maxColumn;
            
            PLVECGiftItem *item = self.giftItems[i];
            
            PLVECGiftButton *button = [[PLVECGiftButton alloc] init];
            button.tag = 100 + i;
            button.frame = CGRectMake(leftMargin + column * btnWidth, 54 + row * btnHeight, btnWidth, btnHeight);
            button.titleLabel.text = item.name;
            button.iconImageView.image = [PLVECUtils imageForWatchResource:item.imageName];
            [button addTarget:self action:@selector(itemButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:button];
        }
    }
    return self;
}

#pragma mark - Private

- (void)addGiftItemWithName:(NSString *)name imageName:(NSString *)imageName {
    PLVECGiftItem *item = [PLVECGiftItem giftItemWithName:name imageName:imageName];
    if (self.giftItems && item) {
        [self.giftItems addObject:item];
    }
}

- (void)itemButtonAction:(PLVECGiftButton *)button {
    if (button.isSelected) {
        button.selected = NO;
        self.selectedButtonTag = 0;
        if ([self.delegate respondsToSelector:@selector(rewardView:didSelectItem:)]) {
            [self.delegate rewardView:self didSelectItem:self.giftItems[button.tag-100]];
        }
    } else {
        button.selected = YES;
        if (button.tag != self.selectedButtonTag) {
            PLVECGiftButton *lastSelectedButton = [self viewWithTag:self.selectedButtonTag];
            if ([lastSelectedButton isKindOfClass:PLVECGiftButton.class]) {
                lastSelectedButton.selected = NO;
            }
        }
        self.selectedButtonTag = button.tag;
    }
}

@end
