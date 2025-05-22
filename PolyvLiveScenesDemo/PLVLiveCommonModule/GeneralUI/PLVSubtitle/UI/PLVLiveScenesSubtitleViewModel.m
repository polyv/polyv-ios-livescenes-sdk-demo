//
//  PLVLiveScenesSubtitleViewModel.m
//  PolyvLiveScenesDemo
//
//  Created by Dhan on 2025/04/24.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVLiveScenesSubtitleViewModel.h"

static const double PLVLiveScenesSubtitleAnimationDuration = 0.15;

@interface PLVLiveScenesSubtitleItemStyle ()

@end

@implementation PLVLiveScenesSubtitleItemStyle

+ (instancetype)styleWithTextColor:(UIColor *)textColor bold:(BOOL)bold italic:(BOOL)italic backgroundColor:(UIColor *)backgroundColor {
    return [self styleWithTextColor:textColor bold:bold italic:italic backgroundColor:backgroundColor fontSize:20.0f];
}

+ (instancetype)styleWithTextColor:(UIColor *)textColor bold:(BOOL)bold italic:(BOOL)italic backgroundColor:(UIColor *)backgroundColor fontSize:(CGFloat)fontSize {
    PLVLiveScenesSubtitleItemStyle *style = [[PLVLiveScenesSubtitleItemStyle alloc] init];
    style.textColor = textColor;
    style.bold = bold;
    style.italic = italic;
    style.backgroundColor = backgroundColor;
    style.fontSize = fontSize;
    return style;
}

@end

@interface PLVLiveScenesSubtitleViewModel ()

@end

@implementation PLVLiveScenesSubtitleViewModel

#pragma mark - dealloc & init


#pragma mark - property

- (void)setEnable:(BOOL)enable {
    _enable = enable;
    [self performSelectorOnMainThread:@selector(hideSubtitleWithAnimation) withObject:nil waitUntilDone:YES];
}

- (void)setSubtitleItem:(PLVLiveScenesSubtitleItem *)subtitleItem {
    BOOL same = subtitleItem == _subtitleItem;
    if (same) {
        return;
    }
    _subtitleItem = subtitleItem;

    [self subtitleItemDidChange:subtitleItem];
}

- (void)setSubtitleAtTopItem:(PLVLiveScenesSubtitleItem *)subtitleAtTopItem {
    BOOL same = subtitleAtTopItem == _subtitleAtTopItem;
    if (same) {
        return;
    }
    _subtitleAtTopItem = subtitleAtTopItem;
    
    [self subtitleItemAtTopDidChange:subtitleAtTopItem];
}

- (void)setSubtitleItem2:(PLVLiveScenesSubtitleItem *)subtitleItem2 {
    BOOL same = subtitleItem2 == _subtitleItem2;
    if (same) {
        return;
    }
    _subtitleItem2 = subtitleItem2;

    [self subtitleItem2DidChange:subtitleItem2];
}

- (void)setSubtitleAtTopItem2:(PLVLiveScenesSubtitleItem *)subtitleAtTopItem2 {
    BOOL same = subtitleAtTopItem2 == _subtitleAtTopItem2;
    if (same) {
        return;
    }
    _subtitleAtTopItem2 = subtitleAtTopItem2;
    
    [self subtitleItem2AtTopDidChange:subtitleAtTopItem2];
}

- (void)setSubtitleLabel:(UILabel *)subtitleLabel {
    [self setSubtitleLabel:subtitleLabel style:nil];
}

- (void)setSubtitleLabel:(UILabel *)subtitleLabel style:(PLVLiveScenesSubtitleItemStyle *)style {
    _subtitleLabel = subtitleLabel;
    _subtitleItemStyle = style;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupSubtitleLabel:subtitleLabel style:style];
    });
}

- (void)setSubtitleTopLabel:(UILabel *)subtitleTopLabel {
    [self setSubtitleTopLabel:subtitleTopLabel style:nil];
}

- (void)setSubtitleTopLabel:(UILabel *)subtitleTopLabel style:(PLVLiveScenesSubtitleItemStyle *)style {
    _subtitleTopLabel = subtitleTopLabel;
    _subtitleAtTopItemStyle = style;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupSubtitleTopLabel:subtitleTopLabel style:style];
    });
}

- (void)setSubtitleLabel2:(UILabel *)subtitleLabel2 {
    [self setSubtitleLabel2:subtitleLabel2 style:nil];
}

- (void)setSubtitleLabel2:(UILabel *)subtitleLabel2 style:(PLVLiveScenesSubtitleItemStyle *)style {
    _subtitleLabel2 = subtitleLabel2;
    _subtitleItemStyle2 = style;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupSubtitleLabel2:subtitleLabel2 style:style];
    });
}

- (void)setSubtitleTopLabel2:(UILabel *)subtitleTopLabel2 {
    [self setSubtitleTopLabel2:subtitleTopLabel2 style:nil];
}

- (void)setSubtitleTopLabel2:(UILabel *)subtitleTopLabel2 style:(PLVLiveScenesSubtitleItemStyle *)style {
    _subtitleTopLabel2 = subtitleTopLabel2;
    _subtitleAtTopItemStyle2 = style;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupSubtitleTopLabel2:subtitleTopLabel2 style:style];
    });
}

#pragma mark - private

