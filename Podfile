source 'https://github.com/CocoaPods/Specs.git'
source 'https://gitee.com/polyv_ef/plvspecs.git'

# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'PolyvLiveScenesDemo' do
  use_frameworks!

  # 保利威 多场景 SDK
  pod 'PLVLiveScenesSDK', '1.10.4'

  # 保利威 手机开播场景 需依赖的库
  pod 'PLVBytedEffectSDK', '4.3.1'
  pod 'PLVBusinessSDK', '1.10.4', :subspecs => ['Beauty']
  
  # 保利威 UI源码 需依赖的库
  pod 'SDWebImage', '4.4.0'
  pod 'MJRefresh', '~> 3.5.0'
  pod 'PLVImagePickerController', '~> 0.1.2' # 仅手机开播场景需要
  pod 'SVGAPlayer', '~> 2.3'
  
end

target 'PLVScreenShareExtension' do
  use_frameworks!
  pod 'PLVBusinessSDK', '1.10.4', :subspecs => ['AbstractBSH','ReplayKitExt']
  pod 'PLVFoundationSDK', '1.10.4'
  pod 'TXLiteAVSDK_TRTC', '9.3.10763'
end
