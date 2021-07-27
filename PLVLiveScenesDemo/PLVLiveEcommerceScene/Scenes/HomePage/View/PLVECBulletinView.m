//
//  PLVECBulletinView.m
//  PLVLiveEcommerceDemo
//
//  Created by ftao on 2020/5/21.
//  Copyright © 2020 PLV. All rights reserved.
//

#import "PLVECBulletinView.h"
#import "PLVECUtils.h"

@interface PLVECBulletinView ()

@property (nonatomic, strong) UIImageView *iconImgView;
@property (nonatomic, strong) UILabel *titleLB;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *contentLB;

@end

@implementation PLVECBulletinView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 12;
        self.layer.masksToBounds = YES;
        self.backgroundColor = [UIColor colorWithRed:1/255.f green:129/255.f blue:1 alpha:0.7f];
        
        self.iconImgView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 6, 12, 12)];
        self.iconImgView.image = [PLVECUtils imageForWatchResource:@"plv_bulletin_icon"];
        [self addSubview:self.iconImgView];
        
        self.titleLB = [[UILabel alloc] initWithFrame:CGRectMake(24, 6, 37, 12)];
        self.titleLB.text = @"公告：";
        self.titleLB.textColor = UIColor.whiteColor;
        self.titleLB.font = [UIFont systemFontOfSize:12];
        [self addSubview:self.titleLB];
        
        self.contentView = [[UIView alloc] init];
        self.contentView.clipsToBounds = YES;
        [self addSubview:self.contentView];
        
        self.contentLB = [[UILabel alloc] init];
        self.contentLB.textColor = UIColor.whiteColor;
        self.contentLB.font = [UIFont systemFontOfSize:12];
        self.contentLB.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:self.contentLB];
    }
    return self;
}

#pragma mark - Public

- (void)showBulletinView:(NSString *)content duration:(NSTimeInterval)duration {
    if (![content isKindOfClass:NSString.class]) {
        return;
    }
    if (duration < 2.0) {
        duration = 2.0;
    }
    
    self.contentLB.attributedText = [self htmlContentAttr:content];
    
    CGSize contentSize = [self.contentLB sizeThatFits:CGSizeMake(MAXFLOAT, 12)];
    CGFloat contentMaxWidth = CGRectGetWidth(self.bounds) - CGRectGetMaxX(self.titleLB.frame) - 15;
    
    self.contentView.frame = CGRectMake(CGRectGetMaxX(self.titleLB.frame), 0, CGRectGetWidth(self.bounds)-CGRectGetMaxX(self.titleLB.frame)-15, CGRectGetHeight(self.bounds));
    self.contentLB.frame = CGRectMake(0, 0, MAX(contentSize.width, contentMaxWidth), CGRectGetHeight(self.contentView.bounds));
    
    if (contentSize.width > contentMaxWidth) { // scroll
        duration = contentSize.width / CGRectGetWidth(self.contentView.bounds) * duration;
        [UIView animateWithDuration:duration animations:^{
            CGRect newFrame = self.contentLB.frame;
            newFrame.origin.x -= contentSize.width;;
            self.contentLB.frame = newFrame;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    } else {
        CGRect newFrame = self.frame;
        newFrame.size.width = CGRectGetMaxX(self.titleLB.frame) + contentSize.width + 15;
        self.frame = newFrame;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self removeFromSuperview];
        });
    }
}

#pragma mark - Private

- (NSAttributedString *)htmlContentAttr:(NSString *)content {
    NSString *style = @"<style> body { font-size: 12px; color: white; } p:last-of-type { margin: 0; }</style>";
    NSString *styledHtml = [NSString stringWithFormat:@"%@%@", style, content];
    NSError *err = nil;
    NSAttributedString *htmlContentAttr = [[NSAttributedString alloc] initWithData:[styledHtml dataUsingEncoding:NSUnicodeStringEncoding] options:@{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType} documentAttributes:nil error:&err];
    if (err) {
        NSLog(@"htmlContentAttr err:%@",err.localizedDescription);
    }
    return htmlContentAttr;
}

@end
