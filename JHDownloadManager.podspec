#
# Be sure to run `pod lib lint JHDownloadManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "JHDownloadManager"
  s.version          = "1.0.0"
  s.summary          = "Dead Simple batch of file Download Manager"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
                       JHDownloadManager is a files download manager built on top of NSURLSession for iOS. It supports auto resume on internet connection recovery.
                       DESC

  s.homepage         = "https://github.com/jameshuynh/JHDownloadManager"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "James Huynh" => "jameshuynhsg@gmail.com" }
  s.source           = { :git => "https://github.com/jameshuynh/JHDownloadManager.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/jameshu'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'JHDownloadManager' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'FileMD5Hash', '~> 2.0.0'
  s.dependency 'ReachabilitySwift', '~> 2.3.3'
end
