#
# Be sure to run `pod lib lint PandaAdsLib.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PandaAdsLib'
  s.version          = '1.0.8'
  s.summary          = 'Lib ads on iOS of Panda Team'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  Lib to request UMP, show ads interstitial, banner, native, video ads of Admob
                       DESC

  s.homepage         = 'https://github.com/blackmonkey0102/PandaAdsLib'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'La Phong' => 'smartbird1995@gmail.com' }
  s.source           = { :git => 'https://github.com/blackmonkey0102/PandaAdsLib.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.swift_version = '5.0'
  s.ios.deployment_target = '13.0'
  s.pod_target_xcconfig = {
    'IPHONEOS_DEPLOYMENT_TARGET' => '13.0'
  }
  s.static_framework = true
  s.source_files = 'Classes/**/*.{swift,h,m}'
  s.resources = ['Classes/**/*.xib']
  #   s.resource_bundles = {
#     'PandaAdsLib' => ['PandaAdsLib/Assets/*.png']
#   }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
   s.dependency 'Google-Mobile-Ads-SDK', '~> 10.7.0'
   s.dependency 'Adjust', '~> 4.38.4'
   s.dependency 'Firebase/Analytics', '~> 8.8.0'
#   s.dependency 'JGProgressHUD'
end
