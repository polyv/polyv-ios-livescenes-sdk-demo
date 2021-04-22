//
//  PLVPhotoCollectionFooterView.m
//  zPic
//
//  Created by zykhbl on 2017/7/11.
//  Copyright © 2017年 zykhbl. All rights reserved.
//

#import "PLVPhotoCollectionFooterView.h"
#import "PLVAlbumTool.h"
#import "PLVPicDefine.h"

@implementation PLVPhotoCollectionFooterView

@synthesize label;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.backgroundColor = BgClearColor;
        
        self.label = [PLVAlbumTool createUILabel:CGRectZero fontOfSize:15.0 textColor:LightGrayColor backgroundColor:BgClearColor textAlignment:NSTextAlignmentCenter inView:self];
    }
    
    return self;
}

@end
