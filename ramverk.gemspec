require_relative './lib/ramverk/version'

Gem::Specification.new do |spec|
  spec.name          = 'ramverk'
  spec.version       = Ramverk::VERSION
  spec.authors       = ['Tobias Sandelius']
  spec.email         = ['tobias@sandeli.us']
  spec.summary       = %q{The Ruby web framework}
  spec.homepage      = 'https://github.com/sandelius/ramverk'
  spec.license       = 'MIT'
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.2.0'

  spec.add_runtime_dependency 'rack', '~> 1.6.0'
  spec.add_runtime_dependency 'rack-parser', '~> 0.6.1'
  spec.add_runtime_dependency 'class_attribute', '~> 0.1.0'
  spec.add_runtime_dependency 'tilt', '~> 2.0.0'

  spec.add_development_dependency 'bundler',   '~> 1.6'
  spec.add_development_dependency 'rake',      '~> 10'
  spec.add_development_dependency 'minitest',  '~> 5'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'coveralls'
end
