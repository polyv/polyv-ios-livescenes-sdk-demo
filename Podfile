source 'https://github.com/CocoaPods/Specs.git'
source 'https://gitee.com/polyv_ef/plvspecs.git'
#source 'https://github.com/volcengine/volcengine-specs.git'

# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

target 'PolyvLiveScenesDemo' do
  use_frameworks!

  # 保利威 多场景 SDK
  pod 'PLVLiveScenesSDK', '1.43.0.1'

  # 保利威 手机开播场景 需依赖的库
  pod 'PLVBytedEffectSDK', '4.4.2.1'
  pod 'PLVBeautyEffect','1.4.0.1'

  pod 'PLVBusinessSDK', '1.43.0.1', :subspecs => ['Beauty']
  
  # 保利威 SM2加密 需依赖的库
  pod 'PLVLOpenSSL', '1.1.12101.1'
  pod 'PLVFoundationSDK', '1.43.0.1', :subspecs => ['CryptoUtils']

  # 保利威 投屏 需依赖的库
  pod 'PLVDLNA', '0.3.0'
  
  # 保利威 UI源码 需依赖的库
  pod 'SDWebImage', '5.21.2'
  pod 'MJRefresh', '~> 3.5.0'
  pod 'PLVImagePickerController', '~> 3.8.9' # 仅手机开播场景需要
  pod 'SVGAPlayer', '~> 2.3'
  pod 'Protobuf', '3.22.4'
end

target 'PLVScreenShareExtension' do
  use_frameworks!
  pod 'PLVBusinessSDK', '1.43.0.1', :subspecs => ['AbstractBSH','ReplayKitExt']
  pod 'PLVFoundationSDK', '1.43.0.1', :subspecs => ['AbstractBase']
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
         end
    end
  end

  # 主工程与扩展引用了不同 subspec，同一 SDK 会生成多个 Pod target，且都拷贝 xcframework 到同一目录：
  # 去掉输出声明避免 Multiple commands produce，并串行构建避免并发 rsync 冲突
  installer.pod_targets.group_by(&:pod_name).each_value do |dups|
    next if dups.size < 2
    natives = dups.map { |t| installer.pods_project.targets.find { |n| n.name == t.label } }
    natives.each_cons(2) { |prev, cur| cur.add_dependency(prev) }
    natives.each do |n|
      n.shell_script_build_phases.each do |phase|
        phase.output_file_list_paths = [] if phase.name == '[CP] Copy XCFrameworks'
      end
    end
  end
end
