//
//  PLVCheckVoiceWarningView.h
//  PolyvLiveScenesDemo
//
//  Created by POLYV on 2026/6/1.
//  Copyright © 2026 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVCheckVoiceWarningModel;

@interface PLVCheckVoiceWarningView : UIView

- (void)receiveWarningModels:(NSArray<PLVCheckVoiceWarningModel *> *)warningModels;
- (void)updateLayoutForParentView;

@end

NS_ASSUME_NONNULL_END
