Pod::Spec.new do |s|
  s.name                = 'SGAVPlayer'
  s.version             = '1.9.0'
  s.summary             = 'A media player framework for iOS, macOS, and tvOS.'
  s.homepage            = 'https://github.com/libobjc/SGPlayer'
  s.license             = { :type => 'MIT', :file => 'LICENSE' }
  s.author              = { 'Single' => 'libobjc@gmail.com' }
  s.social_media_url    = 'https://weibo.com/3118550737'

  s.source              = { :git => 'https://github.com/libobjc/SGPlayer.git', :tag => 'SGAVPlayer-Pod-1.9.0' }
  s.source_files        = 'SGPlayer/Classes/Extension/SGAVPlayer',
                          'SGPlayer/Classes/Extension/SGAVPlayer/**/*.{h,m}',
                          'SGPlayer/Classes/Core/SGCommon',
                          'SGPlayer/Classes/Support/SGPlatform',
                          'SGPlayer/Classes/Support/SGPlatform/**/*.{h,m}'
  s.public_header_files = 'SGPlayer/Classes/Extension/SGAVPlayer/Classes/SGAVPlayer.h',
                          'SGPlayer/Classes/Core/SGCommon/SGPlayerDefines.h',
                          'SGPlayer/Classes/Core/SGCommon/SGPlayerAction.h',
                          'SGPlayer/Classes/Support/SGPlatform/SGPlatform.h',
                          'SGPlayer/Classes/Support/SGPlatform/**/*.h'
  s.module_map          = 'SGPlayer/Classes/Extension/SGAVPlayer/module.modulemap'

  s.ios.frameworks      = 'Foundation', 'AVFoundation', 'UIKit'
  s.tvos.frameworks     = 'Foundation', 'AVFoundation', 'UIKit'
  s.osx.frameworks      = 'Foundation', 'AVFoundation', 'AppKit'

  s.ios.deployment_target   = '8.0'
  s.osx.deployment_target   = '10.10'
  s.tvos.deployment_target  = '9.0'

  s.requires_arc        = true
end
