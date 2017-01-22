
Pod::Spec.new do |s|


  s.name         = "ZZModel"
  s.version      = "1.0.0"
  s.summary      = "A Library for Model and dictionary of mutual transform."

  s.description  = <<-DESC
  ZZModel is a Library for Model and dictionary of mutual transform, it still has many potential bug now，I will consistent upgrade it. add it will add swift version soon.
                   DESC

  s.homepage     = "https://github.com/zmarvin/ZZModel"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }

  s.author             = { "zmarvin" => "zz890620@gmail.com" }
  # Or just: s.author    = "zmarvin"
  # s.authors            = { "zmarvin" => "zz890620@gmail.com" }
  # s.social_media_url   = "http://twitter.com/zmarvin"


  s.platform     = :ios, "7.0"

  s.requires_arc = true
  s.ios.deployment_target = '8.0'
  s.ios.frameworks = ['CoreFoundation', 'Foundation']
  s.source       = { :git => "https://github.com/zmarvin/ZZModel.git", :tag => "#{s.version}" }

  s.source_files  = "ZZModel", "ZZModel/*.{h,m}"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  # s.framework  = "SomeFramework"
  # s.frameworks = "SomeFramework", "AnotherFramework"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  # s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "JSONKit", "~> 1.4"

end
