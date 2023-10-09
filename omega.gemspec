# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'omega/version'

Gem::Specification.new do |spec|
  spec.name          = 'omegaup'
  spec.version       = Omega::VERSION
  spec.authors       = ['Gilberto Vargas']
  spec.email         = ['tachoguitar@gmail.com']

  spec.summary       = 'File created for encrypting files using ssh keys'
  spec.description   = 'Allows to encrypt files using ssh keys'
  spec.homepage      = 'https://github.com/omijal/omegaup-cli'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'amazing_print'
  spec.add_development_dependency 'httparty'
  spec.add_development_dependency 'minitest', '~> 5'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'optimist'
  spec.add_development_dependency 'rack-minitest'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'webmock'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
