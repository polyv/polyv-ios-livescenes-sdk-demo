//
//  PLVSAEmojiSelectView.h
//  PLVLiveScenesDemo
//
//  Created by lijingtong on 2021/5/26.
//  Copyright © 2021 PLV. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PLVEmoticon, PLVImageEmotion;

typedef NS_ENUM(NSUInteger, PLVSAEmojiSelectViewEvent) {
    PLVSAEmojiSelectViewEventSend,
    PLVSAEmojiSelectViewEventDelete
};

typedef void (^PLVSACollectionViewDidSelectBlock)(NSInteger index);

@protocol PLVSAEmojiSelectViewDelegate <NSObject>

- (void)emojiSelectView_didSelectEmoticon:(PLVEmoticon *)emoticon;

- (void)emojiSelectView_didReceiveEvent:(PLVSAEmojiSelectViewEvent)event;
///选择图片表情
- (void)emojiSelectView_sendImageEmoticon:(PLVImageEmotion *)emoticon;

@end

@interface PLVSAEmojiSelectView : UIView

@property (nonatomic, weak) id<PLVSAEmojiSelectViewDelegate> delegate;

///键盘的图片表情数据
@property (nonatomic, strong) NSArray *imageEmotions;

- (void)sendButtonEnable:(BOOL)enable;

@end

@interface PLVSADefaultEmojiSelectView : UIView

@property (nonatomic, strong) NSArray *faces;

@property (nonatomic, copy) PLVSACollectionViewDidSelectBlock selectItemBlock;

@end

@interface PLVSACustomEmojiSelectView : UIView

@property (nonatomic, strong) NSArray *imageEmotions;

@property (nonatomic, copy) PLVSACollectionViewDidSelectBlock selectItemBlock;

@end

@interface PLVSAEmojiCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@end

@interface PLVSACustomEmojiCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) PLVImageEmotion *imageEmotion;

@end
NS_ASSUME_NONNULL_END
