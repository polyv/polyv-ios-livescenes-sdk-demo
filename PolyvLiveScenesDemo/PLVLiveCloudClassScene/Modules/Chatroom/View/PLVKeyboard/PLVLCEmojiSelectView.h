//
//  PLVEmojiSelectView.h
//  PLVLiveScenesDemo
//
//  Created by MissYasiky on 2020/9/27.
//  Copyright © 2020 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

/// PLVLCEmojiSelectToolMode 模式 - 不同模式表情包含的内容不同，同时高度也有区别
typedef NS_ENUM(NSInteger, PLVLCEmojiSelectToolMode) {
    PLVLCEmojiSelectToolModeDefault,     // 默认模式：包含图片表情和大黄脸表情
    PLVLCEmojiSelectToolModeSimple,      // 简单模式：只有大黄脸表情
};

@class PLVEmoticon, PLVImageEmotion;

typedef void (^PLVCollectionViewDidSelectBlock)(NSInteger index);

@protocol PLVLCEmojiSelectViewDelegate <NSObject>

@required

- (void)selectEmoji:(PLVEmoticon *)emojiModel;

- (void)selectImageEmotions:(PLVImageEmotion *)emojiModel;

- (void)deleteEmoji;

- (void)sendEmoji;

@end


@interface PLVLCEmojiSelectView : UIView

@property (nonatomic, weak) id<PLVLCEmojiSelectViewDelegate> delegate;
///键盘的图片表情
@property (nonatomic, strong) NSArray *imageEmotions;
/// 初始化方法
- (instancetype)initWithMode:(PLVLCEmojiSelectToolMode)mode;

- (void)sendButtonEnable:(BOOL)enable;

@end

@interface PLVLCDefaultEmojiSelectView : UIView

@property (nonatomic, strong) NSArray *faces;

@property (nonatomic, copy) PLVCollectionViewDidSelectBlock selectItemBlock;

@end

@interface PLVLCCustomEmojiSelectView : UIView

@property (nonatomic, strong) NSArray *imageEmotions;

@property (nonatomic, copy) PLVCollectionViewDidSelectBlock selectItemBlock;

@end

@interface PLVLCEmojiCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@end

@interface PLVLCCustomEmojiCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) PLVImageEmotion *imageEmotion;

@end
