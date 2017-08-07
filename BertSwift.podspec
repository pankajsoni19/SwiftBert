#
# Be sure to run `pod lib lint BertSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = 'BertSwift'
s.version          = '2.0.1'
s.summary          = 'Swift 3.0 compatible Erlang binary format serializer, deserilizer'

s.description      = <<-DESC
This is Erlang BERT format serializer, deserializer for sending & receiving native erlang packets
DESC

s.homepage         = 'https://github.com/softwarejoint/BertSwift'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { 'pankajsoni@softwarejoint.com' => 'pankajsoni@softwarejoint.com' }
s.source           = { :git => 'https://github.com/softwarejoint/BertSwift.git', :tag => s.version.to_s }

s.ios.deployment_target = '8.0'

s.source_files     = "Source/*.swift"

s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3.0' }
s.requires_arc = true

s.dependency 'BigInt', '2.1.2'
end
