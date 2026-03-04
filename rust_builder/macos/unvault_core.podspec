Pod::Spec.new do |s|
  s.name             = 'unvault_core'
  s.version          = '0.0.1'
  s.summary          = 'Rust cryptographic core for UnVault wallet'
  s.description      = 'Builds the Rust unvault-core library via cargokit for macOS.'
  s.homepage         = 'https://github.com/user/unvault'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'UnVault' => 'dev@unvault.app' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.15'

  s.script_phase = {
    :name => 'Build Rust library',
    :script => 'sh "$PODS_TARGET_SRCROOT/../cargokit/build_pod.sh" ../../rust unvault_core',
    :execution_position => :before_compile,
    :input_files => ['${BUILT_PRODUCTS_DIR}/cargokit_phony'],
    :output_files => ["${BUILT_PRODUCTS_DIR}/libunvault_core.a"],
  }
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'OTHER_LDFLAGS' => '-force_load ${BUILT_PRODUCTS_DIR}/libunvault_core.a',
  }
end
