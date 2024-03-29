Pod::Spec.new do |s|
  s.name             = 'MaterialPageControl'
  s.version          = '2.0.0'
  s.summary          = 'Material page control written entirely in Swift.'
 
  s.description      = <<-DESC
Material page control written entirely in Swift 5 with customizable attributes.
                       DESC
 
  s.homepage         = 'https://github.com/DeluxeAlonso/MaterialPageControl'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Alonso Alvarez' => 'alonso.alvarez.dev@gmail.com' }
  s.source           = { :git => 'https://github.com/DeluxeAlonso/MaterialPageControl.git', :tag => s.version.to_s }
 
  s.ios.deployment_target = '13.0'
  s.source_files = 'Sources/MaterialPageControl/*'
  s.swift_version = "5.0"
  s.swift_versions = ['4.0', '4.2', '5.0']
 
end
