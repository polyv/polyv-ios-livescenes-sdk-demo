
source 'https://github.com/CocoaPods/Specs.git'
source 'https://gitee.com/polyv_ef/plvspecs.git'

# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'PolyvLiveScenesDemo' do
  use_frameworks!

  # 保利威 多场景 SDK
  pod 'PLVLiveScenesSDK', '1.9.2-abn'

  # 保利威 手机开播场景 需依赖的库
  pod 'PLVBytedEffectSDK', '4.3.1'
  pod 'PLVBusinessSDK', '1.9.2-abn', :subspecs => ['ReplayKitExt']
  
  # 保利威 UI源码 需依赖的库
  pod 'SDWebImage', '4.4.0'
  pod 'MJRefresh', '~> 3.5.0'
  pod 'PLVImagePickerController', '~> 0.1.0' # 仅手机开播场景需要
  pod 'SVGAPlayer', '~> 2.3'
  
#  target 'PLVScreenShareExtension' do
#    use_frameworks!
#    inherit! :search_paths
#    pod 'PLVBusinessSDK', '1.9.2-abn', :subspecs => ['ReplayKitExt']
# end
  
end