- (void)hideSubtitleWithAnimation {
    [UIView animateWithDuration:PLVLiveScenesSubtitleAnimationDuration animations:^{
        self.subtitleLabel.alpha = self.enable ? 1.0 : 0;
        self.subtitleTopLabel.alpha = self.enable ? 1.0 : 0;
    }];
}

- (void)setupSubtitleLabel:(UILabel *)subtitleLabel style:(PLVLiveScenesSubtitleItemStyle *)style {
    subtitleLabel.text = @"";
    subtitleLabel.numberOfLines = 0;
    subtitleLabel.contentMode = UIViewContentModeBottom;
    subtitleLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
    subtitleLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
    subtitleLabel.shadowOffset = CGSizeMake(1, 1);
    subtitleLabel.backgroundColor = style.backgroundColor ? style.backgroundColor : [UIColor clearColor];
}

- (void)setupSubtitleTopLabel:(UILabel *)subtitleTopLabel style:(PLVLiveScenesSubtitleItemStyle *)style {
    subtitleTopLabel.text = @"";
    subtitleTopLabel.numberOfLines = 0;
    subtitleTopLabel.contentMode = UIViewContentModeBottom;
    subtitleTopLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
    subtitleTopLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
    subtitleTopLabel.shadowOffset = CGSizeMake(1, 1);
    subtitleTopLabel.backgroundColor = style.backgroundColor ? style.backgroundColor : [UIColor clearColor];
}

- (void)setupSubtitleLabel2:(UILabel *)subtitleLabel style:(PLVLiveScenesSubtitleItemStyle *)style {
    subtitleLabel.text = @"";
    subtitleLabel.numberOfLines = 0;
    subtitleLabel.contentMode = UIViewContentModeBottom;
    subtitleLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
    subtitleLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
    subtitleLabel.shadowOffset = CGSizeMake(1, 1);
    subtitleLabel.backgroundColor = style.backgroundColor ? style.backgroundColor : [UIColor clearColor];
}

- (void)setupSubtitleTopLabel2:(UILabel *)subtitleTopLabel style:(PLVLiveScenesSubtitleItemStyle *)style {
    subtitleTopLabel.text = @"";
    subtitleTopLabel.numberOfLines = 0;
    subtitleTopLabel.contentMode = UIViewContentModeBottom;
    subtitleTopLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
    subtitleTopLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
    subtitleTopLabel.shadowOffset = CGSizeMake(1, 1);
    subtitleTopLabel.backgroundColor = style.backgroundColor ? style.backgroundColor : [UIColor clearColor];
}

- (void)subtitleItemDidChange:(PLVLiveScenesSubtitleItem *)subtitleItem {
    //NSLog(@"%@", subtitleItem);
    [UIView transitionWithView:self.subtitleLabel duration:PLVLiveScenesSubtitleAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.subtitleLabel.attributedText = [self subtitleItem:subtitleItem style:self.subtitleItemStyle];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)subtitleItemAtTopDidChange:(PLVLiveScenesSubtitleItem *)subtitleItem {
    //NSLog(@"%@", subtitleItem);
    [UIView transitionWithView:self.subtitleTopLabel duration:PLVLiveScenesSubtitleAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.subtitleTopLabel.attributedText = [self subtitleItem:subtitleItem style:self.subtitleAtTopItemStyle];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)subtitleItem2DidChange:(PLVLiveScenesSubtitleItem *)subtitleItem {
    //NSLog(@"%@", subtitleItem);
    [UIView transitionWithView:self.subtitleLabel2 duration:PLVLiveScenesSubtitleAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.subtitleLabel2.attributedText = [self subtitleItem:subtitleItem style:self.subtitleItemStyle2];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)subtitleItem2AtTopDidChange:(PLVLiveScenesSubtitleItem *)subtitleItem {
    //NSLog(@"%@", subtitleItem);
    [UIView transitionWithView:self.subtitleTopLabel2 duration:PLVLiveScenesSubtitleAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.subtitleTopLabel2.attributedText = [self subtitleItem:subtitleItem style:self.subtitleAtTopItemStyle2];
    } completion:^(BOOL finished) {
        
    }];
}

- (NSAttributedString *)subtitleItem:(PLVLiveScenesSubtitleItem *)subtitleItem style:(PLVLiveScenesSubtitleItemStyle *)style {
    if (!subtitleItem.attributedText) {
        return nil;
    }
    
    if (!style || ![style isKindOfClass:[PLVLiveScenesSubtitleItemStyle class]]) {
        return subtitleItem.attributedText;
    }
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:subtitleItem.attributedText];
    
    // 调整颜色
    if (style.textColor) {
        [attributedString addAttribute:NSForegroundColorAttributeName value:style.textColor range:NSMakeRange(0, attributedString.length)];
    }
    
    // 调整字体粗细和大小
    CGFloat fontSize = style.fontSize > 0 ? style.fontSize : 20.0f;  // 默认字号为20
    if (style.bold) {
        [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"PingFangSC-SemiBold" size:fontSize] range:NSMakeRange(0, attributedString.length)];
    } else {
        [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"PingFangSC-Regular" size:fontSize] range:NSMakeRange(0, attributedString.length)];
    }
    
    // 调整字体倾斜
    if (style.italic) {
        [attributedString addAttribute:NSObliquenessAttributeName value:@(15 * M_PI / 180) range:NSMakeRange(0, attributedString.length)];
    }
    
    return [attributedString copy];
}

@end
