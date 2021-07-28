# plv-ios-livescenes-sdk-demo
### 1 简介
多场景项目的项目架构图如下：

![多场景架构简图](https://repo.polyv.net/android/resource/hierarchy.png)

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
└── Supporting Files
```




### 2 API 文档

1.5.0 版 API 文档请看 [v1.5.0 API](http://repo.polyv.net/ios/documents/PLVLiveScenesSDK/1.5.0-20210623/index.html)




### 3 Released 版本更新
以下表格反映：

1、Demo 的每个 Release 版本，所依赖的 SDK 版本

2、该 Release 版本的发版改动，所涉及到的场景（“✅ ” 表示涉及、包含该场景下的源码更新、改动）

| Github仓库Tag | 依赖SDK版本 | Comon层 | 观看端-云课堂场景 | 观看端-直播带货场景 | 开播端-手机开播（三分屏）场景 |开播端-手机开播（纯视频）场景 |
| ------------- | ----------- | ------- | ---------- | ------------ | ---------------------- |---------------------- |
| 1.3.0         | 1.3.0       | ✅       | ✅          | ✅            |                        |                      |
| 1.4.1         | 1.4.1       | ✅       | ✅          | ✅            | ✅                      |                      |
| 1.5.0         | 1.5.0       | ✅       | ✅          | ✅            | ✅                      |✅                      |

更多版本更新详情，可在 [版本更新列表](https://github.com/polyv/polyv-ios-livescenes-sdk-demo/releases)，了解 **对应版本更新说明**，以及 **下载源码**





