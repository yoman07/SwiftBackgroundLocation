Pod::Spec.new do |s|
  s.name             = 'SwiftBackgroundLocation'
  s.version          = '0.1.2'
  s.summary          = 'Efficient and Easy Location Background Monitoring in Swift'
  s.description      = <<-DESC
Easy Location Background Monitoring based on regions and significant location change.
                       DESC
  s.homepage         = 'https://github.com/yoman07/SwiftBackgroundLocation'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'yoman07' => 'roman.barzyczak+web@gmail.com' }
  s.source           = { :git => 'https://github.com/yoman07/SwiftBackgroundLocation.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/roman_barzyczak'
  s.ios.deployment_target = '9.0'
  s.source_files = 'SwiftBackgroundLocation/Classes/**/*'
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3.0' }
end
