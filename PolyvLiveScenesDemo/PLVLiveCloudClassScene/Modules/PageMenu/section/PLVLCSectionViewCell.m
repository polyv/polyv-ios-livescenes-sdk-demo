//
//  PLVLCSectionViewCell.m
//  PLVLiveScenesDemo
//
//  Created by Dhan on 2021/12/7.
//  Copyright © 2021 PLV. All rights reserved.
//

#import "PLVLCSectionViewCell.h"
#import "PLVRoomDataManager.h"
#import <PLVFoundationSDK/PLVFoundationSDK.h>
#import "PLVLCUtils.h"

@interface PLVLCSectionViewCell ()

@property (nonatomic, strong) UIView *line;

@end

@implementation PLVLCSectionViewCell

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    [self.line setBackgroundColor:PLV_UIColorFromRGB(@"#000000")];
}

- (void)setSection:(PLVLivePlaybackSectionModel *)section {
    _section = section;
    self.detailTextLabel.text = [PLVFdUtil secondsToString2:section.timeStamp] ;
    self.textLabel.text = section.title;
    self.detailTextLabel.textColor = PLV_UIColorFromRGB(@"#ADADC0");
    self.detailTextLabel.highlightedTextColor = PLV_UIColorFromRGB(@"#78A7ED");
    self.textLabel.textColor = PLV_UIColorFromRGB(@"#ADADC0");
    self.textLabel.highlightedTextColor = PLV_UIColorFromRGB(@"#78A7ED");
    [self.imageView setImage:[PLVLCUtils imageForMenuResource:@"plvlc_menu_section_play"]];
    self.imageView.highlightedImage = [PLVLCUtils imageForMenuResource:@"plvlc_menu_section_playing"];
    self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.frame];
    self.selectedBackgroundView.backgroundColor = self.backgroundColor;
}

@end
