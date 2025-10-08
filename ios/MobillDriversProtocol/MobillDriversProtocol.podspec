Pod::Spec.new do |s|
  s.name         = "MobillDriversProtocol"
  s.version      = "1.0.0"
  s.summary      = "CoolLEDU Protocol Implementation for Mobill Drivers"
  s.description  = <<-DESC
                   Native iOS implementation of CoolLEDU Bluetooth LED display protocol
                   extracted from manufacturer's CoolLED1248 app. Includes LZSS compression,
                   CRC32 checksums, and complete protocol formatting utilities.
                   DESC
  s.homepage     = "https://github.com/mobill/drivers"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Mobill" => "developers@mobill.com" }
  s.platform     = :ios, "11.0"
  s.source       = { :git => ".", :tag => "#{s.version}" }
  s.source_files = "*.{h,m}"
  s.requires_arc = true
  s.framework    = "CoreBluetooth", "Foundation", "UIKit"
  
  # React Native dependency
  s.dependency "React-Core"
end