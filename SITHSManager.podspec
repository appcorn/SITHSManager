Pod::Spec.new do |s|
  s.name             = 'SITHSManager'
  s.version          = '0.1.0'
  s.summary          = 'SITHS Smart Card manager module.'

  s.description      = <<-DESC
iOS helper classes used for reading and parsing the basic contents of Swedish SITHS identification smart cards with a Precise Biometrics card reader.
                       DESC

  s.homepage         = 'https://github.com/appcorn/SITHSManager'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Martin Alleus' => 'martin@appcorn.se' }
  s.source           = { :git => 'https://github.com/appcorn/SITHSManager.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = ['SITHSManager/Classes/**/*', 'Precise/include/*.h', 'Precise/lib/*']
  
  s.vendored_frameworks = 'Precise.framework'

  s.frameworks = 'AudioToolbox'
end
