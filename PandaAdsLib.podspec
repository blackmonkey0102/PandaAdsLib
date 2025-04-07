#
# Be sure to run `pod lib lint PandaAdsLib.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PandaAdsLib'
  s.version          = '1.0.2'
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

  s.source_files = 'PandaAdsLib/Classes/**/*'
  #   s.resource_bundles = {
#     'PandaAdsLib' => ['PandaAdsLib/Assets/*.png']
#   }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
