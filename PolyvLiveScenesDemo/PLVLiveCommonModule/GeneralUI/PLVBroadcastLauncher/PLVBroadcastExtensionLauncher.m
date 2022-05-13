//
//  PLVBroadcastExtensionLauncher.m
//  PLVLiveScenesDemo
//
//  Created by Sakya on 2022/2/11.
//  Copyright © 2022 PLV. All rights reserved.
//

#import <ReplayKit/ReplayKit.h>
#import "PLVBroadcastExtensionLauncher.h"

API_AVAILABLE(ios(12.0))
@interface PLVBroadcastExtensionLauncher()

@property (nonatomic, strong) RPSystemBroadcastPickerView *systemBroadcastExtensionPicker;

@end

@implementation PLVBroadcastExtensionLauncher

#pragma mark - [ Public Method ]

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static PLVBroadcastExtensionLauncher *launch = nil;
    dispatch_once(&onceToken, ^{
        launch = [[self alloc] init];
    });
    return launch;
}

- (void)launch API_AVAILABLE(ios(12.0)) {
    if (!_systemBroadcastExtensionPicker) {
        return;
    }
    
    for (UIView *view in _systemBroadcastExtensionPicker.subviews) {
        UIButton *button = (UIButton *)view;
        [button sendActionsForControlEvents:UIControlEventAllTouchEvents];
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        if (@available(iOS 12.0, *)) {
            RPSystemBroadcastPickerView* picker =
            [[RPSystemBroadcastPickerView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
            picker.showsMicrophoneButton = false;
            picker.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
            _systemBroadcastExtensionPicker = picker;
            
            NSString *plugInPath = NSBundle.mainBundle.builtInPlugInsPath;
            if (!plugInPath) {
                return self;
            }
            
            NSArray* contents = [NSFileManager.defaultManager contentsOfDirectoryAtPath:plugInPath error:nil];
            for (NSString* content in contents) {
                NSURL* url = [NSURL fileURLWithPath:plugInPath];
                NSBundle* bundle = [NSBundle bundleWithPath:[url URLByAppendingPathComponent:content].path];
                
                NSDictionary* extension = [bundle.infoDictionary objectForKey:@"NSExtension"];
                if (extension == nil) { continue; }
                NSString* identifier = [extension objectForKey:@"NSExtensionPointIdentifier"];
                if ([identifier isEqualToString:@"com.apple.broadcast-services-upload"]) {
                    picker.preferredExtension = bundle.bundleIdentifier;
                    break;
                }
            }
        }
    }
    return self;
}

@end
