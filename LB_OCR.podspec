#
# Be sure to run `pod lib lint LB_OCR.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LB_OCR'
  s.version          = '0.0.1'
  s.summary          = 'LB_OCR.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
        This engine can recognize business card, DOC and certificates etc.
                       DESC

  s.homepage         = 'https://github.com/llb1119/LB_OCR'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'llb1119' => 'llb1119@163.com' }
  s.source           = { :git => 'https://github.com/llb1119/LB_OCR.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'LB_OCR/Classes/**/*'
  
  # s.resource_bundles = {
  #   'LB_OCR' => ['LB_OCR/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  #s.dependency 'OpenCV'
  s.dependency 'TesseractOCRiOS', '4.0.0'
end
