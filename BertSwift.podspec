#
# Be sure to run `pod lib lint BertSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |spec|
spec.name             = 'BertSwift'
spec.version          = '2.1.0'
spec.summary          = 'Swift 4.0 compatible Erlang binary format serializer, deserilizer'

spec.description      = <<-DESC
This is Erlang BERT format serializer, deserializer for sending & receiving native erlang packets
DESC

spec.homepage         = 'https://github.com/softwarejoint/BertSwift'
spec.license          = { :type => 'MIT', :file => 'LICENSE.md' }
spec.author           = { 'pankajsoni@softwarejoint.com' => 'pankajsoni@softwarejoint.com' }
spec.source           = { :git => 'https://github.com/softwarejoint/BertSwift.git', :tag => String(spec.version) }

spec.ios.deployment_target = '8.0'
spec.osx.deployment_target = "10.9"
spec.tvos.deployment_target = "9.0"
spec.watchos.deployment_target = "2.0"

spec.source_files     = "Source/*.swift"

spec.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0' }
spec.requires_arc = true

spec.dependency 'BigInt', '~> 3.0'

end
