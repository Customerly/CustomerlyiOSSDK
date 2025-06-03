Pod::Spec.new do |s|
  s.name         = "Customerly"
s.version = '1.0.1'
  s.summary      = "SDK for integrating Customerly in iOS apps"
  s.description  = <<-DESC
    This SDK allows iOS apps to easily integrate Customerly's support chat widget using a native wrapper.
  DESC
  s.homepage     = "https://github.com/customerly/CustomerlyiOSSDK"
  s.license      = { :type => "GNU General Public License v3.0", :file => "LICENSE" }
  s.author       = { "Customerly" => "developers@customerly.io" }
  s.source       = { :git => "https://github.com/customerly/CustomerlyiOSSDK.git", :tag => s.version.to_s }

  s.platform     = :ios, "13.0"
  s.source_files = "CustomerlySDK/**/*.swift"
  s.swift_version = "5.6"
end
