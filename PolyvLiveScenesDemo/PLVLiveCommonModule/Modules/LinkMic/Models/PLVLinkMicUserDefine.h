//
//  PLVLinkMicUserDefine.h
//  PolyvLiveScenesDemo
//
//  Created by Sakya on 2023/5/17.
//  Copyright © 2023 PLV. All rights reserved.
//

#ifndef PLVLinkMicUserDefine_h
#define PLVLinkMicUserDefine_h

typedef NS_ENUM(NSUInteger, PLVLinkMicUserLinkMicStatus) {
    PLVLinkMicUserLinkMicStatus_Unknown = 0, // 未知状态
    PLVLinkMicUserLinkMicStatus_HandUp = 2, // 等待讲师应答中（举手中）
    PLVLinkMicUserLinkMicStatus_Inviting = 4, // 讲师等待连麦邀请的应答中
    PLVLinkMicUserLinkMicStatus_Joining = 6,// 讲师已允许 或 学生已应答，正在加入，引擎正在初始化
    PLVLinkMicUserLinkMicStatus_Joined  = 8,// 已加入连麦（连麦中）
    PLVLinkMicUserLinkMicStatus_Leave = 10, // 嘉宾离开连麦状态
};

#endif /* PLVLinkMicUserDefine_h */
