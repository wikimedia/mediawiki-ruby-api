# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mediawiki_api/version"

Gem::Specification.new do |spec|
  spec.name          = "mediawiki_api"
  spec.version       = MediawikiApi::VERSION
  spec.authors       = ["Amir Aharoni", "Chris McMahon", "Jeff Hall", "Zeljko Filipin"]
  spec.email         = ["amir.aharoni@mail.huji.ac.il", "cmcmahon@wikimedia.org", "jhall@wikimedia.org", "zeljko.filipin@gmail.com"]
  spec.summary       = %q{An easy way to work with MediaWiki API from Ruby.}
  spec.description   = %q{Uses REST Client Ruby gem to communicate with MediaWiki API.}
  spec.homepage      = "https://github.com/zeljkofilipin/mediawiki_api"
  spec.license       = "GPL-2"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "rest-client", "~> 1.6", ">= 1.6.7"
end
