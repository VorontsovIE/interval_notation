# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'interval_notation/version'

Gem::Specification.new do |spec|
  spec.name          = "interval_notation"
  spec.version       = IntervalNotation::VERSION
  spec.authors       = ["Ilya Vorontsov"]
  spec.email         = ["prijutme4ty@gmail.com"]
  spec.summary       = %q{interval_notation allows one to work with 1D-intervals.}
  spec.description   = %q{interval_notation provides methods to create intervals with open or closed boundaries or singular points, unite and intersect them, check inclusion into an interval and so on.}
  spec.homepage      = "https://github.com/prijutme4ty/interval_notation"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
