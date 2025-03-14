//
//  PLVLCMediaPipSet.m
//  PolyvLiveScenesDemo
//
//  Created by polyv on 2025/3/3.
//  Copyright © 2025 PLV. All rights reserved.
//

#import "PLVLCMediaPipSet.h"
#import <PLVFoundationSDK/PLVColorUtil.h>
#import "PLVMultiLanguageManager.h"

@interface PLVLCMediaPipSet ()

@property (nonatomic, strong) UILabel *lblTitle;
@property (nonatomic, strong) UIView *line;

@property (nonatomic, strong) UILabel *lblExitRoom;
@property (nonatomic, strong) UISwitch *swiExitRoom;

@property (nonatomic, strong) UILabel *lblEnterBack;
@property (nonatomic, strong) UISwitch *swiEnterBack;

@end

@implementation PLVLCMediaPipSet

#pragma mark -- lifecycle

- (void)layoutSubviews{
    [super layoutSubviews];
    
    [self updateUI];
}

- (instancetype)initWithSheetHeight:(CGFloat)sheetHeight{
    if (self = [super initWithSheetHeight:sheetHeight]){
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    
    [self.contentView addSubview:self.lblTitle];
    [self.contentView addSubview:self.line];
    
    [self.contentView addSubview:self.lblExitRoom];
    [self.contentView addSubview:self.swiExitRoom];
    
    [self.contentView addSubview:self.lblEnterBack];
    [self.contentView addSubview:self.swiEnterBack];
}

- (void)updateUI{
    
    CGFloat start_x = 24;
    CGFloat start_y = 18;
    self.lblTitle.frame = CGRectMake(start_x, start_y, self.bounds.size.width - 2*start_x, 20);
    start_y = CGRectGetMaxY(self.lblTitle.frame) + 15;
    self.line.frame = CGRectMake(0, start_y, self.bounds.size.width, 1);
    
    CGSize switchSize = CGSizeMake(38, 24);
    start_y = CGRectGetMaxY(self.lblTitle.frame) + 35;
    CGFloat width = self.bounds.size.width - 24*2 - switchSize.width - 5;
    self.lblExitRoom.frame = CGRectMake(start_x, start_y, width, 30);
    
    start_x = self.bounds.size.width - 24 - switchSize.width;
    self.swiExitRoom.frame = CGRectMake(start_x, start_y, switchSize.width, switchSize.height);
    
    start_y = CGRectGetMaxY(self.lblExitRoom.frame) + 35;
    start_x = 24;
    width = self.bounds.size.width - 24*2 - switchSize.width - 5;
    self.lblEnterBack.frame = CGRectMake(start_x, start_y, width, 30);
    
    start_x = self.bounds.size.width - 24 - switchSize.width;
    self.swiEnterBack.frame = CGRectMake(start_x, start_y, switchSize.width, switchSize.height);
    
}

#pragma mark -- Getter
- (UILabel *)lblTitle{
    if (!_lblTitle){
        _lblTitle = [[UILabel alloc] init];
        _lblTitle.text = PLVLocalizedString(@"播放设置");
        _lblTitle.textColor = [PLVColorUtil colorFromHexString:@"#333333"];
        _lblTitle.textAlignment = NSTextAlignmentCenter;
        _lblTitle.font = [UIFont systemFontOfSize:16];
    }
    return _lblTitle;
}

- (UIView *)line{
    if (!_line){
        _line = [[UIView alloc] init];
        _line.backgroundColor =[PLVColorUtil colorFromHexString:@"#F2F2F2"];
    }
    
    return _line;
}

- (UILabel *)lblExitRoom{
    if (!_lblExitRoom){
        _lblExitRoom = [[UILabel alloc] init];
        _lblExitRoom.text = PLVLocalizedString(@"退出直播间自动启用小窗");
        _lblExitRoom.textColor = [PLVColorUtil colorFromHexString:@"#333333"];
        _lblExitRoom.font = [UIFont systemFontOfSize:16];

    }
    
    return _lblExitRoom;
}


- (UISwitch *)swiExitRoom{
    if (!_swiExitRoom){
        _swiExitRoom = [[UISwitch alloc] init];
        _swiExitRoom.onTintColor = [PLVColorUtil colorFromHexString:@"#3F76FC"];
        [_swiExitRoom addTarget:self action:@selector(exitRoomClick:) forControlEvents:UIControlEventValueChanged];
    }
    
    return _swiExitRoom;
}

- (UILabel *)lblEnterBack{
    if (!_lblEnterBack){
        _lblEnterBack = [[UILabel alloc] init];
        _lblEnterBack.text =  PLVLocalizedString(@"退至应用后台自动启用小窗");
        _lblEnterBack.textColor = [PLVColorUtil colorFromHexString:@"#333333"];
        _lblEnterBack.font = [UIFont systemFontOfSize:16];

    }
    
    return _lblEnterBack;
}

- (UISwitch *)swiEnterBack{
    if (!_swiEnterBack){
        _swiEnterBack = [[UISwitch alloc] init];
        _swiEnterBack.onTintColor = [PLVColorUtil colorFromHexString:@"#3F76FC"];
        [_swiEnterBack addTarget:self action:@selector(enterBackClick:) forControlEvents:UIControlEventValueChanged];
    }
    
    return _swiEnterBack;
}

#pragma mark UISwitch Action
- (void)enterBackClick:(UISwitch *)enterBack{
    if (self.enterBackSwitchChanged){
        self.enterBackSwitchChanged(self.swiEnterBack.on);
    }
}

- (void)exitRoomClick:(UISwitch *)exitRoom{
    if (self.exitRoomSwitchChanged){
        self.exitRoomSwitchChanged(self.swiExitRoom.on);
    }
    
    self.lblEnterBack.hidden = !exitRoom.on;
    self.swiEnterBack.hidden = !exitRoom.on;
}

#pragma mark -- PUBLIC
- (void)setExitRoomState:(BOOL)exitRoomState{
    [self.swiExitRoom setOn:exitRoomState];

    self.lblEnterBack.hidden = !exitRoomState;
    self.swiEnterBack.hidden = !exitRoomState;
}

- (void)setEnterBackState:(BOOL)enterBackState{
    [self.swiEnterBack setOn:enterBackState];
}

@end
