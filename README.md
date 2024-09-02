# polyv-ios-livescenes-sdk-demo

[版本更新记录](https://help.polyv.net/index.html#/live/ios/CHANGELOG)

### 1 简介
本项目从属于广州易方信息科技股份有限公司，是一款基于保利威多场景 SDK，包含了云课堂场景、直播带货场景、手机开播场景等多个场景的 Demo。想要集成本项目提供的 SDK，需要在[保利威视频云平台](https://www.polyv.net)注册账号，并开通相关服务。我们推荐的集成方式，是在使用 Demo 中的开源代码的基础上进行集成。关于如何使用开源代码进行集成，详见 [wiki](https://help.polyv.net/index.html#/live/ios/)。

多场景项目的项目架构图如下：

![多场景架构简图](https://polyv-repo.oss-cn-shenzhen.aliyuncs.com/android/resource/hierarchy.png)

多场景项目的文件目录结构如下：

```
├── AppDelegate.h/m
├── Demo
│   ├── Bugly
│   └── Login
├── PLVLiveCommonModule（通用业务层）
│   ├── GeneralUI
│   ├── Modules
├── PLVLiveCloudClassScene（观看端-云课堂场景）
│   ├── Scenes
│   ├── Modules
│   └── Resource
├── PLVLiveEcommerceScene（观看端-直播带货场景）
│   ├── Scenes
│   ├── Modules
│   └── Resource
├── PLVLiveStreamerScene（开播端-手机开播三分屏场景）
│   ├── Scenes
│   ├── Modules
│   └── Resource
├── PLVStreamerAloneScene（开播端-手机开播纯视频场景）
│   ├── Scenes
│   ├── Modules
│   └── Resource
├── PLVLiveHiClassScene（互动学堂场景）
│   ├── Scenes
│   ├── Modules
│   └── Resource
└── Supporting Files
```

### 2 环境要求

| 名称      | 要求        |
| :-------- | ----------- |
| iOS 系统  | iOS 12.0+    |
| CocoaPods | 1.7.0+      |
| 集成工具  | Xcode 11.0+ |

### 3 体验 Demo

Demo [下载链接](https://www.pgyer.com/IzFQ) （密码：polyv）

### 4 Wiki 文档

可在 [Wiki 文档](https://help.polyv.net/index.html#/live/ios/) 中，了解 **项目结构、SDK 能力、源码释义** 等内容

### 5 Released 版本更新

以下表格反映：

1、Demo 的每个 Release 版本，所依赖的 SDK 版本

2、该 Release 版本的发版改动，所涉及到的场景（“✅ ” 表示涉及、包含该场景下的源码更新、改动）

| Github 仓库 Tag | 依赖 SDK 版本 | API 文档 | Comon 层 | 观看端-云课堂场景 | 观看端-直播带货场景 | 开播端-手机开播（三分屏）场景 | 互动学堂场景 |
| --------------- | ------------- | -------------------------------------------------------------------------------------------- | -------- | ----------------- | ------------------- | ----------------------------- | ----------------------------- |
| 1.19.0 | 1.19.0 | [v1.19.0 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.19.0-20240902/index.html) | ✅ | ✅  | ✅ | ✅ |  |
| 1.18.0 | 1.18.0 | [v1.18.0 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.18.0-20240719/index.html) | ✅ | ✅  | ✅ | ✅ |  |
| 1.17.1 | 1.17.1 | [v1.17.1 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.17.1-20240531/index.html) | ✅ | ✅  | ✅ | ✅ |  |
| 1.17.0 | 1.17.0 | [v1.17.0 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.17.0-20240425/index.html) | ✅ | ✅  | ✅ | ✅ |  |
| 1.16.4 | 1.16.4 | [v1.16.4 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.16.4-20240229/index.html) | ✅ | ✅  | ✅ | ✅ |  |
| 1.16.3 | 1.16.3 | [v1.16.3 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.16.3-20240131/index.html) | ✅ | ✅  | ✅ |  |  |
| 1.16.2 | 1.16.2 | [v1.16.2 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.16.2-20240105/index.html) | ✅ | ✅  | ✅ | ✅ |  |
| 1.16.1 | 1.16.1 | [v1.16.1 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.16.1-20231219/index.html) | ✅ |  | ✅ | ✅ |  |
| 1.16.0 | 1.16.0 | [v1.16.0 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.16.0-20231208/index.html) | ✅ | ✅ | ✅ | ✅ |  |
| 1.15.1 | 1.15.1 | [v1.15.1 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.15.1-20231113/index.html) | ✅ | ✅ | ✅ | ✅ |  |
| 1.15.0 | 1.15.0 | [v1.15.0 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.15.0-20231030/index.html) | ✅ | ✅ | ✅ | ✅ |  |
| 1.14.0 | 1.14.0 | [v1.14.0 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.14.0-20230831/index.html) | ✅ | ✅ | ✅ | ✅ |  |
| 1.13.0 | 1.13.0 | [v1.13.0 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.13.0-20230728/index.html) | ✅ | ✅ | ✅ | ✅ |  |
| 1.12.2 | 1.12.2 | [v1.12.2 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.12.2-20230621/index.html) | ✅ | ✅ | ✅ |  |  |
| 1.11.3 | 1.11.3 | [v1.11.3 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.11.3-20230519/index.html) | ✅ | ✅ | ✅ | ✅ |  |
| 1.11.2 | 1.11.2 | [v1.11.2 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.11.2-20230424/index.html) | ✅ | ✅ | ✅ | ✅ |  |
| 1.10.8 | 1.10.8 | [v1.10.8 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.10.8-20230406/index.html) | ✅ | ✅ | ✅ | ✅ |  |
| 1.10.7 | 1.10.7 | [v1.10.7 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.10.7-20230308/index.html) | ✅ | ✅ | ✅ |  |  |
| 1.10.6 | 1.10.6 | [v1.10.6 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.10.6-20230210/index.html) | ✅ | ✅ | ✅ |  |  |
| 1.10.5 | 1.10.5 | [v1.10.5 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.10.5-20230111/index.html) | ✅ | ✅ | ✅ | ✅ |  |
| 1.10.4 | 1.10.4 | [v1.10.4 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.10.4-20221129/index.html) | ✅ | ✅ | ✅ | ✅ |  |
| 1.10.3 | 1.10.3 | [v1.10.3 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.10.3-20221026/index.html) | ✅ | ✅ | ✅ | ✅ |  |
| 1.10.2 | 1.10.2 | [v1.10.2 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.10.2-20221010/index.html) | ✅ | ✅ | ✅ | ✅ |  |
| 1.10.1 | 1.10.1 | [v1.10.1 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.10.1-20220909/index.html) | ✅ | ✅ | ✅ | ✅ |  |
| 1.10.0 | 1.10.0 | [v1.10.0 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.10.0-20220830/index.html) | ✅ | ✅ | ✅ | ✅ |  |
| 1.9.5 | 1.9.5 | [v1.9.5 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.9.5-20220801/index.html) | ✅ | ✅ | ✅ | ✅ |  |
| 1.9.4 | 1.9.4 | [v1.9.4 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.9.4-20220713/index.html) | ✅ | ✅ |  |  |  |
| 1.9.3 | 1.9.3 | [v1.9.3 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.9.3-20220620/index.html) | ✅ | ✅ | ✅ | ✅ |  |
| 1.9.1.1 | 1.9.1.1 | [v1.9.1.1 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.9.1.1-20220520/index.html) | ✅ | ✅ | ✅ |  |  |
| 1.9.1 | 1.9.1 | [v1.9.1 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.9.1-20220513/index.html) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 1.8.3 | 1.8.3 | [v1.8.3 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.8.3-20220318/index.html) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 1.8.2 | 1.8.2 | [v1.8.2 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.8.2-20220228/index.html) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 1.8.1 | 1.8.1 | [v1.8.1 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.8.1-20220107/index.html) | ✅ | ✅ | ✅ |  |  |
| 1.8.0           | 1.8.0         | [v1.8.0 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.8.0-20211220/index.html) | ✅        | ✅                |  ✅                     | ✅                            ||
| 1.7.3           | 1.7.3         | [v1.7.3 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.7.3-20211207/index.html) | ✅        | ✅                |  ✅                     | ✅                            | ✅   |
| 1.7.2           | 1.7.2         | [v1.7.2 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.7.2-20211115/index.html) |        | ✅                |  ✅                     | ✅                            | ✅   |
| 1.7.1.1           | 1.7.0         | [v1.7.0 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.7.0-20211028/index.html) |        |                |                      | ✅                            |                            |
| 1.7.1           | 1.7.0         | [v1.7.0 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.7.0-20211028/index.html) | ✅       | ✅                | ✅                     | ✅                            |                           |
| 1.7.0           | 1.7.0         | [v1.7.0 API](https://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.7.0-20211028/index.html) | ✅       | ✅                | ✅                     | ✅                            | ✅                            |
| 1.6.2           | 1.6.2         | [v1.6.2 API](http://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.6.2-20211015/index.html) | ✅       | ✅                | ✅                     | ✅                            |                            |
| 1.6.0           | 1.6.0         | [v1.6.0 API](http://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.6.0-20210914/index.html) | ✅       | ✅                | ✅                     | ✅                            |                            |
| 1.5.2           | 1.5.2         | [v1.5.2 API](http://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.5.2-20210810/index.html) | ✅       | ✅                | ✅                     | ✅                            |                            |
| 1.5.1           | 1.5.1         | [v1.5.1 API](http://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.5.1-20210720/index.html) | ✅       | ✅                |                     | ✅                            |                            |
| 1.5.0           | 1.5.0         | [v1.5.0 API](http://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.5.0-20210623/index.html) | ✅       | ✅                | ✅                  | ✅                            |                            |
| 1.4.1           | 1.4.1         |                                                                                              | ✅       | ✅                | ✅                  | ✅                            |                               |
| 1.3.0           | 1.3.0         |                                                                                              | ✅       | ✅                | ✅                  |                               |                               |

更多版本更新详情，可前往 [版本更新列表](../../releases)，了解 **对应版本更新说明**，以及 **下载源码**





