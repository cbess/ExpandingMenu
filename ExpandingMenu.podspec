#
# Be sure to run `pod lib lint ExpandingMenu.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "ExpandingMenu"
  s.version          = "0.4.0"
  s.summary          = "An expanding menu button."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
                       This library provides a global menu button.
                       DESC

  s.homepage         = "https://github.com/cbess/ExpandingMenu"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.authors           = { "monoqlo" => "monoqlo44@gmail.com", 'cbess' => 'cbess@quantumquinn.com' }
  s.source           = { :git => "https://github.com/cbess/ExpandingMenu.git", :branch => 'master' }

  s.platform     = :ios, '10.0'
  s.requires_arc = true

  s.source_files = 'ExpandingMenu/Classes/*.swift'
  s.resource_bundles = {
    'ExpandingMenu' => ['ExpandingMenu/Assets/Sounds/*']
  }

  s.frameworks = 'QuartzCore', 'AudioToolBox'
end
