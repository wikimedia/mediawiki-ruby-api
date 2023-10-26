lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mediawiki_api/version'

Gem::Specification.new do |spec|
  spec.name          = 'mediawiki_api'
  spec.version       = MediawikiApi::VERSION
  spec.authors       = [
    'Amir Aharoni', 'Asaf Bartov', 'Chris McMahon', 'Dan Duvall', 'Jeff Hall', 'Juliusz Gonera',
    'Zeljko Filipin'
  ]
  spec.email         = [
    'amir.aharoni@mail.huji.ac.il', 'asaf.bartov@gmail.com', 'cmcmahon@wikimedia.org',
    'dduvall@wikimedia.org', 'jhall@wikimedia.org', 'jgonera@wikimedia.org',
    'zeljko.filipin@gmail.com'
  ]
  spec.summary       = 'A library for interacting with MediaWiki API from Ruby.'
  spec.description   = 'Uses adapter-agnostic Faraday gem to talk to MediaWiki API.'
  spec.homepage      = 'https://github.com/wikimedia/mediawiki-ruby-api'
  spec.license       = 'GPL-2.0'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.test_files    = spec.files.grep(/^(test|spec|features)/)
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.5.0'

  spec.add_runtime_dependency 'faraday', '~> 1'
  # These dependencies will float to whatever `faraday` resolves to
  # and are not needed for faraday 2 when we migrate to 2.X
  spec.add_runtime_dependency 'faraday-cookie_jar'
  spec.add_runtime_dependency 'faraday_middleware'

  # Most developer dependencies can float to latest, but stick to RSpec 3
  # since that would likely introduce breaking changes (bundler, rubocop
  # and rake have excellent back-compat)
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rake'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'redcarpet'
  spec.add_development_dependency 'yard'
end
