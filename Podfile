source 'https://github.com/CocoaPods/Specs.git'
source 'https://gitee.com/polyv_ef/plvspecs.git'

# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

target 'PolyvLiveScenesDemo' do
  use_frameworks!

  # 保利威 多场景 SDK
  pod 'PLVLiveScenesSDK', '1.16.2.1'

  # 保利威 手机开播场景 需依赖的库
  pod 'PLVBytedEffectSDK', '4.4.2'
  pod 'PLVBusinessSDK', '1.16.2.1', :subspecs => ['Beauty']
  
  # 保利威 UI源码 需依赖的库
  pod 'SDWebImage', '4.4.0'
  pod 'MJRefresh', '~> 3.5.0'
  pod 'PLVImagePickerController', '~> 0.1.3' # 仅手机开播场景需要
  pod 'SVGAPlayer', '~> 2.3'
  pod 'Protobuf', '3.22.4'
  pod 'CropViewController', '2.6.1'
end

target 'PLVScreenShareExtension' do
  use_frameworks!
  pod 'PLVBusinessSDK', '1.16.2.1', :subspecs => ['AbstractBSH','ReplayKitExt']
  pod 'PLVFoundationSDK', '1.15.0'
end
